from desktop_app.database import (
    cancel_project_payment,
    create_project_payment,
    create_project,
    delete_project,
    list_project_payments,
    list_projects,
    update_project_financial_plan,
    update_project_financing,
    update_project_status,
)
from desktop_app.models import Project


class ProjectService:
    def create_dimensioning(self, client_id, project_date, status, inputs, results):
        return create_project(client_id, project_date, status, inputs, results)

    def list(self):
        return list_projects()

    def list_models(self):
        return [
            self._to_model(project)
            for project in self.list()
        ]

    def update_status(self, project_id, status):
        update_project_status(project_id, status)

    def update_financing(
        self,
        project_id,
        project_value,
        down_payment,
        monthly_interest_rate,
        term_months,
        results,
    ):
        update_project_financing(
            project_id,
            project_value,
            down_payment,
            monthly_interest_rate,
            term_months,
            results,
        )

    def update_financial_plan(
        self,
        project_id,
        payment_type,
        down_payment,
        discount,
        installments_count,
        installment_value,
        first_due_date,
        notes,
    ):
        update_project_financial_plan(
            project_id,
            payment_type,
            down_payment,
            discount,
            installments_count,
            installment_value,
            first_due_date,
            notes,
        )

    def list_payments(self, project_id=None, include_canceled=False):
        return list_project_payments(project_id, include_canceled)

    def create_payment(self, project_id, amount, payment_type, paid_at, notes=""):
        return create_project_payment(
            project_id,
            amount,
            payment_type,
            paid_at,
            notes,
        )

    def cancel_payment(self, payment_id):
        cancel_project_payment(payment_id)

    def delete(self, project_id):
        delete_project(project_id)

    def _to_model(self, row):
        data = dict(row)
        return Project(
            id=data["id"],
            client_id=data["client_id"],
            project_date=data.get("project_date") or data.get("budget_date", ""),
            status=data["status"],
            client_name=data.get("client_name", ""),
            monthly_consumption=data.get("monthly_consumption", 0),
            sun_hours=data.get("sun_hours", 0),
            monthly_consumptions=data.get("monthly_consumptions", "[]"),
            monthly_hsp=data.get("monthly_hsp", "[]"),
            monthly_generations=data.get("monthly_generations", "[]"),
            monthly_balances=data.get("monthly_balances", "[]"),
            generation_extra_percent=data.get("generation_extra_percent", 0),
            average_consumption=data.get("average_consumption", 0),
            average_hsp=data.get("average_hsp", 0),
            annual_consumption=data.get("annual_consumption", 0),
            annual_generation=data.get("annual_generation", 0),
            performance_ratio=data.get("performance_ratio", 0),
            module_power=data.get("module_power", 0),
            energy_tariff=data.get("energy_tariff", 0),
            project_value=data.get("project_value", data.get("investment", 0)),
            labor_cost=data.get("labor_cost", 0),
            module_unit_cost=data.get("module_unit_cost", 0),
            inverter_cost=data.get("inverter_cost", 0),
            support_cost=data.get("support_cost", 0),
            extra_materials=data.get("extra_materials", "[]"),
            system_power=data.get("system_power", 0),
            module_count=data.get("module_count", 0),
            monthly_generation=data.get("monthly_generation", 0),
            monthly_savings=data.get("monthly_savings", 0),
            payback_years=data.get("payback_years", 0),
            down_payment=data.get("down_payment", 0),
            payment_type=data.get("payment_type", ""),
            discount=data.get("discount", 0),
            installments_count=data.get("installments_count", 0),
            installment_value=data.get("installment_value", 0),
            first_due_date=data.get("first_due_date", ""),
            financial_notes=data.get("financial_notes", ""),
            monthly_interest_rate=data.get("monthly_interest_rate", 0),
            term_months=data.get("term_months", 0),
            financed_amount=data.get("financed_amount", 0),
            monthly_payment=data.get("monthly_payment", 0),
            total_paid=data.get("total_paid", 0),
            total_interest=data.get("total_interest", 0),
            history=data.get("history", "[]"),
        )
