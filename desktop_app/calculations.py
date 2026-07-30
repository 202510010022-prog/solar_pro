from math import ceil

MONTHS = [
    "Jan",
    "Fev",
    "Mar",
    "Abr",
    "Mai",
    "Jun",
    "Jul",
    "Ago",
    "Set",
    "Out",
    "Nov",
    "Dez",
]

def calculate_sizing(
    monthly_consumptions,
    monthly_hsp,
    performance_ratio,
    module_power,
    energy_tariff,
    generation_extra_percent,
):

    annual_consumption = sum(monthly_consumptions)

    average_consumption = annual_consumption / 12

    average_hsp = sum(monthly_hsp) / 12

    target_annual_generation = annual_consumption * (
        1 + (generation_extra_percent / 100)
    )

    annual_generation_per_kwp = sum(
        hsp * 30 * performance_ratio
        for hsp in monthly_hsp
    )

    system_power = target_annual_generation / annual_generation_per_kwp

    module_count = ceil(
        (system_power * 1000) / module_power
    )

    monthly_generations = [
        system_power * hsp * 30 * performance_ratio
        for hsp in monthly_hsp
    ]

    monthly_balances = [
        generation - consumption
        for generation, consumption in zip(
            monthly_generations,
            monthly_consumptions
        )
    ]

    annual_generation = sum(monthly_generations)

    average_monthly_generation = annual_generation / 12

    monthly_savings = average_monthly_generation * energy_tariff

    return {
        "system_power": system_power,
        "module_count": module_count,
        "monthly_generation": average_monthly_generation,
        "monthly_generations": monthly_generations,
        "monthly_balances": monthly_balances,
        "monthly_savings": monthly_savings,
        "payback_years": 0,
        "average_consumption": average_consumption,
        "average_hsp": average_hsp,
        "annual_consumption": annual_consumption,
        "annual_generation": annual_generation,
        "generation_extra_percent": generation_extra_percent,
        "input_monthly_consumptions": monthly_consumptions,
        "input_monthly_hsp": monthly_hsp,
    }

def calculate_financing(
    project_value,
    down_payment,
    monthly_interest_rate,
    term_months,
    monthly_savings,
):

    financed_amount = project_value - down_payment

    if financed_amount <= 0:

        payback_years = (
            project_value / (monthly_savings * 12)
            if monthly_savings > 0
            else 0
        )

        return {
            "project_value": project_value,
            "financed_amount": 0,
            "monthly_payment": 0,
            "total_paid": down_payment,
            "total_interest": 0,
            "payback_years": payback_years,
        }

    interest_rate = monthly_interest_rate / 100

    if interest_rate == 0:

        monthly_payment = financed_amount / term_months

    else:

        monthly_payment = financed_amount * (
            interest_rate
            * ((1 + interest_rate) ** term_months)
        ) / (
            ((1 + interest_rate) ** term_months) - 1
        )

    total_paid = down_payment + (monthly_payment * term_months)
    payback_years = (
        project_value / (monthly_savings * 12)
        if monthly_savings > 0
        else 0
    )

    return {
        "project_value": project_value,
        "financed_amount": financed_amount,
        "monthly_payment": monthly_payment,
        "total_paid": total_paid,
        "total_interest": total_paid - project_value,
        "payback_years": payback_years,
    }
