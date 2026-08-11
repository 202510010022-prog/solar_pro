#!/usr/bin/env python3
"""Fetch frozen PVGIS Brazil validation fixtures.

This is a manual capture tool. It performs one PVGIS PVcalc request per
configured city and writes the offline fixture used by Flutter tests.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parents[1]
FIXTURE_PATH = ROOT / "mobile_app" / "test" / "fixtures" / "pvgis_brazil_cases.json"

PVGIS_BASE_URL = "https://re.jrc.ec.europa.eu/api/v5_3/PVcalc"
VIACEP_BASE_URL = "https://viacep.com.br/ws"

COMMON_PARAMS = {
    "peakpower": 1.0,
    "loss": 14.0,
    "pvtechchoice": "crystSi",
    "mountingplace": "free",
    "optimalangles": 1,
    "outputformat": "json",
}

CASES = [
    {
        "id": "salvador_ba",
        "region": "Nordeste",
        "city": "Salvador",
        "state": "BA",
        "cep": "40010000",
        "latitude": -12.9714,
        "longitude": -38.5014,
    },
    {
        "id": "sao_paulo_sp",
        "region": "Sudeste",
        "city": "São Paulo",
        "state": "SP",
        "cep": "01001000",
        "latitude": -23.5505,
        "longitude": -46.6333,
    },
    {
        "id": "curitiba_pr",
        "region": "Sul",
        "city": "Curitiba",
        "state": "PR",
        "cep": "80010000",
        "latitude": -25.4284,
        "longitude": -49.2733,
    },
    {
        "id": "manaus_am",
        "region": "Norte",
        "city": "Manaus",
        "state": "AM",
        "cep": "69005070",
        "latitude": -3.1190,
        "longitude": -60.0217,
    },
]


def main() -> None:
    captured_at = datetime.now(timezone.utc).isoformat(timespec="seconds").replace(
        "+00:00", "Z"
    )
    fixture = {
        "api_version": "v5_3",
        "tool": "PVcalc",
        "captured_at": captured_at,
        "common_params": COMMON_PARAMS,
        "cases": [],
    }

    for case in CASES:
        cep_data = fetch_viacep(case)
        pvgis_data = fetch_pvgis(case)
        fixture["cases"].append(extract_case(case, cep_data, pvgis_data))

    FIXTURE_PATH.parent.mkdir(parents=True, exist_ok=True)
    FIXTURE_PATH.write_text(
        json.dumps(fixture, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {FIXTURE_PATH}")
    print_summary(fixture)


def fetch_json(url: str) -> dict:
    with urlopen(url, timeout=45) as response:
        if response.status != 200:
            raise RuntimeError(f"HTTP {response.status}: {url}")
        return json.loads(response.read().decode("utf-8"))


def fetch_viacep(case: dict) -> dict:
    cep = digits(case["cep"])
    data = fetch_json(f"{VIACEP_BASE_URL}/{cep}/json/")
    if data.get("erro"):
        raise RuntimeError(f"ViaCEP did not find CEP {cep}")
    if data.get("localidade") != case["city"] or data.get("uf") != case["state"]:
        raise RuntimeError(
            f"ViaCEP mismatch for {cep}: {data.get('localidade')}/{data.get('uf')}"
        )
    return data


def fetch_pvgis(case: dict) -> dict:
    params = {
        "lat": f"{case['latitude']:.6f}",
        "lon": f"{case['longitude']:.6f}",
        **COMMON_PARAMS,
    }
    return fetch_json(f"{PVGIS_BASE_URL}?{urlencode(params)}")


def extract_case(case: dict, cep_data: dict, data: dict) -> dict:
    fixed_monthly = data.get("outputs", {}).get("monthly", {}).get("fixed")
    if not isinstance(fixed_monthly, list) or len(fixed_monthly) < 12:
        raise RuntimeError(f"PVGIS returned less than 12 months for {case['id']}")

    fixed_totals = data.get("outputs", {}).get("totals", {}).get("fixed", {})
    annual_generation = number(fixed_totals.get("E_y"))
    if annual_generation <= 0:
        raise RuntimeError(f"PVGIS missing E_y for {case['id']}")

    pv_orientation = data.get("inputs", {}).get("mounting_system", {}).get("fixed", {})
    slope = number(pv_orientation.get("slope", {}).get("value"))
    pvgis_aspect = number(pv_orientation.get("azimuth", {}).get("value"))
    monthly_hsp = [number(month.get("H(i)_d")) for month in fixed_monthly[:12]]
    monthly_generation = [number(month.get("E_m")) for month in fixed_monthly[:12]]

    if any(value <= 0 for value in monthly_hsp):
        raise RuntimeError(f"PVGIS invalid H(i)_d for {case['id']}")
    if any(value <= 0 for value in monthly_generation):
        raise RuntimeError(f"PVGIS invalid E_m for {case['id']}")

    meteo = data.get("inputs", {}).get("meteo_data", {})
    return {
        **case,
        "cep": digits(case["cep"]),
        "cep_lookup": {
            "provider": "ViaCEP",
            "cep": cep_data.get("cep", ""),
            "street": cep_data.get("logradouro", ""),
            "neighborhood": cep_data.get("bairro", ""),
            "city": cep_data.get("localidade", ""),
            "state": cep_data.get("uf", ""),
        },
        "coordinate_note": "Coordenada de referência urbana; não representa telhado específico.",
        "radiation_database": text(meteo.get("radiation_db")),
        "year_min": optional_number(meteo.get("year_min")),
        "year_max": optional_number(meteo.get("year_max")),
        "elevation": optional_number(data.get("inputs", {}).get("location", {}).get("elevation")),
        "pv_slope": slope,
        "pvgis_aspect": pvgis_aspect,
        "pv_azimuth_geographic": normalize_degrees(180 + pvgis_aspect),
        "monthly_hsp": monthly_hsp,
        "monthly_pvgis_generation": monthly_generation,
        "pvgis_annual_generation": annual_generation,
        "annual_plane_irradiation": optional_number(fixed_totals.get("H(i)_y")),
        "annual_generation_sd": optional_number(fixed_totals.get("SD_y")),
    }


def print_summary(fixture: dict) -> None:
    print(
        "Cidade | DB | slope | azimuth | HSP anual | PVGIS E_y | soma E_m"
    )
    for case in fixture["cases"]:
        monthly_sum = sum(case["monthly_pvgis_generation"])
        hsp = weighted_hsp(case["monthly_hsp"])
        print(
            f"{case['city']} | {case['radiation_database']} | "
            f"{case['pv_slope']:.1f} | {case['pv_azimuth_geographic']:.1f} | "
            f"{hsp:.2f} | {case['pvgis_annual_generation']:.1f} | {monthly_sum:.1f}"
        )


def weighted_hsp(monthly_hsp: list[float]) -> float:
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return sum(value * days[index] for index, value in enumerate(monthly_hsp)) / 365


def number(value) -> float:
    try:
        result = float(value)
    except (TypeError, ValueError):
        raise RuntimeError(f"Invalid numeric value: {value!r}") from None
    if not (-10_000_000 < result < 10_000_000):
        raise RuntimeError(f"Out of range numeric value: {value!r}")
    return result


def optional_number(value):
    if value is None:
        return None
    return number(value)


def text(value) -> str:
    result = str(value or "").strip()
    if not result:
        raise RuntimeError("Expected non-empty text")
    return result


def digits(value: str) -> str:
    return "".join(char for char in str(value) if char.isdigit())


def normalize_degrees(value: float) -> float:
    return value % 360


if __name__ == "__main__":
    main()
