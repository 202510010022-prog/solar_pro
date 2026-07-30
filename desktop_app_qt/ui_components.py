import json
import sys
from pathlib import Path

from PySide6.QtCore import Qt, QRectF
from PySide6.QtGui import QIcon, QPainter, QPalette, QPen, QPixmap, QColor, QFont
from PySide6.QtWidgets import (
    QComboBox,
    QDialog,
    QFrame,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QSizePolicy,
    QToolTip,
    QVBoxLayout,
    QWidget,
)

from desktop_app.calculations import MONTHS
from desktop_app.sync_types import AppUser, SyncError

OFFLINE_USER = AppUser(
    matricula="offline",
    nome="Modo offline",
    permissao="offline",
)


def brl(value):
    return f"R$ {value:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def number(value, digits=2):
    return f"{value:.{digits}f}".replace(".", ",")


def parse_float(widget):
    text = widget.text().strip().replace(".", "").replace(",", ".")
    return float(text or 0)


def parse_int(widget):
    return int(parse_float(widget))


def row_to_dict(row):
    return dict(row)


def resource_path(relative_path):
    if hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / relative_path
    return Path(__file__).resolve().parent / relative_path


def app_icon():
    return QIcon(str(resource_path("assets/app_icon.png")))


class Card(QFrame):
    def __init__(self, title, value, subtitle="", accent="#1d6cff", icon_name=None):
        super().__init__()
        self.setObjectName("card")
        self.setMinimumHeight(84)
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        layout = QHBoxLayout(self)
        layout.setContentsMargins(18, 11, 14, 11)
        layout.setSpacing(14)

        icon = QLabel()
        icon.setAlignment(Qt.AlignCenter)
        icon.setFixedSize(46, 46)
        icon.setContentsMargins(2, 2, 2, 2)
        loaded_icon = False
        if icon_name:
            icon_path = resource_path(f"assets/ui_kit/{icon_name}.png")
            if not icon_path.exists():
                icon_path = resource_path(f"assets/dashboard_icons/{icon_name}.png")
            pixmap = QPixmap(str(icon_path))
            if not pixmap.isNull():
                icon.setPixmap(
                    pixmap.scaled(
                        42,
                        42,
                        Qt.KeepAspectRatio,
                        Qt.SmoothTransformation,
                    )
                )
                loaded_icon = True
            else:
                icon.setText("•")
        else:
            icon.setText("•")

        if not loaded_icon:
            icon.setStyleSheet(
                f"background: {accent}18; color: {accent}; border-radius: 14px; "
                "font-size: 18px; font-weight: 800;"
            )

        text_layout = QVBoxLayout()
        text_layout.setSpacing(1)
        title_label = QLabel(title)
        title_label.setObjectName("cardTitle")
        title_label.setMinimumWidth(96)
        value_label = QLabel(value)
        value_label.setObjectName("cardValue")
        value_label.setMinimumWidth(96)
        subtitle_label = QLabel(subtitle)
        subtitle_label.setObjectName("muted")
        subtitle_label.setMinimumWidth(96)

        text_layout.addWidget(title_label)
        text_layout.addWidget(value_label)
        text_layout.addWidget(subtitle_label)
        layout.addWidget(icon)
        layout.addLayout(text_layout, 1)


class SalesFunnelCard(QFrame):
    def __init__(self):
        super().__init__()
        self.setObjectName("section")
        self.setMinimumHeight(250)
        self.values = []
        self.total = 0
        self.layout = QVBoxLayout(self)
        self.layout.setContentsMargins(16, 14, 16, 14)
        self.layout.setSpacing(10)

        title = QLabel("Funil de vendas")
        title.setObjectName("sectionTitle")
        subtitle = QLabel("Distribuição dos projetos")
        subtitle.setObjectName("muted")
        self.layout.addWidget(title)
        self.layout.addWidget(subtitle)

        body = QHBoxLayout()
        body.setSpacing(14)
        self.donut = DonutWidget()
        body.addWidget(self.donut, 1)
        self.legend = QVBoxLayout()
        self.legend.setSpacing(8)
        body.addLayout(self.legend, 1)
        self.layout.addLayout(body, 1)

    def set_data(self, values):
        self.values = values
        self.total = sum(value for _, value, _ in values)
        self.donut.set_data(values)
        while self.legend.count():
            item = self.legend.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
        for label, value, color in values:
            row = QHBoxLayout()
            marker = QLabel()
            marker.setFixedSize(10, 10)
            marker.setStyleSheet(f"background: {color}; border-radius: 5px;")
            text = QLabel(f"{label} ({value})")
            text.setObjectName("muted")
            row.addWidget(marker)
            row.addWidget(text, 1)
            wrapper = QWidget()
            wrapper.setLayout(row)
            self.legend.addWidget(wrapper)
        self.legend.addStretch()


class DonutWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.setMinimumSize(150, 150)
        self.values = []

    def set_data(self, values):
        self.values = values
        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        rect = self.rect().adjusted(10, 10, -10, -10)
        size = min(rect.width(), rect.height())
        donut_rect = QRectF(
            rect.center().x() - size / 2,
            rect.center().y() - size / 2,
            size,
            size,
        ).adjusted(8, 8, -8, -8)
        total = sum(value for _, value, _ in self.values)

        painter.setPen(QPen(QColor("#14345d"), 20, Qt.SolidLine, Qt.RoundCap))
        painter.drawArc(donut_rect, 0, 360 * 16)

        if total:
            start = 90 * 16
            for _, value, color in self.values:
                span = -int((value / total) * 360 * 16)
                painter.setPen(QPen(QColor(color), 20, Qt.SolidLine, Qt.RoundCap))
                painter.drawArc(donut_rect, start, span)
                start += span

        painter.setPen(QColor("#f8fafc"))
        painter.setFont(QFont("Inter", 18, QFont.Bold))
        painter.drawText(donut_rect, Qt.AlignCenter, str(total))
        painter.setFont(QFont("Inter", 9))
        painter.setPen(QColor("#94a3b8"))
        label_rect = QRectF(
            donut_rect.left(),
            donut_rect.center().y() + 16,
            donut_rect.width(),
            20,
        )
        painter.drawText(label_rect, Qt.AlignCenter, "Total")


class RecentActivitiesCard(QFrame):
    def __init__(self):
        super().__init__()
        self.setObjectName("section")
        self.setMinimumHeight(230)
        self.layout = QVBoxLayout(self)
        self.layout.setContentsMargins(16, 14, 16, 14)
        self.layout.setSpacing(12)
        title = QLabel("Atividades recentes")
        title.setObjectName("sectionTitle")
        self.layout.addWidget(title)
        self.rows = QVBoxLayout()
        self.rows.setSpacing(10)
        self.layout.addLayout(self.rows)
        self.layout.addStretch()

    def set_activities(self, activities):
        while self.rows.count():
            item = self.rows.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
        for activity in activities[:4]:
            row = QHBoxLayout()
            row.setSpacing(12)
            marker = QLabel(activity.get("icon", ""))
            marker.setAlignment(Qt.AlignCenter)
            marker.setFixedSize(42, 42)
            color = activity.get("color", "#007bff")
            icon_name = activity.get("icon_name")
            if icon_name:
                icon_path = resource_path(f"assets/ui_kit/{icon_name}.png")
                pixmap = QPixmap(str(icon_path))
                if not pixmap.isNull():
                    marker.setPixmap(
                        pixmap.scaled(
                            34,
                            34,
                            Qt.KeepAspectRatio,
                            Qt.SmoothTransformation,
                        )
                    )
                else:
                    marker.setStyleSheet(
                        f"background: {color}22; color: {color}; border: 1px solid {color}88; "
                        "border-radius: 17px; font-size: 14px; font-weight: 900;"
                    )
            else:
                marker.setStyleSheet(
                    f"background: {color}22; color: {color}; border: 1px solid {color}88; "
                    "border-radius: 17px; font-size: 14px; font-weight: 900;"
                )

            text_box = QVBoxLayout()
            text_box.setSpacing(2)
            title = QLabel(activity.get("title", ""))
            title.setObjectName("activityTitle")
            title.setWordWrap(True)
            subtitle = QLabel(activity.get("subtitle", ""))
            subtitle.setObjectName("muted")
            subtitle.setWordWrap(True)
            text_box.addWidget(title)
            text_box.addWidget(subtitle)

            date = QLabel(activity.get("date", ""))
            date.setObjectName("muted")
            date.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
            date.setMinimumWidth(76)

            row.addWidget(marker)
            row.addLayout(text_box, 1)
            row.addWidget(date)
            wrapper = QWidget()
            wrapper.setLayout(row)
            self.rows.addWidget(wrapper)


class Section(QFrame):
    def __init__(self, title):
        super().__init__()
        self.setObjectName("section")
        self.layout = QVBoxLayout(self)
        self.layout.setContentsMargins(14, 12, 14, 12)
        self.layout.setSpacing(10)
        heading = QLabel(title)
        heading.setObjectName("sectionTitle")
        self.layout.addWidget(heading)


class ChartWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.setMinimumHeight(300)
        self.setMouseTracking(True)
        self.consumption = []
        self.generation = []
        self.balance = []
        self.bar_regions = []

    def set_data(self, consumption, generation, balance):
        self.consumption = consumption
        self.generation = generation
        self.balance = balance
        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        rect = self.rect().adjusted(20, 18, -20, -18)
        painter.fillRect(self.rect(), QColor("#020817"))

        painter.setPen(QPen(QColor("#1f4f8a"), 1))
        painter.drawRoundedRect(rect, 10, 10)
        self.bar_regions = []

        if not self.consumption or not self.generation:
            painter.setPen(QColor("#94a3b8"))
            painter.drawText(self.rect(), Qt.AlignCenter, "Selecione um projeto para visualizar o gráfico")
            return

        all_values = self.consumption + self.generation + [abs(v) for v in self.balance]
        max_value = max(max(all_values), 1)
        scale_max = max_value * 1.12
        bar_area = rect.adjusted(54, 48, -18, -36)
        group_width = bar_area.width() / 12
        bar_width = max(6, min(14, group_width / 5))

        painter.setPen(QPen(QColor("#12335e"), 1))
        for index in range(5):
            y = bar_area.bottom() - (bar_area.height() * index / 4)
            painter.drawLine(bar_area.left(), y, bar_area.right(), y)
            value = scale_max * index / 4
            painter.setPen(QColor("#94a3b8"))
            painter.setFont(QFont("Inter", 8))
            painter.drawText(
                rect.left() + 10,
                int(y - 8),
                38,
                16,
                Qt.AlignRight,
                f"{value:.0f}",
            )
            painter.setPen(QPen(QColor("#12335e"), 1))

        colors = {
            "consumption": QColor("#ff9f1c"),
            "generation": QColor("#1d6cff"),
            "balance": QColor("#2fb344"),
            "negative_balance": QColor("#d94848"),
        }

        legend = [
            ("Consumo", colors["consumption"]),
            ("Geração", colors["generation"]),
            ("Saldo positivo", colors["balance"]),
            ("Saldo negativo", colors["negative_balance"]),
        ]
        legend_x = bar_area.left()
        legend_y = rect.top() + 18
        painter.setFont(QFont("Inter", 9))
        for label, color in legend:
            painter.fillRect(legend_x, legend_y + 2, 10, 10, color)
            painter.setPen(QColor("#cbd5e1"))
            painter.drawText(legend_x + 16, legend_y + 12, label)
            legend_x += 124

        for index in range(12):
            center = bar_area.left() + (group_width * index) + (group_width / 2)
            values = [
                ("Consumo", self.consumption[index], colors["consumption"], -bar_width - 3),
                ("Geração", self.generation[index], colors["generation"], 0),
                (
                    "Saldo",
                    self.balance[index],
                    colors["balance"] if self.balance[index] >= 0 else colors["negative_balance"],
                    bar_width + 3,
                ),
            ]

            for label, value, color, offset in values:
                visible_value = abs(value)
                height = (visible_value / scale_max) * bar_area.height()
                if visible_value > 0:
                    height = max(4, height)
                x = center + offset - (bar_width / 2)
                y = bar_area.bottom() - height
                bar_rect = QRectF(x, y, bar_width, height)
                painter.fillRect(bar_rect, color)
                hit_rect = bar_rect.adjusted(-3, -4, 3, 4)
                self.bar_regions.append(
                    (
                        hit_rect,
                        f"{MONTHS[index]}\n{label}: {number(value)} kWh",
                    )
                )

            painter.setPen(QColor("#94a3b8"))
            painter.setFont(QFont("Inter", 8))
            painter.drawText(
                int(center - 16),
                bar_area.bottom() + 18,
                32,
                16,
                Qt.AlignCenter,
                MONTHS[index],
            )

    def mouseMoveEvent(self, event):
        position = event.position()
        for rect, tooltip in self.bar_regions:
            if rect.contains(position):
                QToolTip.showText(event.globalPosition().toPoint(), tooltip, self)
                return
        QToolTip.hideText()

    def leaveEvent(self, event):
        QToolTip.hideText()
        super().leaveEvent(event)


class LoginDialog(QDialog):
    def __init__(self, sync_client):
        super().__init__()
        self.sync_client = sync_client
        self.user = None
        self.setWindowTitle("Entrar no Solar Pro")
        self.setWindowIcon(app_icon())
        self.setModal(True)
        self.setFixedWidth(460)
        self.setObjectName("loginDialog")

        layout = QVBoxLayout(self)
        layout.setContentsMargins(28, 26, 28, 24)
        layout.setSpacing(14)

        hero = QFrame()
        hero.setObjectName("loginHero")
        hero_layout = QHBoxLayout(hero)
        hero_layout.setContentsMargins(18, 16, 18, 16)
        hero_layout.setSpacing(14)
        logo = QLabel()
        logo.setAlignment(Qt.AlignCenter)
        logo.setFixedSize(82, 82)
        logo_pixmap = QPixmap(str(resource_path("assets/app_icon.png")))
        if not logo_pixmap.isNull():
            logo.setPixmap(
                logo_pixmap.scaled(
                    76,
                    76,
                    Qt.KeepAspectRatio,
                    Qt.SmoothTransformation,
                )
            )
        hero_layout.addWidget(logo)

        brand_box = QVBoxLayout()
        brand_box.setSpacing(3)
        brand = QLabel("Solar Pro")
        brand.setObjectName("loginBrand")
        brand_sub = QLabel("Energia Solar")
        brand_sub.setObjectName("brandSub")
        brand_box.addWidget(brand)
        brand_box.addWidget(brand_sub)
        brand_box.addStretch()
        hero_layout.addLayout(brand_box, 1)
        layout.addWidget(hero)

        title = QLabel("Acesso da equipe")
        title.setObjectName("dialogTitle")

        provider = getattr(self.sync_client, "provider_name", "Supabase")
        login_label = getattr(self.sync_client, "login_label", "Matrícula")
        password_label = getattr(self.sync_client, "password_label", "PIN")
        login_placeholder = getattr(
            self.sync_client,
            "login_placeholder",
            "Matrícula",
        )
        password_placeholder = getattr(
            self.sync_client,
            "password_placeholder",
            "PIN, se configurado",
        )

        subtitle = QLabel(f"Valide seu acesso via {provider}.")
        subtitle.setObjectName("pageSubtitle")
        subtitle.setWordWrap(True)
        layout.addWidget(title)
        layout.addWidget(subtitle)

        layout.addSpacing(4)
        self.registration_input = QLineEdit()
        self.registration_input.setPlaceholderText(login_placeholder)
        layout.addWidget(QLabel(login_label))
        layout.addWidget(self.registration_input)

        self.pin_input = QLineEdit()
        self.pin_input.setPlaceholderText(password_placeholder)
        self.pin_input.setEchoMode(QLineEdit.Password)
        layout.addWidget(QLabel(password_label))
        layout.addWidget(self.pin_input)

        self.status = QLabel("")
        self.status.setObjectName("loginStatus")
        self.status.setWordWrap(True)
        layout.addWidget(self.status)

        actions = QHBoxLayout()
        actions.setContentsMargins(0, 10, 0, 0)
        self.offline_button = QPushButton("Usar offline")
        self.offline_button.setObjectName("secondaryButton")
        self.offline_button.clicked.connect(self.use_offline)
        self.offline_button.setVisible(not self.sync_client.is_configured())
        self.login_button = QPushButton("Entrar")
        self.login_button.setObjectName("primaryButton")
        self.login_button.setMinimumWidth(100)
        self.login_button.setDefault(True)
        self.login_button.clicked.connect(self.login)
        actions.addWidget(self.offline_button)
        actions.addStretch()
        actions.addWidget(self.login_button)
        layout.addLayout(actions)

        self.registration_input.returnPressed.connect(self.login)
        self.pin_input.returnPressed.connect(self.login)

    def login(self):
        try:
            self.status.setText("Validando acesso...")
            user = self.sync_client.authenticate_user(
                self.registration_input.text(),
                self.pin_input.text(),
            )
            self.user = user
            self.accept()
        except SyncError as error:
            message = str(error)
            self.status.setText(message)
            self.show_message("Acesso negado", message, QMessageBox.Warning)
        except Exception as error:
            message = f"Falha ao validar acesso: {error}"
            self.status.setText(message)
            self.show_message("Acesso negado", message, QMessageBox.Warning)

    def use_offline(self):
        if self.sync_client.is_configured():
            self.show_message(
                "Acesso bloqueado",
                "Modo offline indisponível com Supabase configurado.",
                QMessageBox.Warning,
            )
            return
        self.user = OFFLINE_USER
        self.accept()

    def show_message(self, title, message, icon=QMessageBox.Information):
        dialog = QMessageBox(self)
        dialog.setWindowTitle("Solar Pro")
        dialog.setText(title)
        dialog.setInformativeText(message)
        dialog.setIcon(icon)
        dialog.setMinimumWidth(420)
        dialog.exec()
