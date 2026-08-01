-- Enforce non-negative financial values and valid project discounts.
-- Discount is an absolute BRL amount, not a percentage.

alter table public.projects
    add constraint projects_financial_values_non_negative_check
    check (
        project_value >= 0
        and labor_cost >= 0
        and module_unit_cost >= 0
        and inverter_cost >= 0
        and support_cost >= 0
        and down_payment >= 0
        and discount >= 0
        and installment_value >= 0
        and installments_count >= 0
    );

alter table public.projects
    add constraint projects_discount_not_greater_than_project_value_check
    check (discount <= project_value);

alter table public.projects
    add constraint projects_installments_consistency_check
    check (
        (
            installments_count = 0
            and installment_value = 0
        )
        or
        (
            installments_count >= 1
            and installment_value > 0
        )
    );

alter table public.project_payments
    add constraint project_payments_amount_non_negative_check
    check (amount >= 0);

alter table public.manual_payments
    add constraint manual_payments_amount_non_negative_check
    check (amount >= 0);
