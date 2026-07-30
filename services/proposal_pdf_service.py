from datetime import datetime
from pathlib import Path
from tempfile import TemporaryDirectory

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


class ProposalPDFService:
    def __init__(self, output_dir="exports/propostas", logo_path=None):
        self.output_dir = Path(output_dir)
        self.logo_path = Path(logo_path) if logo_path else self._default_logo_path()
        self.styles = self._build_styles()

    def export(
        self,
        client,
        project,
        equipment=None,
        production=None,
        financial=None,
        charts=None,
        signature=None,
        filename=None,
    ):
        self.output_dir.mkdir(parents=True, exist_ok=True)
        filename = filename or self._default_filename(client, project)
        pdf_path = self.output_dir / filename

        with TemporaryDirectory() as temporary_dir:
            chart_paths = self._prepare_charts(charts or [], temporary_dir)
            document = SimpleDocTemplate(
                str(pdf_path),
                pagesize=A4,
                rightMargin=1.6 * cm,
                leftMargin=1.6 * cm,
                topMargin=1.6 * cm,
                bottomMargin=1.4 * cm,
                title="Proposta Solar Pro",
                author="Solar Pro",
            )
            story = []
            story.extend(self._cover(client, project))
            story.append(PageBreak())
            story.extend(self._client_data(client))
            story.extend(self._executive_summary(project, production, financial))
            story.extend(self._equipment(equipment or {}))
            story.extend(self._production(project, production or {}))
            story.extend(self._annual_savings(project, financial or {}))
            story.extend(self._financial_flow(financial or {}))
            story.extend(self._charts(chart_paths))
            story.extend(self._signature(signature))

            document.build(
                story,
                onFirstPage=self._draw_page_frame,
                onLaterPages=self._draw_page_frame,
            )

        return pdf_path

    def _cover(self, client, project):
        story = [Spacer(1, 1.0 * cm)]
        if self.logo_path and self.logo_path.exists():
            story.append(Image(str(self.logo_path), width=6.2 * cm, height=2.0 * cm))
            story.append(Spacer(1, 1.0 * cm))

        story.append(Paragraph("Proposta Comercial", self.styles["coverTitle"]))
        story.append(Spacer(1, 0.25 * cm))
        story.append(Paragraph("Sistema Fotovoltaico", self.styles["coverSubtitle"]))
        story.append(Spacer(1, 1.0 * cm))
        story.append(
            self._highlight_table(
                [
                    ["Cliente", self._value(client, "name", "Nome não informado")],
                    ["Projeto", f"#{self._value(project, 'id', '-')}"],
                    ["Status", self._value(project, "status", "-")],
                    ["Data", datetime.now().strftime("%d/%m/%Y")],
                ]
            )
        )
        story.append(Spacer(1, 5.6 * cm))
        story.append(
            Paragraph(
                "Solar Pro Energia Solar",
                self.styles["footerCenter"],
            )
        )
        return story

    def _client_data(self, client):
        rows = [
            ["Nome", self._value(client, "name", "-")],
            ["CPF/CNPJ", self._value(client, "document", "-")],
            ["Telefone", self._value(client, "phone", "-")],
            ["Email", self._value(client, "email", "-")],
            ["Cidade/UF", f"{self._value(client, 'city', '-')} / {self._value(client, 'state', '-')}"],
        ]
        return self._section("Dados do cliente", [self._data_table(rows)])

    def _executive_summary(self, project, production, financial):
        annual_generation = self._number(
            self._value(production, "annual_generation", self._value(project, "annual_generation", 0))
        )
        project_value = self._money(
            self._value(financial, "project_value", self._value(project, "project_value", 0))
        )
        payback = self._number(
            self._value(financial, "payback_years", self._value(project, "payback_years", 0))
        )
        text = (
            "Esta proposta apresenta o dimensionamento técnico e a análise financeira "
            "para implantação de um sistema fotovoltaico. A solução foi estruturada "
            "para reduzir custos com energia e oferecer previsibilidade econômica ao cliente."
        )
        rows = [
            ["Potência instalada", f"{self._number(self._value(project, 'system_power', 0))} kWp"],
            ["Geração anual estimada", f"{annual_generation} kWh"],
            ["Valor do projeto", project_value],
            ["Payback estimado", f"{payback} anos"],
        ]
        return self._section(
            "Resumo executivo",
            [
                Paragraph(text, self.styles["body"]),
                Spacer(1, 0.25 * cm),
                self._data_table(rows),
            ],
        )

    def _equipment(self, equipment):
        rows = [
            ["Módulos", self._value(equipment, "modules", "-")],
            ["Potência do módulo", self._value(equipment, "module_power", "-")],
            ["Inversor", self._value(equipment, "inverter", "-")],
            ["Estrutura", self._value(equipment, "structure", "-")],
            ["Observações", self._value(equipment, "notes", "-")],
        ]
        return self._section("Equipamentos", [self._data_table(rows)])

    def _production(self, project, production):
        rows = [
            ["Consumo anual", f"{self._number(self._value(production, 'annual_consumption', self._value(project, 'annual_consumption', 0)))} kWh"],
            ["Produção anual", f"{self._number(self._value(production, 'annual_generation', self._value(project, 'annual_generation', 0)))} kWh"],
            ["HSP médio", self._number(self._value(production, "average_hsp", self._value(project, "average_hsp", 0)))],
            ["Performance ratio", self._number(self._value(production, "performance_ratio", self._value(project, "performance_ratio", 0)))],
        ]
        return self._section("Produção estimada", [self._data_table(rows)])

    def _annual_savings(self, project, financial):
        monthly_savings = float(
            self._value(financial, "monthly_savings", self._value(project, "monthly_savings", 0)) or 0
        )
        annual_savings = self._value(financial, "annual_savings", monthly_savings * 12)
        rows = [
            ["Economia mensal estimada", self._money(monthly_savings)],
            ["Economia anual estimada", self._money(annual_savings)],
            ["Valor do projeto", self._money(self._value(financial, "project_value", self._value(project, "project_value", 0)))],
        ]
        return self._section("Economia anual", [self._data_table(rows)])

    def _financial_flow(self, financial):
        flow = self._value(financial, "annual_cash_flow", [])
        accumulated = self._value(financial, "accumulated_cash_flow", [])
        rows = [["Ano", "Fluxo anual", "Fluxo acumulado"]]
        for index, annual_value in enumerate(flow[:12], start=1):
            accumulated_value = accumulated[index - 1] if index - 1 < len(accumulated) else 0
            rows.append([
                str(index),
                self._money(annual_value),
                self._money(accumulated_value),
            ])

        indicators = [
            ["ROI", f"{self._number(self._value(financial, 'roi_percent', 0))}%"],
            ["TIR", f"{self._number(self._value(financial, 'irr_percent', 0))}%"],
            ["VPL", self._money(self._value(financial, "npv", 0))],
        ]
        return self._section(
            "Fluxo financeiro",
            [
                self._data_table(indicators),
                Spacer(1, 0.25 * cm),
                self._flow_table(rows),
            ],
        )

    def _charts(self, chart_paths):
        if not chart_paths:
            return []
        elements = [Paragraph("Gráficos", self.styles["sectionTitle"])]
        for path in chart_paths:
            if path.exists():
                elements.append(Spacer(1, 0.2 * cm))
                elements.append(Image(str(path), width=16.2 * cm, height=8.6 * cm))
        elements.append(Spacer(1, 0.35 * cm))
        return elements

    def _signature(self, signature):
        signer = self._value(signature or {}, "name", "Responsável Solar Pro")
        role = self._value(signature or {}, "role", "Consultor")
        date = self._value(signature or {}, "date", datetime.now().strftime("%d/%m/%Y"))
        signature_table = Table(
            [
                ["", ""],
                ["_" * 34, "_" * 34],
                [signer, self._value(signature or {}, "client_name", "Cliente")],
                [role, f"Aceite da proposta - {date}"],
            ],
            colWidths=[8 * cm, 8 * cm],
        )
        signature_table.setStyle(
            TableStyle(
                [
                    ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor("#0f172a")),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("TOPPADDING", (0, 0), (-1, -1), 8),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )
        return self._section("Assinatura", [signature_table])

    def _section(self, title, elements):
        return [
            Paragraph(title, self.styles["sectionTitle"]),
            Spacer(1, 0.16 * cm),
            *elements,
            Spacer(1, 0.45 * cm),
        ]

    def _data_table(self, rows):
        table = Table(rows, colWidths=[5.0 * cm, 11.2 * cm])
        table.setStyle(self._base_table_style())
        return table

    def _highlight_table(self, rows):
        table = Table(rows, colWidths=[4.3 * cm, 9.6 * cm])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#06101f")),
                    ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor("#f8fafc")),
                    ("TEXTCOLOR", (0, 0), (0, -1), colors.HexColor("#00aaff")),
                    ("GRID", (0, 0), (-1, -1), 0.6, colors.HexColor("#1e3a5f")),
                    ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 10),
                    ("TOPPADDING", (0, 0), (-1, -1), 9),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 9),
                ]
            )
        )
        return table

    def _flow_table(self, rows):
        table = Table(rows, colWidths=[2.2 * cm, 6.8 * cm, 7.2 * cm])
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#06101f")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#f8fafc")),
                    ("TEXTCOLOR", (0, 1), (-1, -1), colors.HexColor("#0f172a")),
                    ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#cbd5e1")),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("ALIGN", (1, 1), (-1, -1), "RIGHT"),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
                    ("TOPPADDING", (0, 0), (-1, -1), 6),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ]
            )
        )
        return table

    def _base_table_style(self):
        return TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#06101f")),
                ("TEXTCOLOR", (0, 0), (0, -1), colors.HexColor("#f8fafc")),
                ("TEXTCOLOR", (1, 0), (1, -1), colors.HexColor("#0f172a")),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#cbd5e1")),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("ROWBACKGROUNDS", (1, 0), (1, -1), [colors.white, colors.HexColor("#f8fafc")]),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )

    def _prepare_charts(self, charts, temporary_dir):
        chart_paths = []
        temporary_path = Path(temporary_dir)
        for index, chart in enumerate(charts, start=1):
            if hasattr(chart, "savefig"):
                path = temporary_path / f"grafico_{index}.png"
                chart.savefig(path, dpi=150, bbox_inches="tight")
                chart_paths.append(path)
                continue
            path = Path(chart)
            if path.exists():
                chart_paths.append(path)
        return chart_paths

    def _draw_page_frame(self, canvas, document):
        canvas.saveState()
        width, height = A4
        canvas.setFillColor(colors.HexColor("#020817"))
        canvas.rect(0, height - 0.55 * cm, width, 0.55 * cm, fill=1, stroke=0)
        canvas.setFillColor(colors.HexColor("#00aaff"))
        canvas.rect(0, height - 0.58 * cm, width, 0.03 * cm, fill=1, stroke=0)
        canvas.setFillColor(colors.HexColor("#64748b"))
        canvas.setFont("Helvetica", 8)
        canvas.drawRightString(
            width - 1.6 * cm,
            0.85 * cm,
            f"Solar Pro | Página {document.page}",
        )
        canvas.restoreState()

    def _build_styles(self):
        base = getSampleStyleSheet()
        base.add(
            ParagraphStyle(
                name="coverTitle",
                parent=base["Title"],
                fontName="Helvetica-Bold",
                fontSize=28,
                leading=34,
                textColor=colors.HexColor("#020817"),
                alignment=TA_CENTER,
            )
        )
        base.add(
            ParagraphStyle(
                name="coverSubtitle",
                parent=base["Heading2"],
                fontSize=15,
                leading=20,
                textColor=colors.HexColor("#007bff"),
                alignment=TA_CENTER,
            )
        )
        base.add(
            ParagraphStyle(
                name="sectionTitle",
                parent=base["Heading2"],
                fontName="Helvetica-Bold",
                fontSize=15,
                leading=19,
                textColor=colors.HexColor("#020817"),
                spaceBefore=4,
            )
        )
        base.add(
            ParagraphStyle(
                name="body",
                parent=base["BodyText"],
                fontSize=10,
                leading=15,
                textColor=colors.HexColor("#0f172a"),
                alignment=TA_LEFT,
            )
        )
        base.add(
            ParagraphStyle(
                name="footerCenter",
                parent=base["BodyText"],
                fontSize=10,
                leading=14,
                textColor=colors.HexColor("#64748b"),
                alignment=TA_CENTER,
            )
        )
        base.add(
            ParagraphStyle(
                name="footerRight",
                parent=base["BodyText"],
                fontSize=8,
                leading=10,
                textColor=colors.HexColor("#64748b"),
                alignment=TA_RIGHT,
            )
        )
        return base

    def _default_logo_path(self):
        path = Path("desktop_app_qt/assets/ui_kit/logo_horizontal.png")
        return path if path.exists() else None

    def _default_filename(self, client, project):
        name = self._slug(self._value(client, "name", "cliente"))
        project_id = self._value(project, "id", "novo")
        return f"proposta_{name}_{project_id}.pdf"

    def _value(self, source, key, default=None):
        if source is None:
            return default
        if isinstance(source, dict):
            return source.get(key, default)
        return getattr(source, key, default)

    def _money(self, value):
        try:
            number = float(value or 0)
        except (TypeError, ValueError):
            number = 0
        return f"R$ {number:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")

    def _number(self, value, digits=2):
        try:
            number = float(value or 0)
        except (TypeError, ValueError):
            number = 0
        return f"{number:.{digits}f}".replace(".", ",")

    def _slug(self, value):
        allowed = []
        for char in str(value).lower():
            if char.isalnum():
                allowed.append(char)
            elif char in {" ", "-", "_"}:
                allowed.append("_")
        slug = "".join(allowed).strip("_")
        return slug or "cliente"
