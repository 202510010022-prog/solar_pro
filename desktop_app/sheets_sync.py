import json
import sys
from datetime import datetime
from pathlib import Path

from desktop_app.database import (
    export_budgets,
    export_clients,
    replace_database_data,
)
from desktop_app.sync_types import AppUser, SyncError

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]

CLIENT_HEADERS = [
    "id",
    "name",
    "document",
    "phone",
    "email",
    "city",
    "state",
]

BUDGET_HEADERS = [
    "id",
    "client_id",
    "budget_date",
    "status",
    "monthly_consumption",
    "sun_hours",
    "monthly_consumptions",
    "monthly_hsp",
    "monthly_generations",
    "monthly_balances",
    "generation_extra_percent",
    "average_consumption",
    "average_hsp",
    "annual_consumption",
    "annual_generation",
    "performance_ratio",
    "module_power",
    "energy_tariff",
    "investment",
    "system_power",
    "module_count",
    "monthly_generation",
    "monthly_savings",
    "payback_years",
    "down_payment",
    "monthly_interest_rate",
    "term_months",
    "financed_amount",
    "monthly_payment",
    "total_paid",
    "total_interest",
    "client_name",
]

USER_HEADERS = [
    "matricula",
    "nome",
    "email",
    "cargo",
    "permissao",
    "ativo",
    "pin",
]

HISTORY_HEADERS = [
    "data_hora",
    "matricula",
    "nome",
    "acao",
    "entidade",
    "detalhe",
]


def get_config_path():
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent / "sheets_config.json"

    return Path(__file__).resolve().parent / "sheets_config.json"


def load_config():
    path = get_config_path()
    if not path.exists():
        return {
            "enabled": False,
            "config_path": str(path),
        }

    with path.open("r", encoding="utf-8") as file:
        config = json.load(file)

    config["config_path"] = str(path)
    return config


class SheetsSync:
    def __init__(self, config):
        self.config = config
        self.enabled = bool(config.get("enabled"))
        self.service = None

    @classmethod
    def from_config(cls):
        return cls(load_config())

    def is_configured(self):
        required = [
            "service_account_file",
            "users_spreadsheet_id",
            "system_spreadsheet_id",
        ]
        return self.enabled and all(self.config.get(key) for key in required)

    def connect(self):
        if self.service is not None:
            return self.service

        if not self.is_configured():
            raise SyncError("Integração Google Sheets não configurada.")

        try:
            from google.oauth2.service_account import Credentials
            from googleapiclient.discovery import build
        except ImportError as error:
            raise SyncError(
                "Bibliotecas do Google não estão instaladas."
            ) from error

        config_path = Path(self.config["config_path"])
        credentials_path = Path(self.config["service_account_file"])
        if not credentials_path.is_absolute():
            credentials_path = config_path.parent / credentials_path

        if not credentials_path.exists():
            raise SyncError(
                f"Arquivo de credenciais não encontrado: {credentials_path}"
            )

        credentials = Credentials.from_service_account_file(
            credentials_path,
            scopes=SCOPES,
        )
        self.service = build(
            "sheets",
            "v4",
            credentials=credentials,
            cache_discovery=False,
        )

        return self.service

    def authenticate_user(self, matricula, pin):
        matricula = (matricula or "").strip()
        pin = (pin or "").strip()
        if not matricula:
            raise SyncError("Informe a matrícula.")

        users = self.read_records(
            self.config["users_spreadsheet_id"],
            self.config.get("users_sheet", "Usuarios"),
            USER_HEADERS,
        )

        for user in users:
            if str(user.get("matricula", "")).strip() != matricula:
                continue

            ativo = str(user.get("ativo", "")).strip().lower()
            if ativo not in {"sim", "s", "ativo", "true", "1"}:
                raise SyncError("Usuário inativo na planilha de controle.")

            expected_pin = str(user.get("pin", "")).strip()
            if expected_pin and expected_pin != pin:
                raise SyncError("PIN inválido.")

            return AppUser(
                matricula=matricula,
                nome=str(user.get("nome", "")).strip() or matricula,
                email=str(user.get("email", "")).strip(),
                cargo=str(user.get("cargo", "")).strip(),
                permissao=str(user.get("permissao", "usuario")).strip()
                or "usuario",
            )

        raise SyncError("Matrícula não autorizada.")

    def pull_to_local(self):
        spreadsheet_id = self.config["system_spreadsheet_id"]
        clients = self.read_records(
            spreadsheet_id,
            self.config.get("clients_sheet", "Clientes"),
            CLIENT_HEADERS,
        )
        budgets = self.read_records(
            spreadsheet_id,
            self.config.get("budgets_sheet", "Orcamentos"),
            BUDGET_HEADERS,
        )

        if clients or budgets:
            replace_database_data(
                [self._coerce_client(row) for row in clients],
                [self._coerce_budget(row) for row in budgets],
            )

        return len(clients), len(budgets)

    def push_from_local(self, user, action, entity, detail):
        spreadsheet_id = self.config["system_spreadsheet_id"]
        self.write_records(
            spreadsheet_id,
            self.config.get("clients_sheet", "Clientes"),
            CLIENT_HEADERS,
            export_clients(),
        )
        self.write_records(
            spreadsheet_id,
            self.config.get("budgets_sheet", "Orcamentos"),
            BUDGET_HEADERS,
            export_budgets(),
        )
        self.append_history(user, action, entity, detail)

    def append_history(self, user, action, entity, detail):
        spreadsheet_id = self.config["system_spreadsheet_id"]
        sheet_name = self.config.get("history_sheet", "Historico")
        self.ensure_header(spreadsheet_id, sheet_name, HISTORY_HEADERS)
        values = [[
            datetime.now().strftime("%d/%m/%Y %H:%M:%S"),
            user.matricula,
            user.nome,
            action,
            entity,
            detail,
        ]]
        self.connect().spreadsheets().values().append(
            spreadsheetId=spreadsheet_id,
            range=f"{sheet_name}!A:F",
            valueInputOption="USER_ENTERED",
            insertDataOption="INSERT_ROWS",
            body={"values": values},
        ).execute()

    def read_records(self, spreadsheet_id, sheet_name, headers):
        self.ensure_header(spreadsheet_id, sheet_name, headers)
        result = self.connect().spreadsheets().values().get(
            spreadsheetId=spreadsheet_id,
            range=f"{sheet_name}!A1:AZ",
        ).execute()
        values = result.get("values", [])
        if len(values) <= 1:
            return []

        sheet_headers = values[0]
        records = []
        for row in values[1:]:
            if not any(str(cell).strip() for cell in row):
                continue
            record = {}
            for index, header in enumerate(sheet_headers):
                record[header] = row[index] if index < len(row) else ""
            records.append(record)

        return records

    def write_records(self, spreadsheet_id, sheet_name, headers, records):
        self.ensure_header(spreadsheet_id, sheet_name, headers)
        values = [headers]
        for record in records:
            values.append([
                self._cell_value(record.get(header, ""))
                for header in headers
            ])

        end_column = self._column_name(len(headers))
        self.connect().spreadsheets().values().clear(
            spreadsheetId=spreadsheet_id,
            range=f"{sheet_name}!A:{end_column}",
            body={},
        ).execute()
        self.connect().spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=f"{sheet_name}!A1",
            valueInputOption="USER_ENTERED",
            body={"values": values},
        ).execute()

    def ensure_header(self, spreadsheet_id, sheet_name, headers):
        self.ensure_sheet(spreadsheet_id, sheet_name)
        result = self.connect().spreadsheets().values().get(
            spreadsheetId=spreadsheet_id,
            range=f"{sheet_name}!A1:AZ1",
        ).execute()
        current = result.get("values", [[]])[0]
        if current[:len(headers)] == headers:
            return

        self.connect().spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=f"{sheet_name}!A1",
            valueInputOption="USER_ENTERED",
            body={"values": [headers]},
        ).execute()

    def ensure_sheet(self, spreadsheet_id, sheet_name):
        metadata = self.connect().spreadsheets().get(
            spreadsheetId=spreadsheet_id
        ).execute()
        titles = {
            sheet["properties"]["title"]
            for sheet in metadata.get("sheets", [])
        }
        if sheet_name in titles:
            return

        self.connect().spreadsheets().batchUpdate(
            spreadsheetId=spreadsheet_id,
            body={
                "requests": [
                    {
                        "addSheet": {
                            "properties": {
                                "title": sheet_name,
                            }
                        }
                    }
                ]
            },
        ).execute()

    def _coerce_client(self, row):
        return {
            "id": self._int(row.get("id")),
            "name": row.get("name", ""),
            "document": row.get("document", ""),
            "phone": row.get("phone", ""),
            "email": row.get("email", ""),
            "city": row.get("city", ""),
            "state": row.get("state", ""),
        }

    def _coerce_budget(self, row):
        integer_fields = {"id", "client_id", "module_count", "term_months"}
        text_fields = {
            "budget_date",
            "status",
            "monthly_consumptions",
            "monthly_hsp",
            "monthly_generations",
            "monthly_balances",
        }
        budget = {}
        for header in BUDGET_HEADERS:
            if header == "client_name":
                continue
            value = row.get(header, "")
            if header in integer_fields:
                budget[header] = self._int(value)
            elif header in text_fields:
                budget[header] = value
            else:
                budget[header] = self._float(value)

        return budget

    def _int(self, value):
        try:
            return int(self._float(value))
        except (TypeError, ValueError):
            return 0

    def _float(self, value):
        try:
            text = str(value).strip()
            if "," in text:
                text = text.replace(".", "").replace(",", ".")
            return float(text or 0)
        except (TypeError, ValueError):
            return 0

    def _cell_value(self, value):
        if value is None:
            return ""

        return str(value)

    def _column_name(self, index):
        name = ""
        while index:
            index, remainder = divmod(index - 1, 26)
            name = chr(65 + remainder) + name

        return name or "A"
