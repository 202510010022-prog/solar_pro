from datetime import date
import tkinter as tk
from tkinter import messagebox, ttk
import json

from calculations import MONTHS, calculate_financing, calculate_sizing
from database import (
    create_budget,
    create_client,
    get_dashboard_totals,
    initialize_database,
    list_budgets,
    list_clients,
    update_budget_status,
    update_budget_financing,
)
from validators import (
    format_document,
    format_phone,
    only_digits,
    validate_document,
    validate_email,
    validate_phone,
)

STATUSES = [
    "Em negociação",
    "Fechado",
    "Concluído",
]

class SolarManagerApp(tk.Tk):

    def __init__(self):

        super().__init__()

        self.title("Solar Manager")
        self.geometry("1180x760")
        self.minsize(920, 620)
        self.configure(bg="#f6f5f4")

        initialize_database()

        self.clients = []
        self.budgets = []
        self.filtered_budgets = []

        self._configure_style()
        self._build_menu()
        self._build_layout()
        self.refresh_all()

    def _build_menu(self):

        menu_bar = tk.Menu(self)

        file_menu = tk.Menu(menu_bar, tearoff=0)
        file_menu.add_command(
            label="Atualizar",
            command=self.refresh_all,
        )
        file_menu.add_separator()
        file_menu.add_command(
            label="Sair",
            command=self.destroy,
        )

        view_menu = tk.Menu(menu_bar, tearoff=0)
        view_menu.add_command(
            label="Dashboard",
            command=lambda: self.notebook.select(self.dashboard_tab),
        )
        view_menu.add_command(
            label="Clientes",
            command=lambda: self.notebook.select(self.clients_tab),
        )
        view_menu.add_command(
            label="Dimensionamento",
            command=lambda: self.notebook.select(self.budget_tab),
        )
        view_menu.add_command(
            label="Financiamento",
            command=lambda: self.notebook.select(self.finance_tab),
        )
        view_menu.add_command(
            label="Gráficos",
            command=lambda: self.notebook.select(self.charts_tab),
        )
        view_menu.add_command(
            label="Orçamentos",
            command=lambda: self.notebook.select(self.history_tab),
        )

        menu_bar.add_cascade(label="Arquivo", menu=file_menu)
        menu_bar.add_cascade(label="Exibir", menu=view_menu)

        self.config(menu=menu_bar)

    def _configure_style(self):

        self.style = ttk.Style(self)

        try:

            self.style.theme_use("clam")

        except tk.TclError:

            pass

        font = ("Cantarell", 10)
        title_font = ("Cantarell", 17, "bold")
        subtitle_font = ("Cantarell", 9)
        metric_font = ("Cantarell", 15, "bold")
        dashboard_title_font = ("Cantarell", 14, "bold")

        self.style.configure(
            ".",
            font=font,
            background="#f6f5f4",
            foreground="#241f31",
        )

        self.style.configure(
            "App.TFrame",
            background="#f6f5f4",
        )

        self.style.configure(
            "Sidebar.TFrame",
            background="#deddda",
        )

        self.style.configure(
            "Card.TFrame",
            background="#ffffff",
            relief="solid",
            borderwidth=1,
        )

        self.style.configure(
            "Panel.TLabelframe",
            background="#ffffff",
            borderwidth=1,
            relief="solid",
        )
        self.style.configure(
            "Panel.TLabelframe.Label",
            background="#ffffff",
            foreground="#241f31",
            font=("Cantarell", 10, "bold"),
        )

        self.style.configure(
            "Title.TLabel",
            background="#deddda",
            foreground="#241f31",
            font=title_font,
        )

        self.style.configure(
            "Subtitle.TLabel",
            background="#deddda",
            foreground="#5e5c64",
            font=subtitle_font,
        )

        self.style.configure(
            "CardLabel.TLabel",
            background="#ffffff",
            foreground="#5e5c64",
            font=subtitle_font,
        )

        self.style.configure(
            "Metric.TLabel",
            background="#ffffff",
            foreground="#241f31",
            font=metric_font,
        )

        self.style.configure(
            "DashboardTitle.TLabel",
            background="#ffffff",
            foreground="#241f31",
            font=dashboard_title_font,
        )

        self.style.configure(
            "Panel.TFrame",
            background="#ffffff",
        )

        self.style.configure(
            "Header.TLabel",
            background="#f6f5f4",
            foreground="#241f31",
            font=("Cantarell", 18, "bold"),
        )

        self.style.configure(
            "Muted.TLabel",
            background="#f6f5f4",
            foreground="#5e5c64",
            font=("Cantarell", 10),
        )

        self.style.configure(
            "Status.TLabel",
            background="#deddda",
            foreground="#5e5c64",
            font=("Cantarell", 9),
        )

        self.style.configure(
            "Primary.TButton",
            background="#3584e4",
            foreground="#ffffff",
            borderwidth=0,
            focusthickness=0,
            padding=(12, 8),
        )
        self.style.map(
            "Primary.TButton",
            background=[
                ("active", "#1c71d8"),
                ("pressed", "#1a5fb4"),
            ],
            foreground=[
                ("disabled", "#deddda"),
            ],
        )

        self.style.configure(
            "TButton",
            padding=(10, 7),
        )

        self.style.configure(
            "TEntry",
            fieldbackground="#ffffff",
            bordercolor="#c0bfbc",
            lightcolor="#c0bfbc",
            darkcolor="#c0bfbc",
            padding=6,
        )

        self.style.configure(
            "TCombobox",
            fieldbackground="#ffffff",
            bordercolor="#c0bfbc",
            padding=5,
        )

        self.style.configure(
            "TNotebook",
            background="#f6f5f4",
            borderwidth=0,
        )
        self.style.configure(
            "TNotebook.Tab",
            background="#deddda",
            foreground="#241f31",
            padding=(16, 9),
        )
        self.style.map(
            "TNotebook.Tab",
            background=[
                ("selected", "#ffffff"),
                ("active", "#eeeeec"),
            ],
        )

        self.style.configure(
            "Treeview",
            background="#ffffff",
            fieldbackground="#ffffff",
            foreground="#241f31",
            borderwidth=0,
            rowheight=32,
        )
        self.style.configure(
            "Treeview.Heading",
            background="#deddda",
            foreground="#241f31",
            font=("Cantarell", 10, "bold"),
            padding=8,
        )
        self.style.map(
            "Treeview",
            background=[
                ("selected", "#3584e4"),
            ],
            foreground=[
                ("selected", "#ffffff"),
            ],
        )

    def _build_layout(self):

        self.columnconfigure(1, weight=1)
        self.rowconfigure(0, weight=1)
        self.rowconfigure(1, weight=0)

        sidebar = ttk.Frame(
            self,
            padding=18,
            style="Sidebar.TFrame",
        )
        sidebar.grid(row=0, column=0, sticky="ns")
        sidebar.grid_propagate(False)
        sidebar.configure(width=220)

        ttk.Label(
            sidebar,
            text="Solar Manager",
            style="Title.TLabel",
        ).pack(anchor="w", pady=(0, 20))

        ttk.Label(
            sidebar,
            text="Orçamentos solares offline",
            style="Subtitle.TLabel",
            wraplength=170,
        ).pack(anchor="w", pady=(0, 22))

        ttk.Button(
            sidebar,
            text="Atualizar",
            command=self.refresh_all,
            style="Primary.TButton",
        ).pack(fill="x")

        main = ttk.Frame(
            self,
            padding=18,
            style="App.TFrame",
        )
        main.grid(row=0, column=1, sticky="nsew")
        main.columnconfigure(0, weight=1)
        main.rowconfigure(2, weight=1)

        header = ttk.Frame(
            main,
            style="App.TFrame",
        )
        header.grid(row=0, column=0, sticky="ew", pady=(0, 14))
        header.columnconfigure(0, weight=1)

        ttk.Label(
            header,
            text="Painel de Orçamentos",
            style="Header.TLabel",
        ).grid(row=0, column=0, sticky="w")

        ttk.Label(
            header,
            text="Clientes, dimensionamentos e acompanhamento comercial em um app offline.",
            style="Muted.TLabel",
        ).grid(row=1, column=0, sticky="w", pady=(3, 0))

        self.dashboard_frame = ttk.Frame(
            main,
            style="App.TFrame",
        )
        self.dashboard_frame.grid(row=1, column=0, sticky="ew")

        self.notebook = ttk.Notebook(main)
        self.notebook.grid(row=2, column=0, sticky="nsew", pady=(14, 0))

        self.dashboard_tab = ttk.Frame(
            self.notebook,
            padding=16,
            style="App.TFrame",
        )
        self.clients_tab = ttk.Frame(
            self.notebook,
            padding=16,
            style="App.TFrame",
        )
        self.budget_tab = ttk.Frame(
            self.notebook,
            padding=16,
            style="App.TFrame",
        )
        self.finance_tab = ttk.Frame(
            self.notebook,
            padding=16,
            style="App.TFrame",
        )
        self.charts_tab = ttk.Frame(
            self.notebook,
            padding=16,
            style="App.TFrame",
        )
        self.history_tab = ttk.Frame(
            self.notebook,
            padding=16,
            style="App.TFrame",
        )

        self.notebook.add(self.dashboard_tab, text="Dashboard")
        self.notebook.add(self.clients_tab, text="Clientes")
        self.notebook.add(self.budget_tab, text="Dimensionamento")
        self.notebook.add(self.finance_tab, text="Financiamento")
        self.notebook.add(self.charts_tab, text="Gráficos")
        self.notebook.add(self.history_tab, text="Orçamentos")

        self._build_dashboard()
        self._build_dashboard_tab()
        self._build_clients_tab()
        self._build_budget_tab()
        self._build_finance_tab()
        self._build_charts_tab()
        self._build_history_tab()

        self.status_bar = ttk.Label(
            self,
            text="Pronto",
            anchor="w",
            padding=(10, 5),
            style="Status.TLabel",
        )
        self.status_bar.grid(row=1, column=0, columnspan=2, sticky="ew")

    def _build_dashboard(self):

        self.metric_labels = {}

        metrics = [
            ("budget_count", "Orçamentos"),
            ("forecast_revenue", "Receita prevista"),
            ("conversion_rate", "Conversão"),
        ]

        for index, (key, label) in enumerate(metrics):

            card = ttk.Frame(
                self.dashboard_frame,
                padding=9,
                style="Card.TFrame",
            )
            card.grid(
                row=0,
                column=index,
                sticky="ew",
                padx=(0, 8),
            )

            ttk.Label(
                card,
                text=label,
                style="CardLabel.TLabel",
            ).pack(anchor="w")

            value = ttk.Label(
                card,
                text="0",
                style="Metric.TLabel",
            )
            value.pack(anchor="w")

            self.metric_labels[key] = value

        for column in range(3):

            self.dashboard_frame.columnconfigure(column, weight=1)

    def _build_dashboard_tab(self):

        self.dashboard_tab.columnconfigure(0, weight=1)
        self.dashboard_tab.rowconfigure(1, weight=1)

        header = ttk.Frame(
            self.dashboard_tab,
            padding=12,
            style="Card.TFrame",
        )
        header.grid(row=0, column=0, sticky="ew", pady=(0, 12))
        header.columnconfigure(0, weight=1)

        ttk.Label(
            header,
            text="Dashboard comercial",
            style="DashboardTitle.TLabel",
        ).grid(row=0, column=0, sticky="w")

        ttk.Label(
            header,
            text="Resumo de status, receita e potência dos orçamentos.",
            style="CardLabel.TLabel",
        ).grid(row=1, column=0, sticky="w", pady=(3, 0))

        self.dashboard_canvas = tk.Canvas(
            self.dashboard_tab,
            background="#ffffff",
            highlightthickness=1,
            highlightbackground="#c0bfbc",
        )
        self.dashboard_canvas.grid(row=1, column=0, sticky="nsew")
        self.dashboard_canvas.bind(
            "<Configure>",
            lambda event: self.draw_dashboard()
        )

    def draw_dashboard(self):

        if not hasattr(self, "dashboard_canvas"):

            return

        canvas = self.dashboard_canvas
        canvas.delete("all")

        width = max(canvas.winfo_width(), 420)
        height = max(canvas.winfo_height(), 300)
        padding = 28
        gap = 24
        panel_width = (width - (padding * 2) - gap) / 2
        panel_height = max((height - (padding * 2) - gap) / 2, 120)

        if not self.budgets:

            canvas.create_text(
                padding,
                padding,
                anchor="nw",
                text="Crie orçamentos para preencher o dashboard.",
                fill="#5e5c64",
                font=("Cantarell", 12),
            )
            return

        status_counts = {
            status: 0
            for status in STATUSES
        }
        status_values = {
            status: 0
            for status in STATUSES
        }
        total_power = 0

        for budget in self.budgets:

            status = budget["status"]
            if status not in status_counts:

                continue

            value = budget["investment"] or 0
            status_counts[status] += 1
            status_values[status] += value
            total_power += budget["system_power"] or 0

        self._draw_status_panel(
            canvas,
            padding,
            padding,
            panel_width,
            panel_height,
            status_counts,
        )
        self._draw_value_panel(
            canvas,
            padding + panel_width + gap,
            padding,
            panel_width,
            panel_height,
            status_values,
        )
        self._draw_power_panel(
            canvas,
            padding,
            padding + panel_height + gap,
            panel_width,
            panel_height,
            total_power,
        )
        self._draw_recent_panel(
            canvas,
            padding + panel_width + gap,
            padding + panel_height + gap,
            panel_width,
            panel_height,
        )

    def _draw_panel_title(self, canvas, x, y, title, subtitle):

        canvas.create_text(
            x,
            y,
            anchor="nw",
            text=title,
            fill="#241f31",
            font=("Cantarell", 13, "bold"),
        )
        canvas.create_text(
            x,
            y + 24,
            anchor="nw",
            text=subtitle,
            fill="#5e5c64",
            font=("Cantarell", 9),
        )

    def _draw_status_panel(self, canvas, x, y, width, height, status_counts):

        self._draw_panel_title(
            canvas,
            x,
            y,
            "Funil de status",
            "Quantidade de orçamentos por etapa",
        )

        colors = {
            "Em negociação": "#f6d32d",
            "Fechado": "#3584e4",
            "Concluído": "#33d17a",
        }
        max_count = max(status_counts.values()) or 1
        top = y + 58
        row_height = min(34, max(24, (height - 70) / 3))
        bar_left = x + 112
        bar_width = max(width - 154, 80)

        for index, status in enumerate(STATUSES):

            row_y = top + (index * row_height)
            value = status_counts[status]
            filled_width = (value / max_count) * bar_width

            canvas.create_text(
                x,
                row_y + 8,
                anchor="nw",
                text=status,
                fill="#241f31",
                font=("Cantarell", 9),
            )
            canvas.create_rectangle(
                bar_left,
                row_y + 4,
                bar_left + bar_width,
                row_y + 22,
                fill="#eeeeec",
                outline="#eeeeec",
            )
            canvas.create_rectangle(
                bar_left,
                row_y + 4,
                bar_left + filled_width,
                row_y + 22,
                fill=colors[status],
                outline=colors[status],
            )
            canvas.create_text(
                bar_left + bar_width + 10,
                row_y + 5,
                anchor="nw",
                text=str(value),
                fill="#241f31",
                font=("Cantarell", 10, "bold"),
            )

    def _draw_value_panel(self, canvas, x, y, width, height, status_values):

        self._draw_panel_title(
            canvas,
            x,
            y,
            "Receita por status",
            "Valores dos projetos cadastrados",
        )

        colors = {
            "Em negociação": "#f6d32d",
            "Fechado": "#3584e4",
            "Concluído": "#33d17a",
        }
        max_value = max(status_values.values()) or 1
        chart_top = y + 58
        chart_height = max(height - 96, 70)
        bar_area = max(width - 28, 180)
        bar_width = min(42, bar_area / 5)

        for index, status in enumerate(STATUSES):

            center = x + 48 + (index * (bar_area / 3))
            value = status_values[status]
            bar_height = (value / max_value) * chart_height
            base_y = chart_top + chart_height

            canvas.create_rectangle(
                center - (bar_width / 2),
                base_y - bar_height,
                center + (bar_width / 2),
                base_y,
                fill=colors[status],
                outline=colors[status],
            )
            canvas.create_text(
                center,
                base_y + 12,
                text=status.split()[0],
                fill="#5e5c64",
                font=("Cantarell", 8),
            )
            canvas.create_text(
                center,
                max(chart_top, base_y - bar_height - 16),
                text=self._format_compact_currency(value),
                fill="#241f31",
                font=("Cantarell", 9, "bold"),
            )

    def _draw_power_panel(self, canvas, x, y, width, height, total_power):

        self._draw_panel_title(
            canvas,
            x,
            y,
            "Potência acumulada",
            "Soma dos sistemas dimensionados",
        )
        canvas.create_text(
            x,
            y + 66,
            anchor="nw",
            text=f"{total_power:.2f} kWp",
            fill="#241f31",
            font=("Cantarell", 26, "bold"),
        )
        canvas.create_text(
            x,
            y + 108,
            anchor="nw",
            text=f"{len(self.budgets)} orçamentos cadastrados",
            fill="#5e5c64",
            font=("Cantarell", 10),
        )

    def _draw_recent_panel(self, canvas, x, y, width, height):

        self._draw_panel_title(
            canvas,
            x,
            y,
            "Últimos orçamentos",
            "Clientes mais recentes no pipeline",
        )

        top = y + 58
        row_height = 24

        for index, budget in enumerate(self.budgets[:5]):

            row_y = top + (index * row_height)
            value = budget["investment"] or 0
            client_name = budget["client_name"]

            if len(client_name) > 24:

                client_name = f"{client_name[:21]}..."

            text = (
                f"#{budget['id']} {client_name} - "
                f"{budget['status']} - {self._format_compact_currency(value)}"
            )
            canvas.create_text(
                x,
                row_y,
                anchor="nw",
                text=text,
                fill="#241f31",
                font=("Cantarell", 9),
            )

    def _format_compact_currency(self, value):

        if value >= 1000000:

            return f"R$ {value / 1000000:.1f} mi"

        if value >= 1000:

            return f"R$ {value / 1000:.1f} mil"

        return f"R$ {value:.0f}"

    def _build_clients_tab(self):

        form = ttk.LabelFrame(
            self.clients_tab,
            text="Cadastrar Cliente",
            padding=12,
            style="Panel.TLabelframe",
        )
        form.pack(fill="x")

        self.client_fields = {}

        fields = [
            ("name", "Nome"),
            ("document", "CPF/CNPJ"),
            ("phone", "Telefone"),
            ("email", "Email"),
            ("city", "Cidade"),
            ("state", "Estado"),
        ]

        for index, (key, label) in enumerate(fields):

            ttk.Label(form, text=label).grid(
                row=0,
                column=index,
                sticky="w",
                padx=(0, 8),
            )

            entry = ttk.Entry(form, width=22)
            entry.grid(
                row=1,
                column=index,
                sticky="ew",
                padx=(0, 8),
            )

            self.client_fields[key] = entry

        form.columnconfigure(0, weight=1)
        form.columnconfigure(1, weight=1)
        form.columnconfigure(2, weight=1)
        form.columnconfigure(3, weight=1)
        form.columnconfigure(4, weight=1)
        form.columnconfigure(5, weight=1)

        ttk.Button(
            form,
            text="Salvar Cliente",
            command=self.save_client,
            style="Primary.TButton",
        ).grid(row=1, column=len(fields), sticky="ew")

        ttk.Button(
            form,
            text="Limpar",
            command=self.clear_client_form,
        ).grid(row=1, column=len(fields) + 1, sticky="ew", padx=(8, 0))

        self.clients_tree = ttk.Treeview(
            self.clients_tab,
            columns=("name", "document", "phone", "email", "city", "state"),
            show="headings",
            height=14,
        )

        headings = {
            "name": "Nome",
            "document": "CPF/CNPJ",
            "phone": "Telefone",
            "email": "Email",
            "city": "Cidade",
            "state": "Estado",
        }

        for column, heading in headings.items():

            self.clients_tree.heading(column, text=heading)
            self.clients_tree.column(column, width=145)

        self.clients_tree.pack(fill="both", expand=True, pady=(14, 0))

    def _build_budget_tab(self):

        self.budget_canvas = tk.Canvas(
            self.budget_tab,
            background="#f6f5f4",
            highlightthickness=0,
        )
        budget_scrollbar = ttk.Scrollbar(
            self.budget_tab,
            orient="vertical",
            command=self.budget_canvas.yview,
        )
        self.budget_canvas.configure(
            yscrollcommand=budget_scrollbar.set
        )

        self.budget_canvas.pack(
            side="left",
            fill="both",
            expand=True,
        )
        budget_scrollbar.pack(
            side="right",
            fill="y",
        )

        container = ttk.Frame(
            self.budget_canvas,
            style="App.TFrame",
        )
        budget_window = self.budget_canvas.create_window(
            (0, 0),
            window=container,
            anchor="nw",
        )

        container.bind(
            "<Configure>",
            lambda event: self.budget_canvas.configure(
                scrollregion=self.budget_canvas.bbox("all")
            ),
        )
        self.budget_canvas.bind(
            "<Configure>",
            lambda event: self.budget_canvas.itemconfigure(
                budget_window,
                width=event.width,
            ),
        )
        self.budget_canvas.bind_all(
            "<MouseWheel>",
            self._scroll_budget_tab,
        )
        self.budget_canvas.bind_all(
            "<Button-4>",
            self._scroll_budget_tab,
        )
        self.budget_canvas.bind_all(
            "<Button-5>",
            self._scroll_budget_tab,
        )

        container.columnconfigure(0, weight=1)
        container.columnconfigure(1, weight=1)

        form = ttk.LabelFrame(
            container,
            text="Dados do Orçamento",
            padding=12,
            style="Panel.TLabelframe",
        )
        form.grid(row=0, column=0, sticky="nsew", padx=(0, 12))

        self.client_select = ttk.Combobox(
            form,
            state="readonly",
            width=35,
        )

        self.budget_status = ttk.Combobox(
            form,
            values=STATUSES,
            state="readonly",
            width=20,
        )
        self.budget_status.set("Em negociação")

        self.budget_fields = {}
        self.monthly_consumption_fields = []
        self.monthly_hsp_fields = []

        fields = [
            ("client", "Cliente", self.client_select),
            ("budget_date", "Data", ttk.Entry(form)),
            ("status", "Status", self.budget_status),
            ("performance_ratio", "Rendimento", ttk.Entry(form)),
            ("module_power", "Potência módulo W", ttk.Entry(form)),
            ("energy_tariff", "Tarifa energia", ttk.Entry(form)),
            ("generation_extra_percent", "% extra de geração", ttk.Entry(form)),
        ]

        defaults = {
            "budget_date": str(date.today()),
            "performance_ratio": "0.8",
            "module_power": "550",
            "energy_tariff": "0.95",
            "generation_extra_percent": "0",
        }

        for row, (key, label, widget) in enumerate(fields):

            ttk.Label(form, text=label).grid(
                row=row,
                column=0,
                sticky="w",
                pady=4,
            )

            widget.grid(
                row=row,
                column=1,
                sticky="ew",
                pady=4,
            )

            if key in defaults:

                widget.insert(0, defaults[key])

            self.budget_fields[key] = widget

        form.columnconfigure(1, weight=1)

        ttk.Button(
            form,
            text="Calcular e Salvar Orçamento",
            command=self.save_budget,
            style="Primary.TButton",
        ).grid(row=len(fields), column=0, columnspan=2, sticky="ew", pady=(12, 0))

        ttk.Button(
            form,
            text="Limpar Formulário",
            command=self.clear_budget_form,
        ).grid(row=len(fields) + 1, column=0, columnspan=2, sticky="ew", pady=(8, 0))

        monthly_panel = ttk.LabelFrame(
            container,
            text="Consumo e HSP mês a mês",
            padding=12,
            style="Panel.TLabelframe",
        )
        monthly_panel.grid(row=0, column=1, sticky="nsew")

        ttk.Label(monthly_panel, text="Mês").grid(
            row=0,
            column=0,
            sticky="w",
            padx=(0, 8),
        )
        ttk.Label(monthly_panel, text="Consumo kWh").grid(
            row=0,
            column=1,
            sticky="w",
            padx=(0, 8),
        )
        ttk.Label(monthly_panel, text="HSP").grid(
            row=0,
            column=2,
            sticky="w",
        )

        for row, month in enumerate(MONTHS, start=1):

            ttk.Label(monthly_panel, text=month).grid(
                row=row,
                column=0,
                sticky="w",
                pady=2,
                padx=(0, 8),
            )

            consumption_entry = ttk.Entry(monthly_panel, width=14)
            consumption_entry.insert(0, "0")
            consumption_entry.grid(
                row=row,
                column=1,
                sticky="ew",
                pady=2,
                padx=(0, 8),
            )

            hsp_entry = ttk.Entry(monthly_panel, width=10)
            hsp_entry.insert(0, "5.5")
            hsp_entry.grid(
                row=row,
                column=2,
                sticky="ew",
                pady=2,
            )

            self.monthly_consumption_fields.append(consumption_entry)
            self.monthly_hsp_fields.append(hsp_entry)

        monthly_panel.columnconfigure(1, weight=1)
        monthly_panel.columnconfigure(2, weight=1)

        result = ttk.LabelFrame(
            container,
            text="Resultado",
            padding=12,
            style="Panel.TLabelframe",
        )
        result.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(12, 0))
        result.columnconfigure(1, weight=1)
        result.columnconfigure(3, weight=1)

        self.result_labels = {}

        result_fields = [
            ("average_consumption", "Consumo médio"),
            ("average_hsp", "HSP médio"),
            ("annual_consumption", "Consumo anual"),
            ("system_power", "Potência do sistema"),
            ("module_count", "Quantidade de módulos"),
            ("annual_generation", "Geração anual"),
            ("monthly_generation", "Geração média mensal"),
            ("monthly_savings", "Economia mensal"),
        ]

        for index, (key, label) in enumerate(result_fields):

            row = index // 2
            label_column = (index % 2) * 2
            value_column = label_column + 1

            ttk.Label(result, text=label).grid(
                row=row,
                column=label_column,
                sticky="w",
                pady=8,
                padx=(0, 8),
            )

            value = ttk.Label(
                result,
                text="-",
                font=("Cantarell", 12, "bold"),
            )
            value.grid(
                row=row,
                column=value_column,
                sticky="w",
                pady=8,
                padx=(0, 16),
            )

            self.result_labels[key] = value

        self.monthly_result_tree = ttk.Treeview(
            result,
            columns=("month", "consumption", "hsp", "generation", "balance"),
            show="headings",
            height=6,
        )

        monthly_headings = {
            "month": "Mês",
            "consumption": "Consumo",
            "hsp": "HSP",
            "generation": "Geração",
            "balance": "Saldo",
        }

        for column, heading in monthly_headings.items():

            self.monthly_result_tree.heading(column, text=heading)
            self.monthly_result_tree.column(column, width=120)

        self.monthly_result_tree.grid(
            row=(len(result_fields) + 1) // 2,
            column=0,
            columnspan=4,
            sticky="ew",
            pady=(10, 0),
        )

    def _scroll_budget_tab(self, event):

        if self.notebook.select() == str(self.budget_tab):

            if getattr(event, "num", None) == 4:

                direction = -1

            elif getattr(event, "num", None) == 5:

                direction = 1

            else:

                direction = int(-1 * (event.delta / 120))

            self.budget_canvas.yview_scroll(
                direction,
                "units",
            )

    def _build_finance_tab(self):

        container = ttk.Frame(
            self.finance_tab,
            style="App.TFrame",
        )
        container.pack(fill="both", expand=True)
        container.columnconfigure(0, weight=1)
        container.columnconfigure(1, weight=1)

        form = ttk.LabelFrame(
            container,
            text="Simulação de Financiamento",
            padding=12,
            style="Panel.TLabelframe",
        )
        form.grid(row=0, column=0, sticky="nsew", padx=(0, 12))

        self.finance_budget_select = ttk.Combobox(
            form,
            state="readonly",
            width=46,
        )
        self.finance_budget_select.bind(
            "<<ComboboxSelected>>",
            lambda event: self._load_selected_budget_finance()
        )

        self.finance_fields = {
            "project_value": ttk.Entry(form),
            "down_payment": ttk.Entry(form),
            "monthly_interest_rate": ttk.Entry(form),
            "term_months": ttk.Entry(form),
        }

        self.finance_fields["project_value"].insert(0, "18000")
        self.finance_fields["down_payment"].insert(0, "0")
        self.finance_fields["monthly_interest_rate"].insert(0, "1.5")
        self.finance_fields["term_months"].insert(0, "60")

        fields = [
            ("Orçamento", self.finance_budget_select),
            ("Valor do projeto R$", self.finance_fields["project_value"]),
            ("Entrada R$", self.finance_fields["down_payment"]),
            ("Taxa mensal %", self.finance_fields["monthly_interest_rate"]),
            ("Prazo meses", self.finance_fields["term_months"]),
        ]

        for row, (label, widget) in enumerate(fields):

            ttk.Label(form, text=label).grid(
                row=row,
                column=0,
                sticky="w",
                pady=6,
            )
            widget.grid(
                row=row,
                column=1,
                sticky="ew",
                pady=6,
            )

        form.columnconfigure(1, weight=1)

        ttk.Button(
            form,
            text="Calcular e Salvar Financiamento",
            command=self.save_financing,
            style="Primary.TButton",
        ).grid(row=len(fields), column=0, columnspan=2, sticky="ew", pady=(12, 0))

        result = ttk.LabelFrame(
            container,
            text="Resultado Financeiro",
            padding=12,
            style="Panel.TLabelframe",
        )
        result.grid(row=0, column=1, sticky="nsew")

        self.finance_result_labels = {}

        result_fields = [
            ("project_value", "Valor do projeto"),
            ("financed_amount", "Valor financiado"),
            ("monthly_payment", "Parcela estimada"),
            ("total_paid", "Total pago"),
            ("total_interest", "Juros total"),
            ("payback_years", "Payback"),
        ]

        for row, (key, label) in enumerate(result_fields):

            ttk.Label(result, text=label).grid(
                row=row,
                column=0,
                sticky="w",
                pady=8,
            )

            value = ttk.Label(
                result,
                text="-",
                font=("Cantarell", 12, "bold"),
            )
            value.grid(
                row=row,
                column=1,
                sticky="w",
                pady=8,
            )

            self.finance_result_labels[key] = value

    def save_financing(self):

        if not self.budgets:

            messagebox.showerror(
                "Financiamento",
                "Crie um orçamento antes de simular financiamento.",
            )
            self._set_status("Nenhum orçamento disponível para financiamento.")
            return

        try:

            selected_index = self.finance_budget_select.current()
            budget = self.budgets[selected_index]

            project_value = float(
                self.finance_fields["project_value"].get()
            )
            down_payment = float(
                self.finance_fields["down_payment"].get()
            )
            monthly_interest_rate = float(
                self.finance_fields["monthly_interest_rate"].get()
            )
            term_months = int(
                self.finance_fields["term_months"].get()
            )

        except (ValueError, IndexError):

            messagebox.showerror(
                "Financiamento",
                "Revise entrada, taxa e prazo.",
            )
            self._set_status("Erro nos dados de financiamento.")
            return

        if (
            project_value <= 0
            or down_payment < 0
            or monthly_interest_rate < 0
            or term_months <= 0
        ):

            messagebox.showerror(
                "Financiamento",
                "Valor do projeto e prazo devem ser maiores que zero. Entrada e taxa não podem ser negativas.",
            )
            self._set_status("Financiamento com valores inválidos.")
            return

        if down_payment > project_value:

            messagebox.showerror(
                "Financiamento",
                "Entrada não pode ser maior que o valor do projeto.",
            )
            self._set_status("Entrada maior que o projeto.")
            return

        results = calculate_financing(
            project_value,
            down_payment,
            monthly_interest_rate,
            term_months,
            budget["monthly_savings"],
        )

        update_budget_financing(
            budget["id"],
            project_value,
            down_payment,
            monthly_interest_rate,
            term_months,
            results,
        )

        self._show_financing_results(
            budget,
            results,
        )
        self.refresh_all()
        self._set_status("Financiamento salvo no orçamento.")

    def _show_financing_results(self, budget, results):

        self.finance_result_labels["project_value"].configure(
            text=f"R$ {results['project_value']:.2f}"
            if "project_value" in results
            else "-"
        )
        self.finance_result_labels["financed_amount"].configure(
            text=f"R$ {results['financed_amount']:.2f}"
        )
        self.finance_result_labels["monthly_payment"].configure(
            text=f"R$ {results['monthly_payment']:.2f}"
        )
        self.finance_result_labels["total_paid"].configure(
            text=f"R$ {results['total_paid']:.2f}"
        )
        self.finance_result_labels["total_interest"].configure(
            text=f"R$ {results['total_interest']:.2f}"
        )
        self.finance_result_labels["payback_years"].configure(
            text=f"{results['payback_years']:.2f} anos"
        )

    def _build_charts_tab(self):

        toolbar = ttk.Frame(
            self.charts_tab,
            style="App.TFrame",
        )
        toolbar.pack(fill="x")

        ttk.Label(toolbar, text="Orçamento:").pack(
            side="left"
        )

        self.chart_budget_select = ttk.Combobox(
            toolbar,
            state="readonly",
            width=48,
        )
        self.chart_budget_select.pack(
            side="left",
            padx=(8, 12),
        )
        self.chart_budget_select.bind(
            "<<ComboboxSelected>>",
            lambda event: self.draw_generation_chart()
        )

        ttk.Button(
            toolbar,
            text="Atualizar Gráfico",
            command=self.draw_generation_chart,
            style="Primary.TButton",
        ).pack(side="left")

        legend = ttk.Frame(
            self.charts_tab,
            style="App.TFrame",
        )
        legend.pack(fill="x", pady=(12, 6))

        self._legend_item(legend, "#3584e4", "Consumo")
        self._legend_item(legend, "#33d17a", "Geração")
        self._legend_item(legend, "#f6d32d", "Saldo positivo")
        self._legend_item(legend, "#e01b24", "Saldo negativo")

        self.chart_canvas = tk.Canvas(
            self.charts_tab,
            background="#ffffff",
            highlightthickness=1,
            highlightbackground="#c0bfbc",
        )
        self.chart_canvas.pack(
            fill="both",
            expand=True,
        )
        self.chart_canvas.bind(
            "<Configure>",
            lambda event: self.draw_generation_chart()
        )

    def _legend_item(self, parent, color, text):

        item = ttk.Frame(
            parent,
            style="App.TFrame",
        )
        item.pack(side="left", padx=(0, 18))

        sample = tk.Canvas(
            item,
            width=14,
            height=14,
            background="#f6f5f4",
            highlightthickness=0,
        )
        sample.create_rectangle(
            1,
            1,
            13,
            13,
            fill=color,
            outline=color,
        )
        sample.pack(side="left")

        ttk.Label(item, text=text).pack(
            side="left",
            padx=(5, 0),
        )

    def draw_generation_chart(self):

        if not hasattr(self, "chart_canvas"):

            return

        self.chart_canvas.delete("all")

        if not self.budgets:

            self.chart_canvas.create_text(
                30,
                30,
                anchor="nw",
                text="Crie um orçamento para visualizar o gráfico.",
                fill="#5e5c64",
                font=("Cantarell", 12),
            )
            return

        selected_index = self.chart_budget_select.current()

        if selected_index < 0:

            selected_index = 0

        budget = self.budgets[selected_index]

        try:

            consumptions = json.loads(
                budget["monthly_consumptions"] or "[]"
            )
            generations = json.loads(
                budget["monthly_generations"] or "[]"
            )
            balances = json.loads(
                budget["monthly_balances"] or "[]"
            )

        except (TypeError, json.JSONDecodeError):

            consumptions = []
            generations = []
            balances = []

        if len(consumptions) != 12 or len(generations) != 12:

            self.chart_canvas.create_text(
                30,
                30,
                anchor="nw",
                text="Este orçamento não possui dados mensais para o gráfico.",
                fill="#5e5c64",
                font=("Cantarell", 12),
            )
            return

        width = max(self.chart_canvas.winfo_width(), 320)
        height = max(self.chart_canvas.winfo_height(), 260)
        left = 58
        right = 18
        top = 40
        bottom = 78
        chart_width = width - left - right
        chart_height = height - top - bottom

        if chart_width < 240 or chart_height < 120:

            self.chart_canvas.create_text(
                20,
                20,
                anchor="nw",
                text="Aumente a janela para visualizar o gráfico.",
                fill="#5e5c64",
                font=("Cantarell", 12),
            )
            return

        max_value = max(
            consumptions + generations + [abs(value) for value in balances]
        )
        if max_value <= 0:
            max_value = 1

        self.chart_canvas.create_text(
            left,
            18,
            anchor="w",
            text=(
                f"Consumo x Geração - #{budget['id']} "
                f"{budget['client_name']}"
            ),
            fill="#241f31",
            font=("Cantarell", 13, "bold"),
        )

        self.chart_canvas.create_line(
            left,
            top,
            left,
            top + chart_height,
            fill="#c0bfbc",
        )
        self.chart_canvas.create_line(
            left,
            top + chart_height,
            left + chart_width,
            top + chart_height,
            fill="#c0bfbc",
        )

        for index in range(5):

            value = max_value * index / 4
            y = top + chart_height - (
                value / max_value * chart_height
            )

            self.chart_canvas.create_line(
                left,
                y,
                left + chart_width,
                y,
                fill="#eeeeec",
            )
            self.chart_canvas.create_text(
                left - 8,
                y,
                anchor="e",
                text=f"{value:.0f}",
                fill="#5e5c64",
                font=("Cantarell", 8),
            )

        group_width = chart_width / 12
        bar_width = max(4, min(16, group_width / 5))

        for index, month in enumerate(MONTHS):

            center = left + (group_width * index) + (group_width / 2)

            consumption_height = (
                consumptions[index] / max_value * chart_height
            )
            generation_height = (
                generations[index] / max_value * chart_height
            )
            balance_height = (
                abs(balances[index]) / max_value * chart_height
            )

            base_y = top + chart_height

            self._draw_bar(
                center - (bar_width * 1.4),
                base_y,
                bar_width,
                consumption_height,
                "#3584e4",
            )
            self._draw_bar(
                center,
                base_y,
                bar_width,
                generation_height,
                "#33d17a",
            )
            self._draw_bar(
                center + (bar_width * 1.4),
                base_y,
                bar_width,
                balance_height,
                "#f6d32d" if balances[index] >= 0 else "#e01b24",
            )

            self.chart_canvas.create_text(
                center,
                base_y + 18,
                text=month,
                fill="#5e5c64",
                font=("Cantarell", 8),
            )

        summary = (
            f"Consumo anual: {budget['annual_consumption']:.0f} kWh  |  "
            f"Geração anual: {budget['annual_generation']:.0f} kWh  |  "
            f"Saldo anual: {(budget['annual_generation'] - budget['annual_consumption']):.0f} kWh"
        )
        self.chart_canvas.create_text(
            left,
            height - 18,
            anchor="w",
            text=summary,
            fill="#241f31",
            font=("Cantarell", 10, "bold"),
        )

    def _draw_bar(self, x, base_y, width, height, color):

        self.chart_canvas.create_rectangle(
            x - (width / 2),
            base_y - height,
            x + (width / 2),
            base_y,
            fill=color,
            outline=color,
        )

    def _build_history_tab(self):

        toolbar = ttk.Frame(
            self.history_tab,
            style="App.TFrame",
        )
        toolbar.pack(fill="x")

        ttk.Label(toolbar, text="Buscar:").pack(
            side="left"
        )

        self.history_search = ttk.Entry(toolbar, width=28)
        self.history_search.pack(side="left", padx=(8, 16))
        self.history_search.bind(
            "<KeyRelease>",
            lambda event: self._refresh_budgets()
        )

        ttk.Label(toolbar, text="Filtrar status:").pack(
            side="left"
        )

        self.history_filter = ttk.Combobox(
            toolbar,
            values=["Todos"] + STATUSES,
            state="readonly",
            width=18,
        )
        self.history_filter.set("Todos")
        self.history_filter.pack(side="left", padx=(8, 16))
        self.history_filter.bind(
            "<<ComboboxSelected>>",
            lambda event: self._refresh_budgets()
        )

        ttk.Label(toolbar, text="Alterar status selecionado:").pack(
            side="left"
        )

        self.history_status = ttk.Combobox(
            toolbar,
            values=STATUSES,
            state="readonly",
            width=18,
        )
        self.history_status.set("Em negociação")
        self.history_status.pack(side="left", padx=8)

        ttk.Button(
            toolbar,
            text="Salvar Status",
            command=self.change_selected_budget_status,
            style="Primary.TButton",
        ).pack(side="left")

        self.budgets_tree = ttk.Treeview(
            self.history_tab,
            columns=(
                "date",
                "client",
                "status",
                "power",
                "modules",
                "annual_generation",
                "investment",
                "monthly_payment",
                "savings",
                "payback",
            ),
            show="headings",
            height=18,
        )

        headings = {
            "date": "Data",
            "client": "Cliente",
            "status": "Status",
            "power": "kWp",
            "modules": "Módulos",
            "annual_generation": "Geração anual",
            "investment": "Valor do projeto",
            "monthly_payment": "Parcela",
            "savings": "Economia mensal",
            "payback": "Payback",
        }

        for column, heading in headings.items():

            self.budgets_tree.heading(column, text=heading)
            self.budgets_tree.column(column, width=130)

        self.budgets_tree.pack(fill="both", expand=True, pady=(12, 0))
        self.budgets_tree.tag_configure(
            "Em negociação",
            background="#fff7d6",
        )
        self.budgets_tree.tag_configure(
            "Fechado",
            background="#e5f3ff",
        )
        self.budgets_tree.tag_configure(
            "Concluído",
            background="#e8f7e4",
        )

    def save_client(self):

        values = {
            key: field.get().strip()
            for key, field in self.client_fields.items()
        }

        if any(not value for value in values.values()):

            messagebox.showerror(
                "Cliente",
                "Preencha todos os campos do cliente.",
            )
            self._set_status("Cadastro de cliente incompleto.")
            return

        if not validate_document(values["document"]):

            messagebox.showerror(
                "Cliente",
                "Informe um CPF ou CNPJ válido.",
            )
            self._set_status("CPF/CNPJ inválido.")
            return

        if not validate_phone(values["phone"]):

            messagebox.showerror(
                "Cliente",
                "Telefone deve conter 10 ou 11 números.",
            )
            self._set_status("Telefone inválido.")
            return

        if not validate_email(values["email"]):

            messagebox.showerror(
                "Cliente",
                "Informe um email válido.",
            )
            self._set_status("Email inválido.")
            return

        create_client(
            values["name"],
            only_digits(values["document"]),
            only_digits(values["phone"]),
            values["email"].strip().lower(),
            values["city"],
            values["state"],
        )

        self.clear_client_form()

        self.refresh_all()
        self._set_status("Cliente cadastrado com sucesso.")

        messagebox.showinfo(
            "Cliente",
            "Cliente cadastrado com sucesso.",
        )

    def clear_client_form(self):

        for field in self.client_fields.values():

            field.delete(0, tk.END)

    def save_budget(self):

        if not self.clients:

            messagebox.showerror(
                "Orçamento",
                "Cadastre um cliente antes de criar orçamento.",
            )
            self._set_status("Nenhum cliente disponível para orçamento.")
            return

        try:

            selected_index = self.client_select.current()
            client_id = self.clients[selected_index]["id"]

            monthly_consumptions = [
                float(field.get())
                for field in self.monthly_consumption_fields
            ]
            monthly_hsp = [
                float(field.get())
                for field in self.monthly_hsp_fields
            ]

            inputs = {
                "monthly_consumptions": monthly_consumptions,
                "monthly_hsp": monthly_hsp,
                "performance_ratio": float(
                    self.budget_fields["performance_ratio"].get()
                ),
                "module_power": float(
                    self.budget_fields["module_power"].get()
                ),
                "energy_tariff": float(
                    self.budget_fields["energy_tariff"].get()
                ),
                "generation_extra_percent": float(
                    self.budget_fields["generation_extra_percent"].get()
                ),
            }

        except (ValueError, IndexError):

            messagebox.showerror(
                "Orçamento",
                "Revise os campos numéricos do orçamento.",
            )
            self._set_status("Erro nos campos numéricos do orçamento.")
            return

        numeric_values = (
            inputs["monthly_consumptions"]
            + inputs["monthly_hsp"]
            + [
                inputs["performance_ratio"],
                inputs["module_power"],
                inputs["energy_tariff"],
            ]
        )

        if any(value <= 0 for value in numeric_values):

            messagebox.showerror(
                "Orçamento",
                "Os valores do orçamento devem ser maiores que zero.",
            )
            self._set_status("Orçamento com valores inválidos.")
            return

        if inputs["generation_extra_percent"] < 0:

            messagebox.showerror(
                "Orçamento",
                "O percentual extra de geração não pode ser negativo.",
            )
            self._set_status("Percentual extra inválido.")
            return

        if inputs["performance_ratio"] > 1:

            messagebox.showerror(
                "Orçamento",
                "O rendimento deve ser entre 0 e 1.",
            )
            self._set_status("Rendimento inválido.")
            return

        results = calculate_sizing(**inputs)

        create_budget(
            client_id,
            self.budget_fields["budget_date"].get().strip(),
            self.budget_status.get(),
            inputs,
            results,
        )

        self._show_results(results)
        self.refresh_all()
        self._set_status("Orçamento calculado e salvo.")

        messagebox.showinfo(
            "Orçamento",
            "Orçamento calculado e salvo.",
        )

    def clear_budget_form(self):

        keep_defaults = {
            "budget_date": str(date.today()),
            "performance_ratio": "0.8",
            "module_power": "550",
            "energy_tariff": "0.95",
            "generation_extra_percent": "0",
        }

        for key, field in self.budget_fields.items():

            if key in ("client", "status"):

                continue

            field.delete(0, tk.END)

            if key in keep_defaults:

                field.insert(0, keep_defaults[key])

        self.budget_status.set("Em negociação")

        for field in self.monthly_consumption_fields:

            field.delete(0, tk.END)
            field.insert(0, "0")

        for field in self.monthly_hsp_fields:

            field.delete(0, tk.END)
            field.insert(0, "5.5")

        for label in self.result_labels.values():

            label.configure(text="-")

        self.monthly_result_tree.delete(
            *self.monthly_result_tree.get_children()
        )

    def _show_results(self, results):

        self.result_labels["system_power"].configure(
            text=f"{results['system_power']:.2f} kWp"
        )
        self.result_labels["module_count"].configure(
            text=str(results["module_count"])
        )
        self.result_labels["monthly_generation"].configure(
            text=f"{results['monthly_generation']:.2f} kWh"
        )
        self.result_labels["monthly_savings"].configure(
            text=f"R$ {results['monthly_savings']:.2f}"
        )
        self.result_labels["average_consumption"].configure(
            text=f"{results['average_consumption']:.2f} kWh"
        )
        self.result_labels["average_hsp"].configure(
            text=f"{results['average_hsp']:.2f}"
        )
        self.result_labels["annual_consumption"].configure(
            text=f"{results['annual_consumption']:.2f} kWh"
        )
        self.result_labels["annual_generation"].configure(
            text=f"{results['annual_generation']:.2f} kWh"
        )

        self.monthly_result_tree.delete(
            *self.monthly_result_tree.get_children()
        )

        for index, month in enumerate(MONTHS):

            self.monthly_result_tree.insert(
                "",
                "end",
                values=(
                    month,
                    f"{results['input_monthly_consumptions'][index]:.2f}",
                    f"{results['input_monthly_hsp'][index]:.2f}",
                    f"{results['monthly_generations'][index]:.2f}",
                    f"{results['monthly_balances'][index]:.2f}",
                ),
            )

    def change_selected_budget_status(self):

        selected = self.budgets_tree.selection()

        if not selected:

            messagebox.showerror(
                "Orçamentos",
                "Selecione um orçamento na tabela.",
            )
            self._set_status("Nenhum orçamento selecionado.")
            return

        budget_id = int(selected[0])
        update_budget_status(
            budget_id,
            self.history_status.get(),
        )

        self.refresh_all()
        self._set_status("Status do orçamento atualizado.")

    def refresh_all(self):

        self.clients = list_clients()
        self.budgets = list_budgets()

        self._refresh_dashboard()
        self._refresh_clients()
        self._refresh_client_select()
        self._refresh_finance_budget_select()
        self._refresh_chart_budget_select()
        self._refresh_budgets()
        self._set_status(
            f"{len(self.clients)} clientes, {len(self.budgets)} orçamentos carregados."
        )

    def _refresh_dashboard(self):

        totals = get_dashboard_totals()

        self.metric_labels["budget_count"].configure(
            text=str(totals["budget_count"])
        )
        self.metric_labels["forecast_revenue"].configure(
            text=f"R$ {totals['forecast_revenue']:.2f}"
        )
        self.metric_labels["conversion_rate"].configure(
            text=f"{totals['conversion_rate']:.1f}%"
        )
        self.draw_dashboard()

    def _refresh_clients(self):

        self.clients_tree.delete(
            *self.clients_tree.get_children()
        )

        for client in self.clients:

            self.clients_tree.insert(
                "",
                "end",
                iid=str(client["id"]),
                values=(
                    client["name"],
                    format_document(client["document"]),
                    format_phone(client["phone"]),
                    client["email"],
                    client["city"],
                    client["state"],
                ),
            )

    def _refresh_client_select(self):

        self.client_select["values"] = [
            f"{client['name']} - ID {client['id']}"
            for client in self.clients
        ]

        if self.clients:

            self.client_select.current(0)

    def _refresh_finance_budget_select(self):

        self.finance_budget_select["values"] = [
            (
                f"#{budget['id']} - {budget['client_name']} - "
                f"{'R$ ' + format(budget['investment'], '.2f') if budget['investment'] else 'sem valor'}"
            )
            for budget in self.budgets
        ]

        if self.budgets:

            self.finance_budget_select.current(0)
            self._load_selected_budget_finance()

    def _refresh_chart_budget_select(self):

        self.chart_budget_select["values"] = [
            (
                f"#{budget['id']} - {budget['client_name']} - "
                f"{budget['budget_date']}"
            )
            for budget in self.budgets
        ]

        if self.budgets:

            self.chart_budget_select.current(0)

        self.draw_generation_chart()

    def _load_selected_budget_finance(self):

        if not self.budgets:

            return

        index = self.finance_budget_select.current()

        if index < 0:

            return

        budget = self.budgets[index]

        self.finance_fields["project_value"].delete(0, tk.END)
        self.finance_fields["project_value"].insert(
            0,
            f"{budget['investment']:.2f}"
            if budget["investment"]
            else "18000"
        )

        self.finance_fields["down_payment"].delete(0, tk.END)
        self.finance_fields["down_payment"].insert(
            0,
            f"{budget['down_payment']:.2f}"
            if budget["down_payment"]
            else "0"
        )

        self.finance_fields["monthly_interest_rate"].delete(0, tk.END)
        self.finance_fields["monthly_interest_rate"].insert(
            0,
            f"{budget['monthly_interest_rate']:.2f}"
            if budget["monthly_interest_rate"]
            else "1.5"
        )

        self.finance_fields["term_months"].delete(0, tk.END)
        self.finance_fields["term_months"].insert(
            0,
            str(budget["term_months"])
            if budget["term_months"]
            else "60"
        )

    def _refresh_budgets(self):

        self.budgets_tree.delete(
            *self.budgets_tree.get_children()
        )

        search = self.history_search.get().strip().lower()
        status_filter = self.history_filter.get()

        self.filtered_budgets = []

        for budget in self.budgets:

            if status_filter != "Todos" and budget["status"] != status_filter:

                continue

            searchable = (
                f"{budget['client_name']} "
                f"{budget['budget_date']} "
                f"{budget['status']}"
            ).lower()

            if search and search not in searchable:

                continue

            self.filtered_budgets.append(budget)

            self.budgets_tree.insert(
                "",
                "end",
                iid=str(budget["id"]),
                tags=(budget["status"],),
                values=(
                    budget["budget_date"],
                    budget["client_name"],
                    budget["status"],
                    f"{budget['system_power']:.2f}",
                    budget["module_count"],
                    f"{budget['annual_generation']:.2f}",
                    (
                        f"R$ {budget['investment']:.2f}"
                        if budget["investment"]
                        else "-"
                    ),
                    (
                        f"R$ {budget['monthly_payment']:.2f}"
                        if budget["monthly_payment"]
                        else "-"
                    ),
                    f"R$ {budget['monthly_savings']:.2f}",
                    (
                        f"{budget['payback_years']:.2f} anos"
                        if budget["payback_years"]
                        else "-"
                    ),
                ),
            )

    def _set_status(self, message):

        if hasattr(self, "status_bar"):

            self.status_bar.configure(text=message)

if __name__ == "__main__":

    app = SolarManagerApp()
    app.mainloop()
