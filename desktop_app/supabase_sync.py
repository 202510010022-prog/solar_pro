import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path

from desktop_app.database import (
    export_clients,
    export_project_documents,
    export_project_payments,
    export_projects,
    replace_database_data,
)
from desktop_app.sync_types import AppUser, SyncError


CLIENT_COLUMNS = [
    "id",
    "name",
    "document",
    "phone",
    "email",
    "zip_code",
    "street",
    "address_number",
    "neighborhood",
    "city",
    "state",
    "address_complement",
]

PROJECT_COLUMNS = [
    "id",
    "client_id",
    "project_date",
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
    "module_count",
    "energy_tariff",
    "project_value",
    "labor_cost",
    "module_unit_cost",
    "inverter_cost",
    "support_cost",
    "extra_materials",
    "system_power",
    "monthly_generation",
    "monthly_savings",
    "payback_years",
    "down_payment",
    "payment_type",
    "discount",
    "installments_count",
    "installment_value",
    "first_due_date",
    "financial_notes",
    "monthly_interest_rate",
    "term_months",
    "financed_amount",
    "monthly_payment",
    "total_paid",
    "total_interest",
    "history",
]

PROJECT_PAYMENT_COLUMNS = [
    "id",
    "project_id",
    "amount",
    "payment_type",
    "paid_at",
    "status",
    "notes",
    "created_at",
    "updated_at",
]

PROJECT_DOCUMENT_COLUMNS = [
    "id",
    "project_id",
    "category",
    "original_name",
    "stored_path",
    "file_size",
    "created_at",
]


def get_config_path():
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent / "supabase_config.json"

    return Path(__file__).resolve().parent / "supabase_config.json"


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


class SupabaseSync:
    provider_name = "Supabase"
    login_label = "Email"
    password_label = "Senha"
    login_placeholder = "email@empresa.com"
    password_placeholder = "Senha do Supabase"

    def __init__(self, config):
        self.config = config
        self.enabled = bool(config.get("enabled"))
        self.access_token = ""
        self.user_id = ""
        self.user = None
        self.company_id = ""

    @classmethod
    def from_config(cls):
        return cls(load_config())

    def is_configured(self):
        return bool(
            self.enabled
            and self.config.get("url")
            and self.config.get("anon_key")
        )

    def authenticate_user(self, login, password):
        email = (login or "").strip()
        password = (password or "").strip()
        if not email:
            raise SyncError("Informe o email.")
        if not password:
            raise SyncError("Informe a senha.")

        response = self._request(
            "POST",
            "/auth/v1/token?grant_type=password",
            body={
                "email": email,
                "password": password,
            },
            use_auth=False,
        )
        self.access_token = response.get("access_token", "")
        auth_user = response.get("user") or {}
        self.user_id = auth_user.get("id", "")
        if not self.access_token or not self.user_id:
            raise SyncError("Login Supabase não retornou sessão válida.")

        profile = self._get_profile()
        if not profile.get("active", True):
            raise SyncError("Usuário inativo no Supabase.")

        self.company_id = profile.get("company_id", "")
        self.user = AppUser(
            matricula=profile.get("matricula") or email,
            nome=profile.get("name") or email,
            email=profile.get("email") or email,
            cargo=profile.get("role") or "",
            permissao=profile.get("permission") or "usuario",
        )
        return self.user

    def pull_to_local(self):
        self._require_session()
        clients = self._request(
            "GET",
            (
                "/rest/v1/clients?"
                f"company_id=eq.{self.company_id}&select=*&order=name.asc"
            ),
        )
        projects = self._request(
            "GET",
            (
                "/rest/v1/projects?"
                f"company_id=eq.{self.company_id}&select=*&order=id.desc"
            ),
        )
        project_documents = self._request(
            "GET",
            (
                "/rest/v1/project_documents?"
                f"company_id=eq.{self.company_id}&select=*&order=id.desc"
            ),
        )
        project_payments = self._request(
            "GET",
            (
                "/rest/v1/project_payments?"
                f"company_id=eq.{self.company_id}&select=*&order=id.desc"
            ),
        )
        if clients or projects or project_documents or project_payments:
            replace_database_data(
                [self._local_client(row) for row in clients],
                [self._local_project(row) for row in projects],
                [self._local_project_document(row) for row in project_documents],
                [self._local_project_payment(row) for row in project_payments],
            )
        return len(clients), len(projects)

    def push_from_local(self, user, action, entity, detail):
        self._require_session()
        clients = export_clients()
        projects = export_projects()
        project_documents = export_project_documents()
        project_payments = export_project_payments()
        self._upsert_records(
            "clients",
            [self._remote_client(row) for row in clients],
        )
        self._upsert_records(
            "projects",
            [self._remote_project(row) for row in projects],
        )
        self._upsert_records(
            "project_documents",
            [self._remote_project_document(row) for row in project_documents],
        )
        self._upsert_records(
            "project_payments",
            [self._remote_project_payment(row) for row in project_payments],
        )
        if action == "excluiu":
            self._delete_missing_records(
                "project_payments",
                [row["id"] for row in project_payments],
            )
            self._delete_missing_records(
                "project_documents",
                [row["id"] for row in project_documents],
            )
            self._delete_missing_records("projects", [row["id"] for row in projects])
            self._delete_missing_records("clients", [row["id"] for row in clients])
        self._request(
            "POST",
            "/rest/v1/action_history",
            body={
                "company_id": self.company_id,
                "user_id": self.user_id,
                "user_matricula": user.matricula,
                "user_name": user.nome,
                "action": action,
                "entity": entity,
                "detail": detail,
                "created_at": datetime.utcnow().isoformat() + "Z",
            },
            prefer="return=minimal",
        )

    def _get_profile(self):
        result = self._request(
            "GET",
            f"/rest/v1/profiles?select=*&id=eq.{self.user_id}&limit=1",
        )
        if not result:
            raise SyncError(
                "Usuário autenticado, mas sem perfil em public.profiles."
            )
        return result[0]

    def _upsert_records(self, table, records):
        if not records:
            return
        self._request(
            "POST",
            f"/rest/v1/{table}",
            body=records,
            prefer="resolution=merge-duplicates,return=minimal",
        )

    def _delete_missing_records(self, table, local_ids):
        ids = [str(record_id) for record_id in local_ids if record_id is not None]
        if ids:
            filter_path = f"id=not.in.({','.join(ids)})"
        else:
            filter_path = f"company_id=eq.{self.company_id}"

        self._request(
            "DELETE",
            f"/rest/v1/{table}?{filter_path}",
            prefer="return=minimal",
        )

    def _remote_client(self, row):
        record = {column: row.get(column, "") for column in CLIENT_COLUMNS}
        record["company_id"] = self.company_id
        return record

    def _remote_project(self, row):
        record = {column: row.get(column, 0) for column in PROJECT_COLUMNS}
        record["project_date"] = row.get("project_date") or row.get("budget_date", "")
        record["project_value"] = row.get("project_value", row.get("investment", 0))
        record["company_id"] = self.company_id
        return record

    def _remote_project_document(self, row):
        record = {
            column: row.get(column, "" if column != "file_size" else 0)
            for column in PROJECT_DOCUMENT_COLUMNS
        }
        record["company_id"] = self.company_id
        return record

    def _remote_project_payment(self, row):
        record = {
            column: row.get(column, "" if column in {"payment_type", "status", "notes"} else 0)
            for column in PROJECT_PAYMENT_COLUMNS
        }
        record["company_id"] = self.company_id
        record["created_by"] = self.user_id or None
        return record

    def _local_client(self, row):
        return {column: row.get(column, "") for column in CLIENT_COLUMNS}

    def _local_project(self, row):
        project = {column: row.get(column, 0) for column in PROJECT_COLUMNS}
        project["budget_date"] = project.get("project_date", "")
        project["investment"] = project.get("project_value", 0)
        return project

    def _local_project_document(self, row):
        return {
            column: row.get(column, "" if column != "file_size" else 0)
            for column in PROJECT_DOCUMENT_COLUMNS
        }

    def _local_project_payment(self, row):
        return {
            column: row.get(column, "" if column in {"payment_type", "status", "notes"} else 0)
            for column in PROJECT_PAYMENT_COLUMNS
        }

    def _require_session(self):
        if not self.access_token:
            raise SyncError("Faça login no Supabase antes de sincronizar.")
        if not self.company_id:
            raise SyncError("Perfil sem empresa vinculada.")

    def _request(self, method, path, body=None, use_auth=True, prefer=None):
        base_url = self.config.get("url", "").rstrip("/")
        if not base_url:
            raise SyncError("URL do Supabase não configurada.")

        url = base_url + path
        data = None
        headers = {
            "apikey": self.config.get("anon_key", ""),
            "Content-Type": "application/json",
        }
        if use_auth and self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        if prefer:
            headers["Prefer"] = prefer
        if body is not None:
            data = json.dumps(body).encode("utf-8")

        request = urllib.request.Request(
            url,
            data=data,
            headers=headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                content = response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="ignore")
            raise SyncError(
                f"Supabase retornou erro {error.code}: {detail or error.reason}"
            ) from error
        except urllib.error.URLError as error:
            raise SyncError(f"Falha de conexão com Supabase: {error.reason}") from error

        if not content:
            return []
        try:
            return json.loads(content)
        except json.JSONDecodeError as error:
            raise SyncError("Resposta inválida do Supabase.") from error
