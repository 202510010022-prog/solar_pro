from dataclasses import dataclass


@dataclass
class Client:
    id: int
    name: str
    document: str = ""
    phone: str = ""
    email: str = ""
    city: str = ""
    state: str = ""


@dataclass
class Project:
    id: int
    client_id: int
    project_date: str
    status: str
    client_name: str = ""
    monthly_consumption: float = 0
    sun_hours: float = 0
    monthly_consumptions: str = "[]"
    monthly_hsp: str = "[]"
    monthly_generations: str = "[]"
    monthly_balances: str = "[]"
    generation_extra_percent: float = 0
    average_consumption: float = 0
    average_hsp: float = 0
    annual_consumption: float = 0
    annual_generation: float = 0
    performance_ratio: float = 0
    module_power: float = 0
    energy_tariff: float = 0
    project_value: float = 0
    labor_cost: float = 0
    module_unit_cost: float = 0
    inverter_cost: float = 0
    support_cost: float = 0
    extra_materials: str = "[]"
    system_power: float = 0
    module_count: int = 0
    monthly_generation: float = 0
    monthly_savings: float = 0
    payback_years: float = 0
    down_payment: float = 0
    payment_type: str = ""
    discount: float = 0
    installments_count: int = 0
    installment_value: float = 0
    first_due_date: str = ""
    financial_notes: str = ""
    monthly_interest_rate: float = 0
    term_months: int = 0
    financed_amount: float = 0
    monthly_payment: float = 0
    total_paid: float = 0
    total_interest: float = 0
    history: str = "[]"
