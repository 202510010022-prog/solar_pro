import re
from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import pdfplumber


MONTH_ALIASES = {
    "jan": "Jan",
    "janeiro": "Jan",
    "fev": "Fev",
    "fevereiro": "Fev",
    "mar": "Mar",
    "marco": "Mar",
    "março": "Mar",
    "abr": "Abr",
    "abril": "Abr",
    "mai": "Mai",
    "maio": "Mai",
    "jun": "Jun",
    "junho": "Jun",
    "jul": "Jul",
    "julho": "Jul",
    "ago": "Ago",
    "agosto": "Ago",
    "set": "Set",
    "setembro": "Set",
    "out": "Out",
    "outubro": "Out",
    "nov": "Nov",
    "novembro": "Nov",
    "dez": "Dez",
    "dezembro": "Dez",
}

MONTH_ORDER = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]


@dataclass(frozen=True)
class BillImportResult:
    pdf_path: Path
    raw_text: str
    client_name: str
    uc: str
    monthly_consumptions: list[float]
    consumption_table: pd.DataFrame

    @property
    def annual_consumption(self):
        return sum(self.monthly_consumptions)

    @property
    def average_consumption(self):
        return self.annual_consumption / 12 if self.monthly_consumptions else 0


class BillImporterService:
    def import_pdf(self, pdf_path):
        path = Path(pdf_path)
        if not path.exists():
            raise FileNotFoundError(f"PDF não encontrado: {path}")

        raw_text = self.extract_text(path)
        client_name = self.identify_client(raw_text)
        uc = self.identify_uc(raw_text)
        consumption_table = self.identify_monthly_consumption(raw_text)
        monthly_consumptions = self.to_monthly_series(consumption_table)

        return BillImportResult(
            pdf_path=path,
            raw_text=raw_text,
            client_name=client_name,
            uc=uc,
            monthly_consumptions=monthly_consumptions,
            consumption_table=consumption_table,
        )

    def extract_text(self, pdf_path):
        pages = []
        with pdfplumber.open(str(pdf_path)) as pdf:
            for page in pdf.pages:
                text = page.extract_text(x_tolerance=1, y_tolerance=3) or ""
                pages.append(text)
        return "\n".join(pages)

    def identify_client(self, text):
        patterns = [
            r"(?:nome\s+do\s+cliente|cliente|consumidor|titular)\s*[:\-]?\s*([A-ZÀ-Ú][A-ZÀ-Ú0-9 .,&'-]{4,})",
            r"(?:dados\s+do\s+cliente)[\s\S]{0,80}?([A-ZÀ-Ú][A-ZÀ-Ú0-9 .,&'-]{4,})",
        ]
        for pattern in patterns:
            match = re.search(pattern, text, flags=re.IGNORECASE)
            if match:
                return self._clean_label_value(match.group(1))

        for line in text.splitlines()[:20]:
            clean = self._clean_label_value(line)
            if self._looks_like_name(clean):
                return clean
        return ""

    def identify_uc(self, text):
        patterns = [
            r"\bUC\b\s*[:\-]?\s*([0-9A-Z.\-/]{4,})",
            r"unidade\s+consumidora\s*[:\-]?\s*([0-9A-Z.\-/]{4,})",
            r"n[ºo°]?\s*da\s+uc\s*[:\-]?\s*([0-9A-Z.\-/]{4,})",
            r"instala[cç][aã]o\s*[:\-]?\s*([0-9A-Z.\-/]{4,})",
            r"conta\s+contrato\s*[:\-]?\s*([0-9A-Z.\-/]{4,})",
        ]
        for pattern in patterns:
            match = re.search(pattern, text, flags=re.IGNORECASE)
            if match:
                return self._clean_code(match.group(1))
        return ""

    def identify_monthly_consumption(self, text):
        rows = []
        seen = set()
        for line in text.splitlines():
            normalized = self._normalize_text(line)
            month = self._month_from_line(normalized)
            if not month:
                continue
            value = self._kwh_from_line(normalized)
            if value is None:
                continue
            key = (month, value)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "month": month,
                    "consumption_kwh": value,
                    "source_line": line.strip(),
                }
            )

        table = pd.DataFrame(rows, columns=["month", "consumption_kwh", "source_line"])
        if not table.empty:
            table["month_order"] = table["month"].map({month: index for index, month in enumerate(MONTH_ORDER)})
            table = table.sort_values(["month_order"]).drop(columns=["month_order"])
            table = table.drop_duplicates(subset=["month"], keep="last")
        return table.reset_index(drop=True)

    def to_monthly_series(self, consumption_table):
        values_by_month = {
            row["month"]: float(row["consumption_kwh"])
            for _, row in consumption_table.iterrows()
        }
        return [values_by_month.get(month, 0.0) for month in MONTH_ORDER]

    def _month_from_line(self, normalized_line):
        for alias, month in MONTH_ALIASES.items():
            if re.search(rf"\b{re.escape(alias)}(?:/\d{{2,4}})?\b", normalized_line):
                return month
        return None

    def _kwh_from_line(self, normalized_line):
        patterns = [
            r"([0-9]{1,5}(?:[.,][0-9]{1,2})?)\s*kwh\b",
            r"\bkwh\s*[:\-]?\s*([0-9]{1,5}(?:[.,][0-9]{1,2})?)",
        ]
        for pattern in patterns:
            values = re.findall(pattern, normalized_line)
            if values:
                return self._parse_number(values[-1])

        numbers = re.findall(r"\b([0-9]{2,5}(?:[.,][0-9]{1,2})?)\b", normalized_line)
        if numbers and any(alias in normalized_line for alias in MONTH_ALIASES):
            return self._parse_number(numbers[-1])
        return None

    def _parse_number(self, value):
        text = str(value).strip()
        if "," in text and "." in text:
            text = text.replace(".", "").replace(",", ".")
        else:
            text = text.replace(",", ".")
        return float(text)

    def _normalize_text(self, value):
        return value.lower().replace("ç", "c").replace("ã", "a").replace("á", "a").replace("é", "e")

    def _clean_label_value(self, value):
        clean = re.sub(r"\s+", " ", str(value or "")).strip(" :-")
        clean = re.split(
            r"\b(?:cpf|cnpj|uc|unidade|instala[cç][aã]o|endereco|endereço|telefone)\b",
            clean,
            maxsplit=1,
            flags=re.IGNORECASE,
        )[0]
        return clean.strip(" :-")

    def _clean_code(self, value):
        return re.sub(r"[^0-9A-Z.\-/]", "", str(value or "").upper())

    def _looks_like_name(self, value):
        if len(value) < 6 or any(char.isdigit() for char in value):
            return False
        blocked = {"energia", "fatura", "conta", "vencimento", "pagamento"}
        lowered = value.lower()
        return not any(word in lowered for word in blocked)
