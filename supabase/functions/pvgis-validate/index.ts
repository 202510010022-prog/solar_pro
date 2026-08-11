// Restrict CORS to known domains (S2.1)
const allowedOrigins = [
  "https://solarpro.app",
  "https://admin.solarpro.app",
  "http://localhost:3000",
  "http://localhost:8081",
];

function getCorsHeaders(origin?: string): Record<string, string> {
  const corsOrigin = origin && isAllowedOrigin(origin) ? origin : "null";
  return {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function isAllowedOrigin(origin: string) {
  if (allowedOrigins.includes(origin)) return true;
  return /^http:\/\/(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+)(:\d+)?$/
    .test(origin);
}

let corsHeaders = getCorsHeaders();

type PvgisPayload = {
  mode?: string;
  orientation_mode?: "automatic" | "manual";
  latitude?: number | string;
  longitude?: number | string;
  address?: {
    zip_code?: string;
    street?: string;
    address_number?: string;
    neighborhood?: string;
    city?: string;
    state?: string;
  };
  installed_power_kwp?: number | string;
  estimated_annual_generation?: number | string;
  system_loss_percent?: number | string;
};

type GeocodingLevel =
  | "street_number"
  | "street"
  | "neighborhood"
  | "postal_code"
  | "city";

type GeocodingAttempt = {
  level: GeocodingLevel;
  query?: string;
  structured?: Record<string, string>;
  expected: {
    street: string;
    city: string;
    state: string;
    zip: string;
    houseNumber: string;
  };
};

const nominatimDelayMs = 1100;
const nominatimTimeoutMs = 12000;
const nominatimHeaders = {
  "Accept": "application/json",
  "Accept-Language": "pt-BR,pt;q=0.9,en;q=0.6",
  "Referer": "https://solarpro.app",
  "User-Agent": "SolarPro/1.0 (https://solarpro.app)",
};

Deno.serve(async (request) => {
  corsHeaders = getCorsHeaders(request.headers.get("Origin") ?? undefined);

  if (request.method === "OPTIONS") return jsonResponse({ ok: true });
  if (request.method !== "POST") {
    return jsonResponse({ error: "Metodo nao permitido." }, 405);
  }

  try {
    const token = bearerToken(request);
    if (!token) return jsonResponse({ error: "Token de acesso ausente." }, 401);

    const payload = (await request.json().catch(() => ({}))) as PvgisPayload;
    const location = await resolveLocation(payload);
    if ("error" in location) return jsonResponse({ error: location.error }, 400);

    const latitude = location.latitude;
    const longitude = location.longitude;
    const installedPower = toNumber(payload.installed_power_kwp);
    const estimatedAnnual = toNumber(payload.estimated_annual_generation);
    const loss = toNumber(payload.system_loss_percent ?? 14);
    const mode = `${payload.mode || "validate"}`.trim();

    const validation = validatePayload(latitude, longitude, installedPower);
    if (validation) return jsonResponse({ error: validation }, 400);

    const pvgisResult = await fetchPvgis({
      latitude,
      longitude,
      installedPower,
      loss,
    });
    if ("error" in pvgisResult) {
      return jsonResponse({ error: pvgisResult.error }, 502);
    }

    const data = pvgisResult.data;
    const monthly = data?.outputs?.monthly?.fixed;
    if (!Array.isArray(monthly) || monthly.length < 12) {
      return jsonResponse({ error: "PVGIS retornou dados incompletos." }, 502);
    }

    const monthlyGenerations = monthly
      .slice(0, 12)
      .map((item) => toNumber(item?.E_m))
      .filter((value) => value > 0);
    if (monthlyGenerations.length < 12) {
      return jsonResponse({ error: "PVGIS retornou valores mensais invalidos." }, 502);
    }
    const monthlyHsp = monthly
      .slice(0, 12)
      // H(i)_d is average daily plane-of-array irradiation (kWh/m²/day).
      // Its numeric value is used as monthly average daily HSP (h/day).
      .map((item) => toNumber(item?.["H(i)_d"]))
      .filter((value) => value > 0);
    if (monthlyHsp.length < 12) {
      return jsonResponse({ error: "PVGIS retornou HSP médio diário incompleto." }, 502);
    }

    const monthlyAverageDailyGenerations = extractMonthlyMetric(monthly, "E_d");
    const monthlyPlaneIrradiations = extractMonthlyMetric(monthly, "H(i)_m");
    const monthlyGenerationSd = extractMonthlyMetric(monthly, "SD_m");
    const totals = extractPvgisTotals(data);
    const monthlyAnnual = monthlyGenerations.reduce((sum, value) => sum + value, 0);
    const pvgisAnnual = totals.annualGeneration ?? monthlyAnnual;
    const pvgisAnnualSource = totals.annualGeneration === null ? "sum_E_m" : "E_y";
    const base = Math.max(estimatedAnnual, 1);
    const differencePercent = ((pvgisAnnual - estimatedAnnual) / base) * 100;
    const pvOrientation = extractPvOrientation(data);
    const radiationDatabase = extractRadiationDatabase(data);

    return jsonResponse({
      ok: true,
      mode,
      orientation_mode: pvOrientation.mode,
      pv_slope: pvOrientation.slope,
      pv_azimuth: pvOrientation.azimuth,
      pvgis_aspect: pvOrientation.pvgisAspect,
      pvgis_system_loss_percent: loss,
      pvgis_radiation_database: radiationDatabase,
      estimated_annual_generation: estimatedAnnual,
      pvgis_annual_generation: pvgisAnnual,
      pvgis_annual_generation_source: pvgisAnnualSource,
      monthly_generations: monthlyGenerations,
      monthly_hsp: monthlyHsp,
      monthly_average_daily_generation_kwh: monthlyAverageDailyGenerations,
      monthly_plane_irradiation_kwh_m2: monthlyPlaneIrradiations,
      monthly_generation_sd_kwh: monthlyGenerationSd,
      pvgis_annual_plane_irradiation_kwh_m2: totals.annualPlaneIrradiation,
      pvgis_annual_generation_sd_kwh: totals.annualGenerationSd,
      pvgis_l_aoi_percent: totals.lAoi,
      pvgis_l_spec_percent: totals.lSpec,
      pvgis_l_tg_percent: totals.lTg,
      pvgis_l_total_percent: totals.lTotal,
      difference_percent: differencePercent,
      latitude,
      longitude,
      location_source: location.source,
      location_label: location.label,
      geocoding_provider: location.geocodingProvider,
      geocoding_level: location.geocodingLevel,
      geocoding_result_type: location.geocodingResultType,
    });
  } catch (error) {
    return jsonResponse(
      { error: "Nao foi possivel validar com PVGIS." },
      500,
    );
  }
});

async function fetchPvgis(options: {
  latitude: number;
  longitude: number;
  installedPower: number;
  loss: number;
}) {
  const baseParams = {
    lat: options.latitude.toFixed(6),
    lon: options.longitude.toFixed(6),
    peakpower: options.installedPower.toFixed(4),
    loss: options.loss.toFixed(2),
    pvtechchoice: "crystSi",
    mountingplace: "free",
    optimalangles: "1",
    outputformat: "json",
  };
  const databases = ["", "PVGIS-SARAH3", "PVGIS-ERA5"];
  const errors: string[] = [];

  for (const database of databases) {
    const params = new URLSearchParams(baseParams);
    if (database) params.set("raddatabase", database);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000); // S1.1: Reduced timeout from 20s
    try {
      const response = await fetch(
        `https://re.jrc.ec.europa.eu/api/v5_3/PVcalc?${params.toString()}`,
        { signal: controller.signal },
      );
      const rawText = await response.text();
      if (response.ok) {
        return { data: JSON.parse(rawText) };
      }
      errors.push(
        `${database || "auto"}: ${response.status} ${extractPvgisMessage(rawText)}`,
      );
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") {
        errors.push(`${database || "auto"}: tempo excedido`);
      } else {
        errors.push(
          `${database || "auto"}: ${
            error instanceof Error ? error.message : String(error)
          }`,
        );
      }
    } finally {
      clearTimeout(timeout);
    }
  }

  return {
    error:
      `PVGIS recusou a consulta para as coordenadas ${options.latitude.toFixed(5)}, ${options.longitude.toFixed(5)}. ` +
      errors.filter(Boolean).join(" | "),
  };
}

function extractPvOrientation(data: any) {
  const fixed = data?.inputs?.mounting_system?.fixed;
  const slope = finiteOrNull(toNumber(fixed?.slope?.value));
  const pvgisAspect = finiteOrNull(toNumber(fixed?.azimuth?.value));

  return {
    mode: "automatic",
    slope,
    pvgisAspect,
    azimuth: pvgisAspect === null
      ? null
      : pvgisAspectToGeographicAzimuth(pvgisAspect),
  };
}

function extractRadiationDatabase(data: any) {
  const value = data?.inputs?.meteo_data?.radiation_db;
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length ? trimmed : null;
}

function extractMonthlyMetric(monthly: any[], key: string) {
  const values = monthly
    .slice(0, 12)
    .map((item) => finiteOrNull(toNumber(item?.[key])));
  return values.every((value) => value !== null) ? values : [];
}

function extractPvgisTotals(data: any) {
  const fixed = data?.outputs?.totals?.fixed;
  const annualGeneration = positiveFiniteOrNull(toNumber(fixed?.E_y));

  return {
    annualGeneration,
    annualPlaneIrradiation: finiteOrNull(toNumber(fixed?.["H(i)_y"])),
    annualGenerationSd: finiteOrNull(toNumber(fixed?.SD_y)),
    lAoi: finiteOrNull(toNumber(fixed?.l_aoi)),
    lSpec: finiteOrNull(toNumber(fixed?.l_spec)),
    lTg: finiteOrNull(toNumber(fixed?.l_tg)),
    lTotal: finiteOrNull(toNumber(fixed?.l_total)),
  };
}

function positiveFiniteOrNull(value: number) {
  return Number.isFinite(value) && value > 0 ? value : null;
}

// PVGIS uses aspect/azimuth with 0=south, 90=west, -90=east.
// Solar Pro exposes pv_azimuth as conventional geographic azimuth:
// 0/360=north, 90=east, 180=south, 270=west.
function pvgisAspectToGeographicAzimuth(pvgisAspect: number) {
  return normalizeDegrees(180 + pvgisAspect);
}

function normalizeDegrees(value: number) {
  return ((value % 360) + 360) % 360;
}

function finiteOrNull(value: number) {
  return Number.isFinite(value) ? value : null;
}

async function resolveLocation(payload: PvgisPayload) {
  const latitude = toNumber(payload.latitude);
  const longitude = toNumber(payload.longitude);
  if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
    return {
      latitude,
      longitude,
      source: "current_location",
      label: "Localização atual",
      geocodingProvider: null,
      geocodingLevel: null,
      geocodingResultType: null,
    };
  }

  const attempts = geocodingAttempts(payload.address);
  if (attempts.length === 0) {
    return {
      error:
        "Endereço insuficiente. Informe pelo menos cidade e estado para localizar o projeto.",
    };
  }

  let lastError = "";
  let calledNominatim = false;
  for (const attempt of attempts) {
    if (calledNominatim) await delay(nominatimDelayMs);
    const result = await geocodeAttempt(attempt);
    calledNominatim = true;
    if ("error" in result) {
      lastError = result.error;
      continue;
    }
    return result;
  }

  return {
    error:
      lastError ||
      "Não encontramos coordenadas para o endereço do cliente. Confira CEP, cidade e estado.",
  };
}

async function geocodeAttempt(attempt: GeocodingAttempt) {
  const params = new URLSearchParams({
    format: "jsonv2",
    limit: "3",
    countrycodes: "br",
    addressdetails: "1",
  });
  if (attempt.query) {
    params.set("q", attempt.query);
  } else if (attempt.structured) {
    for (const [key, value] of Object.entries(attempt.structured)) {
      if (value) params.set(key, value);
    }
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), nominatimTimeoutMs);
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/search?${params.toString()}`,
      {
        headers: nominatimHeaders,
        signal: controller.signal,
      },
    );
    if (!response.ok) {
      return { error: `Geocodificação retornou erro ${response.status}.` };
    }

    const data = await response.json();
    if (!Array.isArray(data) || data.length === 0) {
      return { error: "" };
    }

    for (const candidate of data) {
      const selected = selectGeocodingCandidate(attempt, candidate);
      if (selected) return selected;
    }
    return { error: "" };
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      return { error: "Geocodificação demorou demais para responder." };
    }
    return {
      error: error instanceof Error
        ? `Falha na geocodificação: ${error.message}`
        : "Falha na geocodificação.",
    };
  } finally {
    clearTimeout(timeout);
  }
}

function selectGeocodingCandidate(attempt: GeocodingAttempt, candidate: any) {
  const latitude = toNumber(candidate?.lat);
  const longitude = toNumber(candidate?.lon);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

  const address = candidate?.address || {};
  if (hasStateMismatch(attempt.expected.state, address)) return null;
  if (hasCityMismatch(attempt.expected.city, address)) return null;
  if (
    ["street_number", "street"].includes(attempt.level) &&
    hasRoadMismatch(attempt.expected.street, address)
  ) {
    return null;
  }

  // CEPs can be stale in OSM/CEP providers, so only postal-code-level
  // attempts reject an explicit postcode mismatch.
  if (attempt.level === "postal_code" && attempt.expected.zip) {
    const postcode = onlyDigits(address?.postcode);
    if (postcode && postcode !== attempt.expected.zip) return null;
  }

  if (attempt.level === "street_number" && attempt.expected.houseNumber) {
    const houseNumber = clean(address?.house_number);
    if (houseNumber && !sameText(houseNumber, attempt.expected.houseNumber)) {
      return null;
    }
  }

  return {
    latitude,
    longitude,
    source: "client_address",
    label: `${candidate?.display_name || geocodingAttemptLabel(attempt)}`,
    geocodingProvider: "nominatim",
    geocodingLevel: attempt.level,
    geocodingResultType: nullableClean(candidate?.addresstype || candidate?.type),
  };
}

function geocodingAttempts(address?: PvgisPayload["address"]) {
  if (!address) return [];
  const street = clean(address.street);
  const number = clean(address.address_number);
  const neighborhood = clean(address.neighborhood);
  const city = clean(address.city);
  const state = clean(address.state).toUpperCase();
  const zip = onlyDigits(address.zip_code);

  if (!city || !/^[A-Z]{2}$/.test(state)) return [];

  const expected = { street, city, state, zip, houseNumber: number };
  const attempts: GeocodingAttempt[] = [];

  if (street && number) {
    attempts.push({
      level: "street_number",
      structured: {
        street: `${number} ${street}`,
        city,
        state,
        postalcode: zip,
        country: "Brasil",
      },
      expected,
    });
  }
  if (street) {
    attempts.push({
      level: "street",
      structured: { street, city, state, country: "Brasil" },
      expected,
    });
  }
  if (neighborhood) {
    attempts.push({
      level: "neighborhood",
      query: joinQuery([neighborhood, city, state, "Brasil"]),
      expected,
    });
  }
  if (zip) {
    attempts.push({
      level: "postal_code",
      structured: { postalcode: zip, city, state, country: "Brasil" },
      expected,
    });
  }
  attempts.push({
    level: "city",
    structured: { city, state, country: "Brasil" },
    expected,
  });

  return attempts;
}

function hasStateMismatch(expectedState: string, address: any) {
  const resultState = stateCodeFromAddress(address);
  return resultState !== null && resultState !== expectedState;
}

function stateCodeFromAddress(address: any) {
  const values = Object.values(address || {});
  for (const value of values) {
    const match = `${value ?? ""}`.toUpperCase().match(/\bBR-([A-Z]{2})\b/);
    if (match) return match[1];
  }
  return null;
}

function hasCityMismatch(expectedCity: string, address: any) {
  const resultCity = [
    address?.city,
    address?.town,
    address?.village,
    address?.municipality,
  ].map(nullableClean).find(Boolean);
  return resultCity !== undefined && !sameText(resultCity, expectedCity);
}

function hasRoadMismatch(expectedStreet: string, address: any) {
  const resultRoad = nullableClean(address?.road);
  if (!expectedStreet || !resultRoad) return false;
  return !textLooksCompatible(resultRoad, expectedStreet);
}

function geocodingAttemptLabel(attempt: GeocodingAttempt) {
  if (attempt.query) return attempt.query;
  const parts = [
    attempt.structured?.street,
    attempt.structured?.postalcode,
    attempt.structured?.city,
    attempt.structured?.state,
    attempt.structured?.country,
  ];
  return joinQuery(parts);
}

function joinQuery(parts: Array<string | undefined>) {
  return parts.map(clean).filter(Boolean).join(", ");
}

function clean(value: unknown) {
  return `${value ?? ""}`.trim().replace(/\s+/g, " ");
}

function nullableClean(value: unknown) {
  const text = clean(value);
  return text || null;
}

function sameText(a: unknown, b: unknown) {
  return normalizeText(a) === normalizeText(b);
}

function textLooksCompatible(a: unknown, b: unknown) {
  const normalizedA = normalizeText(a);
  const normalizedB = normalizeText(b);
  return (
    normalizedA === normalizedB ||
    normalizedA.includes(normalizedB) ||
    normalizedB.includes(normalizedA)
  );
}

function normalizeText(value: unknown) {
  return clean(value)
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase();
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function onlyDigits(value: unknown) {
  return clean(value).replace(/\D/g, "");
}

function extractPvgisMessage(rawText: string) {
  const text = `${rawText || ""}`.trim();
  if (!text) return "sem detalhe";
  try {
    const data = JSON.parse(text);
    const message =
      data?.message || data?.error || data?.detail || data?.description;
    if (message) return cleanMessage(message);
  } catch (_) {
    // PVGIS sometimes returns plain text or HTML for bad requests.
  }
  return cleanMessage(text.replace(/<[^>]+>/g, " "));
}

function cleanMessage(value: unknown) {
  const text = clean(value);
  if (text.length <= 160) return text;
  return `${text.slice(0, 160)}...`;
}

function validatePayload(
  latitude: number,
  longitude: number,
  installedPower: number,
) {
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    return "Latitude invalida.";
  }
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    return "Longitude invalida.";
  }
  if (!Number.isFinite(installedPower) || installedPower <= 0) {
    return "Potencia instalada invalida.";
  }
  return "";
}

function toNumber(value: unknown) {
  if (typeof value === "number") return value;
  if (value === null || value === undefined) return Number.NaN;
  const normalized = `${value ?? ""}`.trim().replace(",", ".");
  if (!normalized) return Number.NaN;
  return Number(normalized);
}

function bearerToken(request: Request) {
  const header = request.headers.get("Authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? "";
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
