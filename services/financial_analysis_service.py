from dataclasses import dataclass
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

from matplotlib import pyplot as plt


@dataclass(frozen=True)
class FinancialAnalysisResult:
    investment: float
    years: int
    discount_rate: float
    roi_percent: float
    irr_percent: float | None
    npv: float
    annual_cash_flow: list[float]
    accumulated_cash_flow: list[float]


class FinancialAnalysisService:
    def analyze(
        self,
        investment,
        annual_savings,
        years=25,
        discount_rate=0.08,
        annual_maintenance=0,
        energy_inflation_rate=0,
        degradation_rate=0,
    ):
        investment = self._positive_float(investment, "investment")
        annual_savings = self._float(annual_savings, "annual_savings")
        years = self._positive_int(years, "years")
        discount_rate = self._rate(discount_rate, "discount_rate")
        annual_maintenance = self._float(annual_maintenance, "annual_maintenance")
        energy_inflation_rate = self._rate(
            energy_inflation_rate,
            "energy_inflation_rate",
        )
        degradation_rate = self._rate(degradation_rate, "degradation_rate")

        annual_cash_flow = self._annual_cash_flow(
            annual_savings,
            years,
            annual_maintenance,
            energy_inflation_rate,
            degradation_rate,
        )
        accumulated_cash_flow = self._accumulated_cash_flow(
            investment,
            annual_cash_flow,
        )
        npv = self.calculate_npv(investment, annual_cash_flow, discount_rate)
        roi_percent = self.calculate_roi(investment, annual_cash_flow)
        irr = self.calculate_irr(investment, annual_cash_flow)

        return FinancialAnalysisResult(
            investment=investment,
            years=years,
            discount_rate=discount_rate,
            roi_percent=roi_percent,
            irr_percent=irr * 100 if irr is not None else None,
            npv=npv,
            annual_cash_flow=annual_cash_flow,
            accumulated_cash_flow=accumulated_cash_flow,
        )

    def calculate_roi(self, investment, annual_cash_flow):
        total_return = sum(annual_cash_flow)
        return ((total_return - investment) / investment) * 100

    def calculate_npv(self, investment, annual_cash_flow, discount_rate):
        return -investment + sum(
            cash_flow / ((1 + discount_rate) ** year)
            for year, cash_flow in enumerate(annual_cash_flow, start=1)
        )

    def calculate_irr(self, investment, annual_cash_flow):
        cash_flows = [-investment] + list(annual_cash_flow)
        if not self._has_irr_solution(cash_flows):
            return None

        low = -0.9999
        high = 1.0
        low_value = self._npv_at_rate(cash_flows, low)
        high_value = self._npv_at_rate(cash_flows, high)

        while low_value * high_value > 0 and high < 100:
            high *= 2
            high_value = self._npv_at_rate(cash_flows, high)

        if low_value * high_value > 0:
            return None

        for _ in range(120):
            midpoint = (low + high) / 2
            midpoint_value = self._npv_at_rate(cash_flows, midpoint)
            if abs(midpoint_value) < 1e-7:
                return midpoint
            if low_value * midpoint_value < 0:
                high = midpoint
                high_value = midpoint_value
            else:
                low = midpoint
                low_value = midpoint_value

        return (low + high) / 2

    def create_cash_flow_chart(self, result):
        years = list(range(1, result.years + 1))
        figure, axis = plt.subplots(figsize=(9, 4.8))
        colors = [
            "#48e13b" if value >= 0 else "#ef4444"
            for value in result.annual_cash_flow
        ]
        axis.bar(years, result.annual_cash_flow, color=colors)
        self._style_axis(
            axis,
            title="Fluxo de caixa anual",
            ylabel="R$ por ano",
        )
        axis.set_xlabel("Ano")
        figure.tight_layout()
        return figure

    def create_accumulated_cash_flow_chart(self, result):
        years = list(range(1, result.years + 1))
        figure, axis = plt.subplots(figsize=(9, 4.8))
        axis.plot(
            years,
            result.accumulated_cash_flow,
            color="#00aaff",
            linewidth=2.5,
            marker="o",
            markersize=4,
        )
        axis.axhline(0, color="#48e13b", linewidth=1.2, linestyle="--")
        self._style_axis(
            axis,
            title="Fluxo de caixa acumulado",
            ylabel="R$ acumulado",
        )
        axis.set_xlabel("Ano")
        figure.tight_layout()
        return figure

    def create_indicator_chart(self, result):
        labels = ["ROI", "TIR", "VPL"]
        values = [
            result.roi_percent,
            result.irr_percent or 0,
            result.npv,
        ]
        colors = ["#48e13b", "#00aaff", "#8a3ffc"]
        figure, axis = plt.subplots(figsize=(8.5, 4.8))
        axis.bar(labels, values, color=colors)
        self._style_axis(
            axis,
            title="Indicadores financeiros",
            ylabel="ROI/TIR (%) e VPL (R$)",
        )
        figure.tight_layout()
        return figure

    def save_charts(self, result, output_dir):
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        charts = {
            "fluxo_caixa_anual.png": self.create_cash_flow_chart(result),
            "fluxo_caixa_acumulado.png": self.create_accumulated_cash_flow_chart(
                result
            ),
            "indicadores_financeiros.png": self.create_indicator_chart(result),
        }
        saved_paths = {}
        for filename, figure in charts.items():
            path = output_path / filename
            figure.savefig(path, dpi=150, facecolor=figure.get_facecolor())
            plt.close(figure)
            saved_paths[filename] = path
        return saved_paths

    def _annual_cash_flow(
        self,
        annual_savings,
        years,
        annual_maintenance,
        energy_inflation_rate,
        degradation_rate,
    ):
        flows = []
        for year in range(years):
            savings = annual_savings
            savings *= (1 + energy_inflation_rate) ** year
            savings *= (1 - degradation_rate) ** year
            maintenance = annual_maintenance * ((1 + energy_inflation_rate) ** year)
            flows.append(savings - maintenance)
        return flows

    def _accumulated_cash_flow(self, investment, annual_cash_flow):
        accumulated = []
        current = -investment
        for cash_flow in annual_cash_flow:
            current += cash_flow
            accumulated.append(current)
        return accumulated

    def _style_axis(self, axis, title, ylabel):
        figure = axis.figure
        figure.patch.set_facecolor("#020817")
        axis.set_facecolor("#06101f")
        axis.set_title(title, color="#f8fafc", fontsize=14, fontweight="bold")
        axis.set_ylabel(ylabel, color="#cbd5e1")
        axis.tick_params(colors="#cbd5e1")
        axis.grid(True, color="#1e3a5f", linestyle="-", linewidth=0.6, alpha=0.55)
        for spine in axis.spines.values():
            spine.set_color("#1e3a5f")

    def _npv_at_rate(self, cash_flows, rate):
        return sum(
            cash_flow / ((1 + rate) ** index)
            for index, cash_flow in enumerate(cash_flows)
        )

    def _has_irr_solution(self, cash_flows):
        return any(value < 0 for value in cash_flows) and any(
            value > 0 for value in cash_flows
        )

    def _positive_float(self, value, field_name):
        number = self._float(value, field_name)
        if number <= 0:
            raise ValueError(f"{field_name} must be greater than zero.")
        return number

    def _positive_int(self, value, field_name):
        number = int(value)
        if number <= 0:
            raise ValueError(f"{field_name} must be greater than zero.")
        return number

    def _rate(self, value, field_name):
        rate = self._float(value, field_name)
        if rate < -0.9999:
            raise ValueError(f"{field_name} must be greater than -99.99%.")
        if rate > 1:
            rate = rate / 100
        return rate

    def _float(self, value, field_name):
        try:
            return float(value)
        except (TypeError, ValueError) as exc:
            raise ValueError(f"{field_name} must be numeric.") from exc
