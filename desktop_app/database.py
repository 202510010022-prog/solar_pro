import json
import shutil
import sqlite3
import sys
from datetime import datetime
from pathlib import Path

APP_DIR = Path(__file__).resolve().parent

def get_database_path():

    if getattr(sys, "frozen", False):

        return Path(sys.executable).resolve().parent / "solar_manager_desktop.db"

    return APP_DIR / "solar_manager_desktop.db"

DB_PATH = get_database_path()

def get_connection():

    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row

    return connection

def initialize_database():

    with get_connection() as connection:

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS clients (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                document TEXT NOT NULL DEFAULT '',
                phone TEXT NOT NULL,
                email TEXT NOT NULL,
                zip_code TEXT NOT NULL DEFAULT '',
                street TEXT NOT NULL DEFAULT '',
                address_number TEXT NOT NULL DEFAULT '',
                neighborhood TEXT NOT NULL DEFAULT '',
                city TEXT NOT NULL,
                state TEXT NOT NULL,
                address_complement TEXT NOT NULL DEFAULT ''
            )
            """
        )

        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS budgets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_id INTEGER NOT NULL,
                budget_date TEXT NOT NULL,
                status TEXT NOT NULL,
                monthly_consumption REAL NOT NULL,
                sun_hours REAL NOT NULL,
                monthly_consumptions TEXT NOT NULL DEFAULT '[]',
                monthly_hsp TEXT NOT NULL DEFAULT '[]',
                monthly_generations TEXT NOT NULL DEFAULT '[]',
                monthly_balances TEXT NOT NULL DEFAULT '[]',
                generation_extra_percent REAL NOT NULL DEFAULT 0,
                average_consumption REAL NOT NULL DEFAULT 0,
                average_hsp REAL NOT NULL DEFAULT 0,
                annual_consumption REAL NOT NULL DEFAULT 0,
                annual_generation REAL NOT NULL DEFAULT 0,
                performance_ratio REAL NOT NULL,
                module_power REAL NOT NULL,
                energy_tariff REAL NOT NULL,
                investment REAL NOT NULL,
                system_power REAL NOT NULL,
                module_count INTEGER NOT NULL,
                monthly_generation REAL NOT NULL,
                monthly_savings REAL NOT NULL,
                payback_years REAL NOT NULL,
                FOREIGN KEY (client_id) REFERENCES clients (id)
            )
            """
        )

        connection.commit()

        _ensure_clients_document_column(connection)
        _ensure_budget_monthly_columns(connection)
        _ensure_budget_financing_columns(connection)
        _ensure_projects_table(connection)
        _ensure_project_financial_plan_columns(connection)
        _ensure_project_indexes(connection)
        _ensure_project_documents_table(connection)
        _ensure_project_payments_table(connection)

def _ensure_clients_document_column(connection):

    columns = connection.execute(
        "PRAGMA table_info(clients)"
    ).fetchall()

    column_names = {
        column["name"]
        for column in columns
    }

    migrations = {
        "document": "TEXT NOT NULL DEFAULT ''",
        "zip_code": "TEXT NOT NULL DEFAULT ''",
        "street": "TEXT NOT NULL DEFAULT ''",
        "address_number": "TEXT NOT NULL DEFAULT ''",
        "neighborhood": "TEXT NOT NULL DEFAULT ''",
        "address_complement": "TEXT NOT NULL DEFAULT ''",
    }

    for column, definition in migrations.items():

        if column not in column_names:

            connection.execute(
                f"ALTER TABLE clients ADD COLUMN {column} {definition}"
            )

    connection.commit()

def _ensure_budget_monthly_columns(connection):

    columns = connection.execute(
        "PRAGMA table_info(budgets)"
    ).fetchall()

    column_names = {
        column["name"]
        for column in columns
    }

    migrations = {
        "monthly_consumptions": "TEXT NOT NULL DEFAULT '[]'",
        "monthly_hsp": "TEXT NOT NULL DEFAULT '[]'",
        "monthly_generations": "TEXT NOT NULL DEFAULT '[]'",
        "monthly_balances": "TEXT NOT NULL DEFAULT '[]'",
        "generation_extra_percent": "REAL NOT NULL DEFAULT 0",
        "average_consumption": "REAL NOT NULL DEFAULT 0",
        "average_hsp": "REAL NOT NULL DEFAULT 0",
        "annual_consumption": "REAL NOT NULL DEFAULT 0",
        "annual_generation": "REAL NOT NULL DEFAULT 0",
    }

    for column, definition in migrations.items():

        if column not in column_names:

            connection.execute(
                f"ALTER TABLE budgets ADD COLUMN {column} {definition}"
            )

    connection.commit()

def _ensure_budget_financing_columns(connection):

    columns = connection.execute(
        "PRAGMA table_info(budgets)"
    ).fetchall()

    column_names = {
        column["name"]
        for column in columns
    }

    migrations = {
        "down_payment": "REAL NOT NULL DEFAULT 0",
        "monthly_interest_rate": "REAL NOT NULL DEFAULT 0",
        "term_months": "INTEGER NOT NULL DEFAULT 0",
        "financed_amount": "REAL NOT NULL DEFAULT 0",
        "monthly_payment": "REAL NOT NULL DEFAULT 0",
        "total_paid": "REAL NOT NULL DEFAULT 0",
        "total_interest": "REAL NOT NULL DEFAULT 0",
    }

    for column, definition in migrations.items():

        if column not in column_names:

            connection.execute(
                f"ALTER TABLE budgets ADD COLUMN {column} {definition}"
            )

    connection.commit()

def _project_columns():

    return [
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
        "energy_tariff",
        "project_value",
        "labor_cost",
        "module_unit_cost",
        "inverter_cost",
        "support_cost",
        "extra_materials",
        "system_power",
        "module_count",
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

def _ensure_projects_table(connection):

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id INTEGER NOT NULL,
            project_date TEXT NOT NULL,
            status TEXT NOT NULL,
            monthly_consumption REAL NOT NULL DEFAULT 0,
            sun_hours REAL NOT NULL DEFAULT 0,
            monthly_consumptions TEXT NOT NULL DEFAULT '[]',
            monthly_hsp TEXT NOT NULL DEFAULT '[]',
            monthly_generations TEXT NOT NULL DEFAULT '[]',
            monthly_balances TEXT NOT NULL DEFAULT '[]',
            generation_extra_percent REAL NOT NULL DEFAULT 0,
            average_consumption REAL NOT NULL DEFAULT 0,
            average_hsp REAL NOT NULL DEFAULT 0,
            annual_consumption REAL NOT NULL DEFAULT 0,
            annual_generation REAL NOT NULL DEFAULT 0,
            performance_ratio REAL NOT NULL DEFAULT 0,
            module_power REAL NOT NULL DEFAULT 0,
            energy_tariff REAL NOT NULL DEFAULT 0,
            project_value REAL NOT NULL DEFAULT 0,
            labor_cost REAL NOT NULL DEFAULT 0,
            module_unit_cost REAL NOT NULL DEFAULT 0,
            inverter_cost REAL NOT NULL DEFAULT 0,
            support_cost REAL NOT NULL DEFAULT 0,
            extra_materials TEXT NOT NULL DEFAULT '[]',
            system_power REAL NOT NULL DEFAULT 0,
            module_count INTEGER NOT NULL DEFAULT 0,
            monthly_generation REAL NOT NULL DEFAULT 0,
            monthly_savings REAL NOT NULL DEFAULT 0,
            payback_years REAL NOT NULL DEFAULT 0,
            down_payment REAL NOT NULL DEFAULT 0,
            payment_type TEXT NOT NULL DEFAULT '',
            discount REAL NOT NULL DEFAULT 0,
            installments_count INTEGER NOT NULL DEFAULT 0,
            installment_value REAL NOT NULL DEFAULT 0,
            first_due_date TEXT,
            financial_notes TEXT NOT NULL DEFAULT '',
            monthly_interest_rate REAL NOT NULL DEFAULT 0,
            term_months INTEGER NOT NULL DEFAULT 0,
            financed_amount REAL NOT NULL DEFAULT 0,
            monthly_payment REAL NOT NULL DEFAULT 0,
            total_paid REAL NOT NULL DEFAULT 0,
            total_interest REAL NOT NULL DEFAULT 0,
            history TEXT NOT NULL DEFAULT '[]',
            FOREIGN KEY (client_id) REFERENCES clients (id)
        )
        """
    )

    project_count = connection.execute(
        "SELECT COUNT(*) AS total FROM projects"
    ).fetchone()["total"]
    budget_count = connection.execute(
        "SELECT COUNT(*) AS total FROM budgets"
    ).fetchone()["total"]

    if project_count == 0 and budget_count > 0:
        connection.execute(
            """
            INSERT INTO projects (
                id,
                client_id,
                project_date,
                status,
                monthly_consumption,
                sun_hours,
                monthly_consumptions,
                monthly_hsp,
                monthly_generations,
                monthly_balances,
                generation_extra_percent,
                average_consumption,
                average_hsp,
                annual_consumption,
                annual_generation,
                performance_ratio,
                module_power,
                energy_tariff,
                project_value,
                system_power,
                module_count,
                monthly_generation,
                monthly_savings,
                payback_years,
                down_payment,
                monthly_interest_rate,
                term_months,
                financed_amount,
                monthly_payment,
                total_paid,
                total_interest,
                history
            )
            SELECT
                id,
                client_id,
                budget_date,
                status,
                monthly_consumption,
                sun_hours,
                monthly_consumptions,
                monthly_hsp,
                monthly_generations,
                monthly_balances,
                generation_extra_percent,
                average_consumption,
                average_hsp,
                annual_consumption,
                annual_generation,
                performance_ratio,
                module_power,
                energy_tariff,
                investment,
                system_power,
                module_count,
                monthly_generation,
                monthly_savings,
                payback_years,
                down_payment,
                monthly_interest_rate,
                term_months,
                financed_amount,
                monthly_payment,
                total_paid,
                total_interest,
                '[]'
            FROM budgets
            """
        )

    connection.commit()


def _ensure_project_financial_plan_columns(connection):

    columns = connection.execute(
        "PRAGMA table_info(projects)"
    ).fetchall()
    column_names = {
        column["name"]
        for column in columns
    }
    migrations = {
        "labor_cost": "REAL NOT NULL DEFAULT 0",
        "module_unit_cost": "REAL NOT NULL DEFAULT 0",
        "inverter_cost": "REAL NOT NULL DEFAULT 0",
        "support_cost": "REAL NOT NULL DEFAULT 0",
        "extra_materials": "TEXT NOT NULL DEFAULT '[]'",
        "payment_type": "TEXT NOT NULL DEFAULT ''",
        "discount": "REAL NOT NULL DEFAULT 0",
        "installments_count": "INTEGER NOT NULL DEFAULT 0",
        "installment_value": "REAL NOT NULL DEFAULT 0",
        "first_due_date": "TEXT",
        "financial_notes": "TEXT NOT NULL DEFAULT ''",
    }

    for column, definition in migrations.items():

        if column not in column_names:

            connection.execute(
                f"ALTER TABLE projects ADD COLUMN {column} {definition}"
            )

    connection.commit()


def _ensure_project_indexes(connection):

    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status)"
    )
    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_projects_date ON projects(project_date)"
    )
    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_projects_client_id ON projects(client_id)"
    )

    connection.commit()

def _ensure_project_documents_table(connection):

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS project_documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            category TEXT NOT NULL,
            original_name TEXT NOT NULL,
            stored_path TEXT NOT NULL,
            file_size INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (project_id) REFERENCES projects (id)
        )
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_project_documents_project_id
        ON project_documents(project_id)
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_project_documents_category
        ON project_documents(category)
        """
    )

    connection.commit()


def _ensure_project_payments_table(connection):

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS project_payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            amount REAL NOT NULL DEFAULT 0,
            payment_type TEXT NOT NULL DEFAULT '',
            paid_at TEXT,
            status TEXT NOT NULL DEFAULT 'paid',
            notes TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (project_id) REFERENCES projects (id)
        )
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_project_payments_project_id
        ON project_payments(project_id)
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_project_payments_status
        ON project_payments(status)
        """
    )

    connection.commit()


def create_client(name, document, phone, email, city, state):

    with get_connection() as connection:

        cursor = connection.execute(
            """
            INSERT INTO clients (name, document, phone, email, city, state)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (name, document, phone, email, city, state),
        )

        connection.commit()

        return cursor.lastrowid

def update_client(client_id, name, document, phone, email, city, state):

    with get_connection() as connection:

        connection.execute(
            """
            UPDATE clients
            SET
                name = ?,
                document = ?,
                phone = ?,
                email = ?,
                city = ?,
                state = ?
            WHERE id = ?
            """,
            (name, document, phone, email, city, state, client_id),
        )

        connection.commit()

def delete_client(client_id):

    with get_connection() as connection:

        connection.execute(
            "DELETE FROM projects WHERE client_id = ?",
            (client_id,),
        )
        connection.execute(
            "DELETE FROM budgets WHERE client_id = ?",
            (client_id,),
        )
        connection.execute(
            "DELETE FROM clients WHERE id = ?",
            (client_id,),
        )

        connection.commit()

def list_clients():

    with get_connection() as connection:

        return connection.execute(
            """
            SELECT
                id,
                name,
                document,
                phone,
                email,
                zip_code,
                street,
                address_number,
                neighborhood,
                city,
                state,
                address_complement
            FROM clients
            ORDER BY name
            """
        ).fetchall()

def export_clients():

    return [
        dict(row)
        for row in list_clients()
    ]

def export_projects():

    return [
        dict(row)
        for row in list_projects()
    ]

def export_project_documents():

    with get_connection() as connection:

        return [
            dict(row)
            for row in connection.execute(
                """
                SELECT
                    id,
                    project_id,
                    category,
                    original_name,
                    stored_path,
                    file_size,
                    created_at
                FROM project_documents
                ORDER BY id
                """
            ).fetchall()
        ]


def export_project_payments():

    return [
        dict(row)
        for row in list_project_payments(include_canceled=True)
    ]


def export_budgets():

    return export_projects()

def backup_database(prefix="backup"):

    if not DB_PATH.exists():

        return None

    backup_dir = DB_PATH.parent / "backups"
    backup_dir.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = backup_dir / f"{prefix}_{timestamp}.db"
    shutil.copy2(DB_PATH, backup_path)

    return backup_path

def replace_database_data(
    clients,
    projects,
    project_documents=None,
    project_payments=None,
):

    backup_database("before_sync")

    client_columns = [
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
    project_columns = _project_columns()
    project_document_columns = [
        "id",
        "project_id",
        "category",
        "original_name",
        "stored_path",
        "file_size",
        "created_at",
    ]
    project_payment_columns = [
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
    legacy_budget_columns = [
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
    ]

    with get_connection() as connection:

        if project_documents is not None:
            connection.execute("DELETE FROM project_documents")
        if project_payments is not None:
            connection.execute("DELETE FROM project_payments")
        connection.execute("DELETE FROM projects")
        connection.execute("DELETE FROM budgets")
        connection.execute("DELETE FROM clients")

        for client in clients:

            values = [
                client.get(column, "")
                for column in client_columns
            ]
            connection.execute(
                """
                INSERT OR REPLACE INTO clients (
                    id,
                    name,
                    document,
                    phone,
                    email,
                    zip_code,
                    street,
                    address_number,
                    neighborhood,
                    city,
                    state,
                    address_complement
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                values,
            )

        for project in projects:

            values = [
                _project_value(project, column)
                for column in project_columns
            ]
            connection.execute(
                """
                INSERT OR REPLACE INTO projects (
                    id,
                    client_id,
                    project_date,
                    status,
                    monthly_consumption,
                    sun_hours,
                    monthly_consumptions,
                    monthly_hsp,
                    monthly_generations,
                    monthly_balances,
                    generation_extra_percent,
                    average_consumption,
                    average_hsp,
                    annual_consumption,
                    annual_generation,
                    performance_ratio,
                    module_power,
                    energy_tariff,
                    project_value,
                    labor_cost,
                    module_unit_cost,
                    inverter_cost,
                    support_cost,
                    extra_materials,
                    system_power,
                    module_count,
                    monthly_generation,
                    monthly_savings,
                    payback_years,
                    down_payment,
                    payment_type,
                    discount,
                    installments_count,
                    installment_value,
                    first_due_date,
                    financial_notes,
                    monthly_interest_rate,
                    term_months,
                    financed_amount,
                    monthly_payment,
                    total_paid,
                    total_interest,
                    history
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                values,
            )

            legacy_values = [
                project.get(column, _default_budget_value(column))
                for column in legacy_budget_columns
            ]
            legacy_values[2] = project.get("project_date", legacy_values[2])
            legacy_values[18] = project.get("project_value", legacy_values[18])
            connection.execute(
                """
                INSERT OR REPLACE INTO budgets (
                    id,
                    client_id,
                    budget_date,
                    status,
                    monthly_consumption,
                    sun_hours,
                    monthly_consumptions,
                    monthly_hsp,
                    monthly_generations,
                    monthly_balances,
                    generation_extra_percent,
                    average_consumption,
                    average_hsp,
                    annual_consumption,
                    annual_generation,
                    performance_ratio,
                    module_power,
                    energy_tariff,
                    investment,
                    system_power,
                    module_count,
                    monthly_generation,
                    monthly_savings,
                    payback_years,
                    down_payment,
                    monthly_interest_rate,
                    term_months,
                    financed_amount,
                    monthly_payment,
                    total_paid,
                    total_interest
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                legacy_values,
            )

        if project_documents is not None:

            for document in project_documents:

                values = [
                    document.get(column, "" if column != "file_size" else 0)
                    for column in project_document_columns
                ]
                connection.execute(
                    """
                    INSERT OR REPLACE INTO project_documents (
                        id,
                        project_id,
                        category,
                        original_name,
                        stored_path,
                        file_size,
                        created_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    values,
                )

        if project_payments is not None:

            for payment in project_payments:

                values = [
                    payment.get(column, "" if column in {"payment_type", "status", "notes"} else 0)
                    for column in project_payment_columns
                ]
                connection.execute(
                    """
                    INSERT OR REPLACE INTO project_payments (
                        id,
                        project_id,
                        amount,
                        payment_type,
                        paid_at,
                        status,
                        notes,
                        created_at,
                        updated_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    values,
                )

        connection.commit()

def _project_value(project, column):

    legacy_map = {
        "project_date": "budget_date",
        "project_value": "investment",
    }
    if column in project:
        return project.get(column, _default_budget_value(column))

    legacy_column = legacy_map.get(column)
    if legacy_column:
        return project.get(legacy_column, _default_budget_value(column))

    return _default_budget_value(column)

def _default_budget_value(column):

    if column in {
        "monthly_consumptions",
        "monthly_hsp",
        "monthly_generations",
        "monthly_balances",
        "extra_materials",
    }:

        return "[]"

    if column == "status":

        return "Em negociação"

    if column in {"budget_date", "project_date"}:

        return datetime.now().strftime("%d/%m/%Y")

    if column == "history":

        return "[]"

    if column in {"payment_type", "financial_notes", "first_due_date"}:

        return ""

    return 0

def _history_entry(action, detail):

    return {
        "action": action,
        "detail": detail,
        "created_at": datetime.now().isoformat(timespec="seconds"),
    }

def _append_project_history(connection, project_id, action, detail):

    row = connection.execute(
        "SELECT history FROM projects WHERE id = ?",
        (project_id,),
    ).fetchone()

    if row is None:

        return

    try:

        history = json.loads(row["history"] or "[]")

    except json.JSONDecodeError:

        history = []

    history.append(_history_entry(action, detail))

    connection.execute(
        """
        UPDATE projects
        SET history = ?
        WHERE id = ?
        """,
        (
            json.dumps(history, ensure_ascii=False),
            project_id,
        ),
    )

def create_project(client_id, project_date, status, inputs, results):

    with get_connection() as connection:

        history = json.dumps(
            [
                _history_entry(
                    "created",
                    "Projeto criado a partir do dimensionamento.",
                )
            ],
            ensure_ascii=False,
        )
        cursor = connection.execute(
            """
            INSERT INTO projects (
                client_id,
                project_date,
                status,
                monthly_consumption,
                sun_hours,
                monthly_consumptions,
                monthly_hsp,
                monthly_generations,
                monthly_balances,
                generation_extra_percent,
                average_consumption,
                average_hsp,
                annual_consumption,
                annual_generation,
                performance_ratio,
                module_power,
                energy_tariff,
                project_value,
                system_power,
                module_count,
                monthly_generation,
                monthly_savings,
                payback_years,
                history
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                client_id,
                project_date,
                status,
                results["average_consumption"],
                results["average_hsp"],
                json.dumps(inputs["monthly_consumptions"]),
                json.dumps(inputs["monthly_hsp"]),
                json.dumps(results["monthly_generations"]),
                json.dumps(results["monthly_balances"]),
                inputs["generation_extra_percent"],
                results["average_consumption"],
                results["average_hsp"],
                results["annual_consumption"],
                results["annual_generation"],
                inputs["performance_ratio"],
                inputs["module_power"],
                inputs["energy_tariff"],
                0,
                results["system_power"],
                results["module_count"],
                results["monthly_generation"],
                results["monthly_savings"],
                results["payback_years"],
                history,
            ),
        )

        connection.commit()

        return cursor.lastrowid


def create_budget(client_id, budget_date, status, inputs, results):

    return create_project(client_id, budget_date, status, inputs, results)


def list_projects():

    with get_connection() as connection:

        return connection.execute(
            """
            SELECT
                projects.id,
                projects.client_id,
                projects.project_date,
                projects.project_date AS budget_date,
                projects.status,
                projects.monthly_consumption,
                projects.average_consumption,
                projects.average_hsp,
                projects.monthly_consumptions,
                projects.monthly_hsp,
                projects.monthly_generations,
                projects.monthly_balances,
                projects.annual_consumption,
                projects.annual_generation,
                projects.generation_extra_percent,
                projects.performance_ratio,
                projects.module_power,
                projects.energy_tariff,
                projects.project_value,
                projects.project_value AS investment,
                projects.labor_cost,
                projects.module_unit_cost,
                projects.inverter_cost,
                projects.support_cost,
                projects.extra_materials,
                projects.system_power,
                projects.module_count,
                projects.monthly_generation,
                projects.monthly_savings,
                projects.payback_years,
                projects.down_payment,
                projects.payment_type,
                projects.discount,
                projects.installments_count,
                projects.installment_value,
                projects.first_due_date,
                projects.financial_notes,
                projects.monthly_interest_rate,
                projects.term_months,
                projects.financed_amount,
                projects.monthly_payment,
                projects.total_paid,
                projects.total_interest,
                projects.history,
                clients.name AS client_name,
                clients.document AS client_document,
                clients.phone AS client_phone,
                clients.email AS client_email,
                clients.city AS client_city,
                clients.state AS client_state
            FROM projects
            JOIN clients ON clients.id = projects.client_id
            ORDER BY projects.project_date DESC, projects.id DESC
            """
        ).fetchall()


def list_budgets():

    return list_projects()


def update_project_status(project_id, status):

    with get_connection() as connection:

        connection.execute(
            """
            UPDATE projects
            SET status = ?
            WHERE id = ?
            """,
            (status, project_id),
        )
        _append_project_history(
            connection,
            project_id,
            "status_updated",
            f"Status alterado para {status}.",
        )

        connection.commit()


def update_budget_status(budget_id, status):

    update_project_status(budget_id, status)


def delete_project(project_id):

    with get_connection() as connection:

        connection.execute(
            "DELETE FROM project_payments WHERE project_id = ?",
            (project_id,),
        )
        connection.execute(
            "DELETE FROM project_documents WHERE project_id = ?",
            (project_id,),
        )
        connection.execute(
            "DELETE FROM projects WHERE id = ?",
            (project_id,),
        )
        connection.execute(
            "DELETE FROM budgets WHERE id = ?",
            (project_id,),
        )

        connection.commit()


def delete_budget(budget_id):

    delete_project(budget_id)

def create_project_document(
    project_id,
    category,
    original_name,
    stored_path,
    file_size,
):

    with get_connection() as connection:

        cursor = connection.execute(
            """
            INSERT INTO project_documents (
                project_id,
                category,
                original_name,
                stored_path,
                file_size,
                created_at
            )
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                project_id,
                category,
                original_name,
                stored_path,
                file_size,
                datetime.now().isoformat(timespec="seconds"),
            ),
        )

        connection.commit()

        return cursor.lastrowid

def list_project_documents(project_id, category=None):

    with get_connection() as connection:

        if category and category != "Todos":

            return connection.execute(
                """
                SELECT *
                FROM project_documents
                WHERE project_id = ? AND category = ?
                ORDER BY created_at DESC, id DESC
                """,
                (project_id, category),
            ).fetchall()

        return connection.execute(
            """
            SELECT *
            FROM project_documents
            WHERE project_id = ?
            ORDER BY created_at DESC, id DESC
            """,
            (project_id,),
        ).fetchall()

def get_project_document(document_id):

    with get_connection() as connection:

        return connection.execute(
            """
            SELECT *
            FROM project_documents
            WHERE id = ?
            """,
            (document_id,),
        ).fetchone()

def delete_project_document(document_id):

    with get_connection() as connection:

        connection.execute(
            "DELETE FROM project_documents WHERE id = ?",
            (document_id,),
        )

        connection.commit()


def update_project_financing(
    project_id,
    project_value,
    down_payment,
    monthly_interest_rate,
    term_months,
    results,
):

    with get_connection() as connection:

        connection.execute(
            """
            UPDATE projects
            SET
                project_value = ?,
                down_payment = ?,
                monthly_interest_rate = ?,
                term_months = ?,
                financed_amount = ?,
                monthly_payment = ?,
                total_paid = ?,
                total_interest = ?,
                payback_years = ?
            WHERE id = ?
            """,
            (
                project_value,
                down_payment,
                monthly_interest_rate,
                term_months,
                results["financed_amount"],
                results["monthly_payment"],
                results["total_paid"],
                results["total_interest"],
                results["payback_years"],
                project_id,
            ),
        )
        _append_project_history(
            connection,
            project_id,
            "financing_updated",
            "Simulação financeira atualizada.",
        )

        connection.commit()


def update_project_financial_plan(
    project_id,
    payment_type,
    down_payment,
    discount,
    installments_count,
    installment_value,
    first_due_date,
    notes,
):

    with get_connection() as connection:

        connection.execute(
            """
            UPDATE projects
            SET
                payment_type = ?,
                down_payment = ?,
                discount = ?,
                installments_count = ?,
                installment_value = ?,
                first_due_date = ?,
                financial_notes = ?
            WHERE id = ?
            """,
            (
                payment_type,
                down_payment,
                discount,
                installments_count,
                installment_value,
                first_due_date,
                notes,
                project_id,
            ),
        )
        _append_project_history(
            connection,
            project_id,
            "financial_plan_updated",
            "Plano financeiro atualizado.",
        )

        connection.commit()


def create_project_payment(
    project_id,
    amount,
    payment_type,
    paid_at,
    notes="",
):

    now = datetime.now().isoformat(timespec="seconds")

    with get_connection() as connection:

        cursor = connection.execute(
            """
            INSERT INTO project_payments (
                project_id,
                amount,
                payment_type,
                paid_at,
                status,
                notes,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, ?, 'paid', ?, ?, ?)
            """,
            (
                project_id,
                amount,
                payment_type,
                paid_at,
                notes,
                now,
                now,
            ),
        )
        _append_project_history(
            connection,
            project_id,
            "payment_created",
            f"Pagamento registrado: R$ {amount:.2f}.",
        )

        connection.commit()
        return cursor.lastrowid


def cancel_project_payment(payment_id):

    now = datetime.now().isoformat(timespec="seconds")

    with get_connection() as connection:

        row = connection.execute(
            "SELECT project_id FROM project_payments WHERE id = ?",
            (payment_id,),
        ).fetchone()
        connection.execute(
            """
            UPDATE project_payments
            SET status = 'canceled', updated_at = ?
            WHERE id = ?
            """,
            (now, payment_id),
        )
        if row:
            _append_project_history(
                connection,
                row["project_id"],
                "payment_canceled",
                "Pagamento cancelado.",
            )

        connection.commit()


def list_project_payments(project_id=None, include_canceled=False):

    where = []
    params = []
    if project_id is not None:
        where.append("project_id = ?")
        params.append(project_id)
    if not include_canceled:
        where.append("status != 'canceled'")

    query = """
        SELECT
            id,
            project_id,
            amount,
            payment_type,
            paid_at,
            status,
            notes,
            created_at,
            updated_at
        FROM project_payments
    """
    if where:
        query += " WHERE " + " AND ".join(where)
    query += " ORDER BY paid_at DESC, id DESC"

    with get_connection() as connection:
        return connection.execute(query, params).fetchall()


def get_project_payment_totals():

    with get_connection() as connection:

        return connection.execute(
            """
            SELECT
                COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0) AS received,
                COALESCE(SUM(CASE WHEN status = 'paid'
                    AND strftime('%Y-%m', paid_at) = strftime('%Y-%m', 'now', 'localtime')
                    THEN amount ELSE 0 END), 0) AS received_month
            FROM project_payments
            """
        ).fetchone()


def update_budget_financing(
    budget_id,
    project_value,
    down_payment,
    monthly_interest_rate,
    term_months,
    results,
):

    update_project_financing(
        budget_id,
        project_value,
        down_payment,
        monthly_interest_rate,
        term_months,
        results,
    )

def get_dashboard_totals():

    with get_connection() as connection:

        totals = connection.execute(
            """
            SELECT
                COUNT(*) AS budget_count,
                SUM(CASE WHEN status = 'Em negociação' THEN 1 ELSE 0 END) AS negotiating,
                SUM(CASE WHEN status = 'Fechado' THEN 1 ELSE 0 END) AS closed,
                SUM(CASE WHEN status = 'Concluído' THEN 1 ELSE 0 END) AS completed,
                SUM(CASE WHEN status = 'Não aprovado' THEN 1 ELSE 0 END) AS not_approved,
                SUM(CASE WHEN status IN ('Em negociação', 'Fechado') THEN 1 ELSE 0 END) AS active_projects,
                COALESCE(SUM(system_power), 0) AS total_power,
                COALESCE(SUM(CASE WHEN status IN ('Fechado', 'Concluído') THEN system_power ELSE 0 END), 0) AS sold_power,
                COALESCE(SUM(monthly_savings), 0) AS total_savings,
                COALESCE(SUM(project_value), 0) AS total_investment,
                COALESCE(SUM(CASE WHEN status != 'Não aprovado' THEN project_value ELSE 0 END), 0) AS forecast_revenue,
                COALESCE(SUM(CASE WHEN status IN ('Fechado', 'Concluído') THEN project_value ELSE 0 END), 0) AS closed_revenue,
                COALESCE(AVG(CASE WHEN payback_years > 0 THEN payback_years END), 0) AS average_payback,
                COALESCE(SUM(CASE WHEN status = 'Fechado' THEN project_value ELSE 0 END), 0) AS closed_investment,
                COALESCE(SUM(CASE WHEN status = 'Concluído' THEN project_value ELSE 0 END), 0) AS completed_investment
            FROM projects
            """
        ).fetchone()

    budget_count = totals["budget_count"] or 0
    not_approved = totals["not_approved"] or 0
    converted_count = (totals["closed"] or 0) + (totals["completed"] or 0)
    convertible_count = max(budget_count - not_approved, 0)
    conversion_rate = (
        (converted_count / convertible_count) * 100
        if convertible_count
        else 0
    )

    return {
        "budget_count": budget_count,
        "total_power": totals["total_power"] or 0,
        "sold_power": totals["sold_power"] or 0,
        "total_savings": totals["total_savings"] or 0,
        "total_investment": totals["total_investment"] or 0,
        "forecast_revenue": totals["forecast_revenue"] or 0,
        "closed_revenue": totals["closed_revenue"] or 0,
        "conversion_rate": conversion_rate,
        "active_projects": totals["active_projects"] or 0,
        "average_payback": totals["average_payback"] or 0,
        "closed_investment": totals["closed_investment"] or 0,
        "completed_investment": totals["completed_investment"] or 0,
        "negotiating": totals["negotiating"] or 0,
        "closed": totals["closed"] or 0,
        "completed": totals["completed"] or 0,
        "not_approved": not_approved,
    }
