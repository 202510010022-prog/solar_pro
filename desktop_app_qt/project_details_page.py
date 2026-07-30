import json

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QComboBox,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QStackedWidget,
    QTableWidget,
    QTableWidgetItem,
    QVBoxLayout,
    QWidget,
)

from desktop_app.calculations import MONTHS
from desktop_app_qt.ui_components import ChartWidget, Section, brl, number


class ProjectDetailsPage(QWidget):
    def __init__(
        self,
        on_back=None,
        on_dimensioning=None,
        on_financing=None,
        on_upload_document=None,
        on_open_document=None,
        on_delete_document=None,
        document_categories=None,
    ):
        super().__init__()
        self.project = None
        self.on_back = on_back
        self.on_dimensioning = on_dimensioning
        self.on_financing = on_financing
        self.on_upload_document = on_upload_document
        self.on_open_document = on_open_document
        self.on_delete_document = on_delete_document
        self.document_categories = document_categories or []
        self.documents = []
        self.nav_buttons = []

        self.setObjectName("projectDetailsPage")
        root = QHBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(14)

        root.addWidget(self._build_sidebar())

        content = QFrame()
        content.setObjectName("projectDetailsContent")
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(12)

        content_layout.addWidget(self._build_header())
        self.stack = QStackedWidget()
        self.stack.addWidget(self._summary_page())
        self.stack.addWidget(self._dimensioning_page())
        self.stack.addWidget(self._financing_page())
        self.stack.addWidget(self._production_page())
        self.stack.addWidget(self._proposal_page())
        self.stack.addWidget(self._documents_page())
        self.stack.addWidget(self._history_page())
        content_layout.addWidget(self.stack, 1)

        root.addWidget(content, 1)
        self.show_tab(0)

    def _build_sidebar(self):
        sidebar = QFrame()
        sidebar.setObjectName("projectDetailsSidebar")
        sidebar.setFixedWidth(210)
        layout = QVBoxLayout(sidebar)
        layout.setContentsMargins(12, 14, 12, 14)
        layout.setSpacing(8)

        title = QLabel("Projeto")
        title.setObjectName("projectDetailsEyebrow")
        self.sidebar_project_label = QLabel("Selecione um projeto")
        self.sidebar_project_label.setObjectName("projectDetailsSidebarTitle")
        self.sidebar_project_label.setWordWrap(True)
        layout.addWidget(title)
        layout.addWidget(self.sidebar_project_label)
        layout.addSpacing(10)

        tabs = [
            "Resumo",
            "Dimensionamento",
            "Financeiro",
            "Produção",
            "Proposta",
            "Documentos",
            "Histórico",
        ]
        for index, text in enumerate(tabs):
            button = QPushButton(text)
            button.setObjectName("projectDetailsNavButton")
            button.setCheckable(True)
            button.clicked.connect(lambda checked=False, page=index: self.show_tab(page))
            self.nav_buttons.append(button)
            layout.addWidget(button)

        layout.addStretch()
        back = QPushButton("Voltar")
        back.setObjectName("secondaryButton")
        if self.on_back:
            back.clicked.connect(self.on_back)
        layout.addWidget(back)
        return sidebar

    def _build_header(self):
        header = QFrame()
        header.setObjectName("projectDetailsHeader")
        layout = QHBoxLayout(header)
        layout.setContentsMargins(16, 14, 16, 14)
        layout.setSpacing(12)

        title_box = QVBoxLayout()
        title_box.setSpacing(4)
        self.title_label = QLabel("Detalhes do Projeto")
        self.title_label.setObjectName("pageTitle")
        self.subtitle_label = QLabel("Dados técnicos, financeiros e histórico do projeto.")
        self.subtitle_label.setObjectName("pageSubtitle")
        self.subtitle_label.setWordWrap(True)
        title_box.addWidget(self.title_label)
        title_box.addWidget(self.subtitle_label)
        layout.addLayout(title_box, 1)

        self.status_badge = QLabel("-")
        self.status_badge.setObjectName("projectStatusBadge")
        self.status_badge.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.status_badge)

        dimensioning = QPushButton("Editar técnico")
        dimensioning.setObjectName("secondaryButton")
        if self.on_dimensioning:
            dimensioning.clicked.connect(lambda: self.on_dimensioning(self.project))
        financing = QPushButton("Abrir financeiro")
        financing.setObjectName("primaryButton")
        if self.on_financing:
            financing.clicked.connect(lambda: self.on_financing(self.project))
        layout.addWidget(dimensioning)
        layout.addWidget(financing)
        return header

    def _summary_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)

        metrics = QGridLayout()
        metrics.setHorizontalSpacing(10)
        metrics.setVerticalSpacing(10)
        self.summary_metrics = {}
        for index, (key, label) in enumerate([
            ("project_value", "Valor do projeto"),
            ("system_power", "Potência"),
            ("module_count", "Módulos"),
            ("annual_generation", "Geração anual"),
            ("payback_years", "Payback"),
            ("monthly_savings", "Economia mensal"),
        ]):
            metrics.addWidget(self._metric_card(key, label), index // 3, index % 3)
        layout.addLayout(metrics)

        section = Section("Dados do cliente")
        self.client_rows = QGridLayout()
        self.client_rows.setHorizontalSpacing(12)
        self.client_rows.setVerticalSpacing(8)
        section.layout.addLayout(self.client_rows)
        layout.addWidget(section)
        layout.addStretch()
        return page

    def _dimensioning_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)

        section = Section("Parâmetros técnicos")
        grid = QGridLayout()
        grid.setHorizontalSpacing(12)
        grid.setVerticalSpacing(8)
        self.dimensioning_labels = {}
        for index, (key, label) in enumerate([
            ("performance_ratio", "Performance ratio"),
            ("module_power", "Módulo W"),
            ("energy_tariff", "Tarifa R$/kWh"),
            ("generation_extra_percent", "Geração extra"),
            ("average_consumption", "Consumo médio"),
            ("average_hsp", "HSP médio"),
        ]):
            grid.addWidget(self._detail_pair(key, label, self.dimensioning_labels), index // 3, index % 3)
        section.layout.addLayout(grid)
        layout.addWidget(section)

        monthly = Section("Consumo, HSP e produção mensal")
        self.monthly_table = QTableWidget(0, 5)
        self.monthly_table.setHorizontalHeaderLabels([
            "Mês", "Consumo", "HSP", "Geração", "Saldo"
        ])
        self._setup_table(self.monthly_table)
        monthly.layout.addWidget(self.monthly_table)
        layout.addWidget(monthly, 1)
        return page

    def _financing_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)
        section = Section("Simulação financeira")
        grid = QGridLayout()
        grid.setHorizontalSpacing(12)
        grid.setVerticalSpacing(8)
        self.financing_labels = {}
        for index, (key, label) in enumerate([
            ("project_value", "Valor do projeto"),
            ("payment_type", "Tipo de pagamento"),
            ("down_payment", "Entrada"),
            ("discount", "Desconto"),
            ("installments", "Parcelamento"),
            ("first_due_date", "Primeiro vencimento"),
            ("financed_amount", "Valor financiado"),
            ("monthly_interest_rate", "Juros ao mês"),
            ("term_months", "Prazo"),
            ("monthly_payment", "Parcela"),
            ("total_paid", "Total pago"),
            ("total_interest", "Juros total"),
            ("payback_years", "Payback"),
        ]):
            grid.addWidget(self._detail_pair(key, label, self.financing_labels), index // 3, index % 3)
        section.layout.addLayout(grid)
        layout.addWidget(section)
        layout.addStretch()
        return page

    def _production_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        section = Section("Produção x consumo")
        self.production_chart = ChartWidget()
        section.layout.addWidget(self.production_chart)
        layout.addWidget(section)
        return page

    def _proposal_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        section = Section("Proposta")
        self.proposal_text = QLabel("Resumo comercial ainda não carregado.")
        self.proposal_text.setObjectName("resultText")
        self.proposal_text.setWordWrap(True)
        section.layout.addWidget(self.proposal_text)
        layout.addWidget(section)
        layout.addStretch()
        return page

    def _history_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        section = Section("Histórico do projeto")
        self.history_box = QVBoxLayout()
        self.history_box.setSpacing(8)
        section.layout.addLayout(self.history_box)
        layout.addWidget(section)
        layout.addStretch()
        return page

    def _documents_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)

        section = Section("Documentos do projeto")
        actions = QHBoxLayout()
        self.document_category_filter = QComboBox()
        self.document_category_filter.addItems(["Todos"] + self.document_categories)
        self.document_category_filter.currentIndexChanged.connect(
            self.refresh_documents_table
        )
        upload = QPushButton("Upload")
        upload.setObjectName("primaryButton")
        upload.clicked.connect(self.upload_document)
        open_button = QPushButton("Visualizar")
        open_button.clicked.connect(self.open_selected_document)
        delete_button = QPushButton("Excluir")
        delete_button.clicked.connect(self.delete_selected_document)
        actions.addWidget(QLabel("Categoria"))
        actions.addWidget(self.document_category_filter)
        actions.addStretch()
        actions.addWidget(upload)
        actions.addWidget(open_button)
        actions.addWidget(delete_button)
        section.layout.addLayout(actions)

        self.documents_table = QTableWidget(0, 5)
        self.documents_table.setHorizontalHeaderLabels([
            "ID", "Categoria", "Arquivo", "Tamanho", "Data"
        ])
        self._setup_table(self.documents_table)
        self.documents_table.doubleClicked.connect(
            lambda index: self.open_selected_document()
        )
        section.layout.addWidget(self.documents_table)
        layout.addWidget(section, 1)
        return page

    def _metric_card(self, key, label):
        card = QFrame()
        card.setObjectName("projectMetricCard")
        layout = QVBoxLayout(card)
        layout.setContentsMargins(12, 10, 12, 10)
        layout.setSpacing(4)
        title = QLabel(label)
        title.setObjectName("metricLabel")
        value = QLabel("-")
        value.setObjectName("metricValue")
        layout.addWidget(title)
        layout.addWidget(value)
        self.summary_metrics[key] = value
        return card

    def _detail_pair(self, key, label, registry):
        box = QFrame()
        box.setObjectName("projectInfoBox")
        layout = QVBoxLayout(box)
        layout.setContentsMargins(10, 8, 10, 8)
        layout.setSpacing(3)
        title = QLabel(label)
        title.setObjectName("metricLabel")
        value = QLabel("-")
        value.setObjectName("metricValue")
        value.setWordWrap(True)
        registry[key] = value
        layout.addWidget(title)
        layout.addWidget(value)
        return box

    def _setup_table(self, table):
        table.setAlternatingRowColors(True)
        table.verticalHeader().setVisible(False)
        table.verticalHeader().setDefaultSectionSize(34)
        table.setSelectionBehavior(QTableWidget.SelectRows)
        table.setEditTriggers(QTableWidget.NoEditTriggers)
        table.horizontalHeader().setStretchLastSection(True)

    def show_tab(self, index):
        self.stack.setCurrentIndex(index)
        for button_index, button in enumerate(self.nav_buttons):
            button.setChecked(button_index == index)

    def set_project(self, project):
        self.project = project
        if not project:
            self.title_label.setText("Detalhes do Projeto")
            self.sidebar_project_label.setText("Selecione um projeto")
            self.status_badge.setText("-")
            return

        project_id = project.get("id", "-")
        client_name = project.get("client_name", "Cliente sem nome")
        status = project.get("status", "-")
        self.title_label.setText(f"Projeto #{project_id}")
        self.subtitle_label.setText(f"{client_name} · {project.get('budget_date', project.get('project_date', '-'))}")
        self.sidebar_project_label.setText(f"#{project_id}\n{client_name}")
        self.status_badge.setText(status)

        self._fill_summary(project)
        self._fill_dimensioning(project)
        self._fill_financing(project)
        self._fill_production(project)
        self._fill_proposal(project)
        self._fill_history(project)
        self.set_documents([])

    def _fill_summary(self, project):
        values = {
            "project_value": brl(self._float(project, "project_value", "investment")),
            "system_power": f"{number(self._float(project, 'system_power'))} kWp",
            "module_count": str(int(self._float(project, "module_count"))),
            "annual_generation": f"{number(self._float(project, 'annual_generation'))} kWh",
            "payback_years": f"{number(self._float(project, 'payback_years'))} anos",
            "monthly_savings": brl(self._float(project, "monthly_savings")),
        }
        for key, label in self.summary_metrics.items():
            label.setText(values.get(key, "-"))

        self._clear_layout(self.client_rows)
        client_values = [
            ("Cliente", project.get("client_name", "-")),
            ("CPF/CNPJ", project.get("client_document", "-")),
            ("Telefone", project.get("client_phone", "-")),
            ("Email", project.get("client_email", "-")),
            ("Cidade", project.get("client_city", "-")),
            ("Estado", project.get("client_state", "-")),
        ]
        for index, (label, value) in enumerate(client_values):
            self.client_rows.addWidget(
                self._readonly_text(label, value),
                index // 3,
                index % 3,
            )

    def _fill_dimensioning(self, project):
        values = {
            "performance_ratio": number(self._float(project, "performance_ratio")),
            "module_power": f"{number(self._float(project, 'module_power'), 0)} W",
            "energy_tariff": brl(self._float(project, "energy_tariff")).replace("R$ ", "R$/kWh "),
            "generation_extra_percent": f"{number(self._float(project, 'generation_extra_percent'))}%",
            "average_consumption": f"{number(self._float(project, 'average_consumption'))} kWh",
            "average_hsp": number(self._float(project, "average_hsp")),
        }
        for key, label in self.dimensioning_labels.items():
            label.setText(values.get(key, "-"))

        consumption = self._json_list(project.get("monthly_consumptions"))
        hsp = self._json_list(project.get("monthly_hsp"))
        generation = self._json_list(project.get("monthly_generations"))
        balance = self._json_list(project.get("monthly_balances"))
        self.monthly_table.setRowCount(len(MONTHS))
        for row, month in enumerate(MONTHS):
            values = [
                month,
                f"{number(self._at(consumption, row))} kWh",
                number(self._at(hsp, row)),
                f"{number(self._at(generation, row))} kWh",
                f"{number(self._at(balance, row))} kWh",
            ]
            for column, value in enumerate(values):
                self.monthly_table.setItem(row, column, QTableWidgetItem(value))

    def _fill_financing(self, project):
        values = {
            "project_value": brl(self._float(project, "project_value", "investment")),
            "payment_type": str(project.get("payment_type") or "-"),
            "down_payment": brl(self._float(project, "down_payment")),
            "discount": brl(self._float(project, "discount")),
            "installments": (
                f"{int(self._float(project, 'installments_count'))}x de "
                f"{brl(self._float(project, 'installment_value'))}"
            ),
            "first_due_date": str(project.get("first_due_date") or "-"),
            "financed_amount": brl(self._float(project, "financed_amount")),
            "monthly_interest_rate": f"{number(self._float(project, 'monthly_interest_rate'))}%",
            "term_months": f"{int(self._float(project, 'term_months'))} meses",
            "monthly_payment": brl(self._float(project, "monthly_payment")),
            "total_paid": brl(self._float(project, "total_paid")),
            "total_interest": brl(self._float(project, "total_interest")),
            "payback_years": f"{number(self._float(project, 'payback_years'))} anos",
        }
        for key, label in self.financing_labels.items():
            label.setText(values.get(key, "-"))

    def _fill_production(self, project):
        consumption = self._json_list(project.get("monthly_consumptions"))
        generation = self._json_list(project.get("monthly_generations"))
        balance = self._json_list(project.get("monthly_balances"))
        self.production_chart.set_data(consumption, generation, balance)

    def _fill_proposal(self, project):
        text = (
            f"Cliente: {project.get('client_name', '-')}\n"
            f"Status: {project.get('status', '-')}\n"
            f"Potência sugerida: {number(self._float(project, 'system_power'))} kWp\n"
            f"Módulos: {int(self._float(project, 'module_count'))}\n"
            f"Geração anual estimada: {number(self._float(project, 'annual_generation'))} kWh\n"
            f"Valor do projeto: {brl(self._float(project, 'project_value', 'investment'))}\n"
            f"Payback estimado: {number(self._float(project, 'payback_years'))} anos"
        )
        self.proposal_text.setText(text)

    def _fill_history(self, project):
        self._clear_layout(self.history_box)
        history = self._json_list(project.get("history"))
        if not history:
            history = [
                {
                    "action": "imported",
                    "detail": "Projeto disponível no banco de dados.",
                    "created_at": project.get("budget_date") or project.get("project_date") or "-",
                }
            ]
        for item in history:
            row = QFrame()
            row.setObjectName("projectHistoryRow")
            layout = QVBoxLayout(row)
            layout.setContentsMargins(10, 8, 10, 8)
            layout.setSpacing(2)
            title = QLabel(str(item.get("detail") or item.get("action") or "Evento"))
            title.setObjectName("activityTitle")
            date = QLabel(str(item.get("created_at", "")))
            date.setObjectName("muted")
            layout.addWidget(title)
            layout.addWidget(date)
            self.history_box.addWidget(row)
        self.history_box.addStretch()

    def set_documents(self, documents):
        self.documents = documents or []
        self.refresh_documents_table()

    def refresh_documents_table(self):
        if not hasattr(self, "documents_table"):
            return

        category = (
            self.document_category_filter.currentText()
            if hasattr(self, "document_category_filter")
            else "Todos"
        )
        documents = [
            document for document in self.documents
            if category == "Todos" or document["category"] == category
        ]
        self.documents_table.setRowCount(len(documents))
        for row, document in enumerate(documents):
            values = [
                document["id"],
                document["category"],
                document["original_name"],
                self._file_size(document.get("file_size", 0)),
                document.get("created_at", ""),
            ]
            for column, value in enumerate(values):
                item = QTableWidgetItem(str(value))
                if column == 0:
                    item.setData(Qt.UserRole, document["id"])
                self.documents_table.setItem(row, column, item)

    def upload_document(self):
        if self.project and self.on_upload_document:
            self.on_upload_document(self.project)

    def open_selected_document(self):
        document_id = self.selected_document_id()
        if document_id and self.on_open_document:
            self.on_open_document(document_id)

    def delete_selected_document(self):
        document_id = self.selected_document_id()
        if document_id and self.on_delete_document:
            self.on_delete_document(document_id)

    def selected_document_id(self):
        rows = self.documents_table.selectionModel().selectedRows()
        if not rows:
            return None
        item = self.documents_table.item(rows[0].row(), 0)
        return item.data(Qt.UserRole) if item else None

    def _file_size(self, value):
        try:
            size = int(value or 0)
        except (TypeError, ValueError):
            size = 0
        if size >= 1024 * 1024:
            return f"{size / (1024 * 1024):.1f} MB"
        if size >= 1024:
            return f"{size / 1024:.1f} KB"
        return f"{size} B"

    def _readonly_text(self, label, value):
        box = QFrame()
        box.setObjectName("projectInfoBox")
        layout = QVBoxLayout(box)
        layout.setContentsMargins(10, 8, 10, 8)
        layout.setSpacing(3)
        title = QLabel(label)
        title.setObjectName("metricLabel")
        content = QLabel(str(value or "-"))
        content.setObjectName("metricValue")
        content.setWordWrap(True)
        layout.addWidget(title)
        layout.addWidget(content)
        return box

    def _float(self, project, *keys):
        for key in keys:
            if key in project and project.get(key) not in (None, ""):
                try:
                    return float(project.get(key))
                except (TypeError, ValueError):
                    return 0.0
        return 0.0

    def _json_list(self, value):
        if isinstance(value, list):
            return value
        try:
            parsed = json.loads(value or "[]")
        except (TypeError, json.JSONDecodeError):
            return []
        return parsed if isinstance(parsed, list) else []

    def _at(self, values, index):
        return float(values[index]) if index < len(values) else 0.0

    def _clear_layout(self, layout):
        while layout.count():
            item = layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
            elif item.layout():
                self._clear_layout(item.layout())
