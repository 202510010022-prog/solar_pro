import json
import sys
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import (
    QEasingCurve,
    QParallelAnimationGroup,
    QPropertyAnimation,
    QSettings,
    QSize,
    Qt,
    QTimer,
)
from PySide6.QtGui import QColor, QFont, QIcon, QPalette, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QComboBox,
    QDialog,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QHeaderView,
    QFileDialog,
    QInputDialog,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QScrollArea,
    QSizePolicy,
    QStackedWidget,
    QStyleFactory,
    QTableWidget,
    QTableWidgetItem,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

APP_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(APP_ROOT))

from desktop_app.calculations import MONTHS, calculate_financing, calculate_sizing
from desktop_app.database import (
    create_client,
    delete_client,
    get_dashboard_totals,
    get_project_payment_totals,
    initialize_database,
    list_clients,
    update_client,
)
from desktop_app.project_service import ProjectService
from desktop_app.supabase_sync import SupabaseSync
from desktop_app.sync_types import SyncError
from desktop_app.validators import (
    format_document,
    format_phone,
    only_digits,
    validate_document,
    validate_email,
    validate_phone,
)
from desktop_app_qt.ui_components import (
    OFFLINE_USER,
    Card,
    ChartWidget,
    LoginDialog,
    RecentActivitiesCard,
    SalesFunnelCard,
    Section,
    app_icon,
    brl,
    number,
    parse_float,
    parse_int,
    resource_path,
    row_to_dict,
)
from desktop_app_qt.project_details_page import ProjectDetailsPage
from services.bill_importer_service import BillImporterService
from services.project_documents import DOCUMENT_CATEGORIES, ProjectDocuments


STATUSES = ["Em negociação", "Fechado", "Concluído", "Não aprovado"]
PAYMENT_TYPES = [
    "Pix",
    "Boleto",
    "Cartão",
    "Transferência",
    "Dinheiro",
    "Financiamento",
    "Outro",
]
ROLE_LABELS = {
    "assessor_projetos": "Assessor de Projetos",
    "assessor_daf": "Assessor do DAF",
    "diretor": "Diretor",
    "admin": "Diretor",
    "owner": "Diretor",
    "usuario": "Assessor de Projetos",
    "offline": "Offline",
}
BRAZIL_STATES = [
    "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT",
    "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO",
    "RR", "SC", "SP", "SE", "TO",
]

APP_STYLES = """
* {
    font-family: Inter, "Segoe UI", Arial, sans-serif;
    color: #233044;
    font-size: 12px;
}
QWidget, QFrame, QScrollArea {
    background: #f3f6fa;
}
QDialog, QMessageBox {
    background: #ffffff;
}
QDialog QLabel, QMessageBox QLabel {
    color: #2c3a50;
}
#loginDialog {
    background: #ffffff;
}
#sidebar {
    background: #10213a;
    border-right: 1px solid #223a5d;
    border-top-right-radius: 18px;
    border-bottom-right-radius: 18px;
}
#sidebar QLabel {
    color: #dce7ff;
}
#brand {
    color: #ffffff;
    font-size: 20px;
    font-weight: 900;
    line-height: 140%;
    letter-spacing: 0px;
}
#brandSub {
    color: #9fb8dc;
    font-size: 10px;
    font-weight: 800;
    letter-spacing: 1px;
}
#userBadge {
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 10px;
    color: #e8f0ff;
    font-size: 11px;
    font-weight: 700;
    padding: 10px 12px;
    line-height: 145%;
}
#navButton {
    background: transparent;
    color: #dce7ff;
    text-align: left;
    padding: 10px 14px;
    border: 0;
    border-radius: 8px;
    font-weight: 700;
    font-size: 12px;
}
#navButton:hover {
    background: rgba(255, 255, 255, 0.08);
}
#navButton:checked {
    background: #2a6dff;
    color: #ffffff;
}
#greenCard {
    background: #16355d;
    border: 1px solid #274f83;
    border-radius: 12px;
}
#greenTitle {
    color: #ffffff;
    font-weight: 800;
}
#greenText, #sidebarFooter {
    color: #9cb9ff;
}
#poweredBy {
    color: #aac0e5;
    font-size: 10px;
}
#shell {
    background: #eef3f8;
}
#page, #pageScroll {
    background: #eef3f8;
}
#headerPanel {
    background: #ffffff;
    border: 1px solid #e3e9f4;
    border-radius: 14px;
}
#headerPanel QLabel {
    color: #34415a;
}
#pageTitle {
    font-size: 24px;
    font-weight: 900;
    color: #1f3246;
}
#dialogTitle {
    color: #1f3246;
    font-size: 19px;
    font-weight: 900;
}
#pageSubtitle, #muted {
    color: #66728a;
    font-size: 11px;
    line-height: 140%;
}
#loginStatus {
    color: #d44f54;
    font-size: 12px;
}
#card, #section {
    background: #ffffff;
    border: 1px solid #e2e9f4;
    border-radius: 12px;
}
#card {
    margin: 0;
}
#cardTitle {
    color: #5f6f86;
    font-size: 10px;
}
#cardValue {
    font-size: 18px;
    font-weight: 900;
}
#metricStrip {
    background: #f7faff;
    border: 1px solid #e1e8f3;
    border-radius: 10px;
}
#metricLabel {
    color: #66728a;
    font-size: 10px;
    font-weight: 700;
}
#metricValue {
    color: #1f3246;
    font-size: 14px;
    font-weight: 900;
}
#sectionTitle {
    font-size: 14px;
    font-weight: 900;
}
QLineEdit, QComboBox {
    background: #ffffff;
    color: #1f3246;
    border: 1px solid #d9e2ec;
    border-radius: 8px;
    padding: 7px 10px;
    min-height: 28px;
    font-size: 12px;
}
QLineEdit::placeholder {
    color: #8d9bb1;
}
QComboBox {
    padding-right: 26px;
}
QComboBox::drop-down {
    subcontrol-origin: padding;
    subcontrol-position: top right;
    width: 28px;
    border-left: 1px solid #d9e2ec;
    border-top-right-radius: 8px;
    border-bottom-right-radius: 8px;
    background: #f3f7fb;
}
QComboBox::down-arrow {
    image: none;
    border: none;
}
QComboBox QAbstractItemView, #comboPopup {
    background: #ffffff;
    color: #1f3246;
    border: 1px solid #d9e2ec;
    border-radius: 8px;
    selection-background-color: #2a6dff;
    selection-color: #ffffff;
    outline: 0;
    padding: 4px;
}
QComboBox QAbstractItemView::item, #comboPopup::item {
    background: #ffffff;
    color: #1f3246;
    min-height: 28px;
    padding: 7px 10px;
}
QComboBox QAbstractItemView::item:selected, #comboPopup::item:selected {
    background: #2a6dff;
    color: #ffffff;
}
QLineEdit:focus, QComboBox:focus {
    border: 1px solid #2a6dff;
}
QPushButton {
    background: #ffffff;
    color: #1f3246;
    border: 1px solid #d9e2ec;
    border-radius: 8px;
    padding: 8px 13px;
    font-weight: 700;
    font-size: 12px;
    min-height: 32px;
}
QPushButton:hover {
    background: #eef4ff;
    border-color: #b8c8f7;
}
QPushButton:pressed {
    background: #e5ecfb;
}
#primaryButton {
    background: #2a6dff;
    color: #ffffff;
    border: 1px solid #2a6dff;
}
#primaryButton:hover {
    background: #2359d7;
}
#secondaryButton {
    color: #4b556a;
    border: 1px solid #d1d9e7;
    background: #ffffff;
}
QTableWidget {
    background: #ffffff;
    alternate-background-color: #f6f9ff;
    border: 1px solid #e2e8f5;
    border-radius: 10px;
    gridline-color: #edf2f7;
    selection-background-color: #2a6dff;
    selection-color: #ffffff;
}
QHeaderView::section {
    background: #eef4ff;
    border: none;
    border-bottom: 1px solid #dbe4f3;
    padding: 8px 9px;
    font-weight: 700;
    font-size: 11px;
    color: #4b5568;
}
QTableWidget::item {
    padding: 7px 7px;
}
#resultText {
    color: #3b4860;
    font-size: 12px;
    line-height: 160%;
}
#statusbar {
    background: #ffffff;
    border-top: 1px solid #e2e8f5;
}
QScrollArea {
    background: transparent;
}
QScrollBar:vertical {
    background: #e7eef8;
    width: 12px;
    margin: 0;
    border-radius: 6px;
}
QScrollBar::handle:vertical {
    background: #a8bbd9;
    min-height: 34px;
    border-radius: 6px;
}
QScrollBar::handle:vertical:hover {
    background: #8497bc;
}
QScrollBar::add-line:vertical,
QScrollBar::sub-line:vertical {
    height: 0;
    border: 0;
    background: transparent;
}

/* Dark neon Solar Pro skin */
* {
    color: #f8fafc;
}
QWidget, QFrame, QScrollArea {
    background: #020817;
}
QDialog, QMessageBox {
    background: #06101f;
}
QDialog QLabel, QMessageBox QLabel {
    color: #f8fafc;
}
#loginDialog {
    background: #06101f;
}
#sidebar {
    background: qlineargradient(x1:0 y1:0, x2:0 y2:1, stop:0 #06101f, stop:1 #020817);
    border-right: 1px solid rgba(59, 130, 246, 0.35);
    border-top-right-radius: 0;
    border-bottom-right-radius: 0;
}
#sidebar QLabel {
    color: #dbeafe;
}
#brand {
    color: #f8fafc;
}
#brandSub {
    color: #94a3b8;
}
#userBadge {
    background: rgba(15, 23, 42, 0.85);
    border: 1px solid rgba(59, 130, 246, 0.35);
    border-radius: 16px;
    color: #f8fafc;
}
#navButton {
    background: transparent;
    color: #cbd5e1;
    text-align: left;
    padding-left: 18px;
    border: 1px solid transparent;
    border-radius: 12px;
}
#navButton:hover {
    background: rgba(0, 123, 255, 0.12);
    border: 1px solid rgba(59, 130, 246, 0.28);
}
#navButton:checked {
    background: qlineargradient(x1:0 y1:0, x2:1 y2:0, stop:0 #007bff, stop:1 #00aaff);
    border: 1px solid rgba(0, 170, 255, 0.75);
    color: #ffffff;
}
#greenCard {
    background: qlineargradient(x1:0 y1:0, x2:1 y2:1, stop:0 rgba(15, 23, 42, 0.88), stop:1 rgba(6, 78, 59, 0.55));
    border: 1px solid rgba(72, 225, 59, 0.35);
    border-radius: 16px;
}
#greenTitle {
    color: #f8fafc;
}
#greenText, #sidebarFooter {
    color: #48e13b;
}
#poweredBy {
    color: #94a3b8;
}
#shell, #page, #pageScroll {
    background: qradialgradient(cx:0.8, cy:0.05, radius:0.9, fx:0.8, fy:0.05, stop:0 rgba(0, 123, 255, 0.35), stop:0.35 #06101f, stop:1 #020817);
}
#headerPanel, #card, #section, #metricStrip {
    background: rgba(15, 23, 42, 0.85);
    border: 1px solid rgba(59, 130, 246, 0.35);
    border-radius: 18px;
}
#card:hover, #section:hover {
    border: 1px solid rgba(0, 170, 255, 0.75);
    background: rgba(15, 23, 42, 0.96);
}
#headerPanel QLabel {
    color: #f8fafc;
}
#pageTitle {
    color: #f8fafc;
}
#dialogTitle {
    color: #f8fafc;
}
#pageSubtitle, #muted, #cardTitle, #metricLabel {
    color: #94a3b8;
}
#cardValue, #metricValue, #sectionTitle, #activityTitle {
    color: #f8fafc;
}
QLineEdit, QComboBox {
    background: rgba(2, 8, 23, 0.76);
    color: #f8fafc;
    border: 1px solid rgba(59, 130, 246, 0.35);
    border-radius: 12px;
    selection-background-color: #007bff;
}
QLineEdit::placeholder {
    color: #64748b;
}
QLineEdit:focus, QComboBox:focus {
    border: 1px solid #00aaff;
}
QComboBox::drop-down {
    background: rgba(6, 16, 31, 0.9);
    border-left: 1px solid rgba(59, 130, 246, 0.35);
    border-top-right-radius: 12px;
    border-bottom-right-radius: 12px;
}
QComboBox QAbstractItemView, #comboPopup {
    background: #06101f;
    color: #f8fafc;
    border: 1px solid rgba(59, 130, 246, 0.45);
    border-radius: 12px;
    padding: 6px;
    selection-background-color: #007bff;
    selection-color: #ffffff;
    outline: 0;
}
QComboBox QAbstractItemView::item, #comboPopup::item {
    background: #06101f;
    color: #f8fafc;
    min-height: 28px;
    padding: 7px 10px;
}
QComboBox QAbstractItemView::item:selected, #comboPopup::item:selected {
    background: #007bff;
    color: #ffffff;
}
QPushButton {
    background: rgba(15, 23, 42, 0.85);
    color: #f8fafc;
    border: 1px solid rgba(59, 130, 246, 0.35);
    border-radius: 12px;
}
QPushButton:hover {
    background: rgba(0, 123, 255, 0.18);
    border: 1px solid rgba(0, 170, 255, 0.78);
}
#primaryButton {
    background: qlineargradient(x1:0 y1:0, x2:1 y2:0, stop:0 #007bff, stop:1 #00aaff);
    color: #ffffff;
    border: 1px solid rgba(0, 170, 255, 0.9);
}
#primaryButton:hover {
    background: qlineargradient(x1:0 y1:0, x2:1 y2:0, stop:0 #006ee6, stop:1 #0098df);
    border: 1px solid #7dd3fc;
}
#secondaryButton {
    background: rgba(15, 23, 42, 0.85);
    color: #cbd5e1;
    border: 1px solid rgba(59, 130, 246, 0.35);
}
#topIconButton {
    background: rgba(15, 23, 42, 0.55);
    border: 1px solid transparent;
    border-radius: 17px;
    min-width: 34px;
    max-width: 34px;
    min-height: 34px;
    padding: 0;
    color: #94a3b8;
    font-weight: 900;
}
#topIconButton:hover {
    border: 1px solid rgba(0, 170, 255, 0.75);
}
#avatarBadge {
    background: #0f2345;
    border: 1px solid rgba(59, 130, 246, 0.45);
    border-radius: 18px;
    color: #f8fafc;
    font-weight: 900;
}
QTableWidget {
    background: rgba(2, 8, 23, 0.42);
    alternate-background-color: rgba(15, 23, 42, 0.72);
    border: 1px solid rgba(59, 130, 246, 0.28);
    border-radius: 14px;
    gridline-color: rgba(59, 130, 246, 0.12);
    selection-background-color: rgba(0, 123, 255, 0.35);
    selection-color: #ffffff;
}
QHeaderView::section {
    background: rgba(6, 16, 31, 0.95);
    border: none;
    border-bottom: 1px solid rgba(59, 130, 246, 0.28);
    color: #cbd5e1;
}
QTableWidget::item {
    color: #dbeafe;
    border-bottom: 1px solid rgba(59, 130, 246, 0.08);
}
QTableWidget::item:hover {
    background: rgba(0, 170, 255, 0.10);
}
#resultText {
    color: #cbd5e1;
}
#statusbar {
    background: rgba(6, 16, 31, 0.9);
    border-top: 1px solid rgba(59, 130, 246, 0.28);
}
QScrollBar:vertical {
    background: rgba(15, 23, 42, 0.55);
    width: 10px;
}
QScrollBar::handle:vertical {
    background: rgba(0, 170, 255, 0.45);
    border-radius: 5px;
}

/* Global cleanup: keep structural widgets transparent so helper wrappers and
   labels do not paint horizontal dark bands behind content. */
QWidget {
    background: transparent;
}
QFrame {
    background: transparent;
}
QLabel {
    background: transparent;
}
QScrollArea {
    background: transparent;
}
QScrollArea QWidget {
    background: transparent;
}
#loginDialog {
    background: #06101f;
}
#shell, #page, #pageScroll {
    background: qradialgradient(cx:0.8, cy:0.05, radius:0.9, fx:0.8, fy:0.05, stop:0 rgba(0, 123, 255, 0.35), stop:0.35 #06101f, stop:1 #020817);
}
#sidebar {
    background: qlineargradient(x1:0 y1:0, x2:0 y2:1, stop:0 #06101f, stop:1 #020817);
}
#headerPanel, #card, #section, #metricStrip {
    background: rgba(15, 23, 42, 0.85);
}
#greenCard {
    background: qlineargradient(x1:0 y1:0, x2:1 y2:1, stop:0 rgba(15, 23, 42, 0.88), stop:1 rgba(6, 78, 59, 0.55));
}
#statusbar {
    background: rgba(6, 16, 31, 0.9);
}
QTableWidget {
    background: rgba(2, 8, 23, 0.42);
    alternate-background-color: rgba(15, 23, 42, 0.72);
}
QHeaderView::section {
    background: rgba(6, 16, 31, 0.95);
}
QLineEdit, QComboBox, QPushButton {
    background: rgba(2, 8, 23, 0.76);
}
#navButton {
    background: transparent;
}
#primaryButton, #navButton:checked {
    background: qlineargradient(x1:0 y1:0, x2:1 y2:0, stop:0 #007bff, stop:1 #00aaff);
}
#loginDialog {
    background: qradialgradient(cx:0.8, cy:0.0, radius:1.0, fx:0.8, fy:0.0, stop:0 rgba(0, 170, 255, 0.18), stop:0.42 #06101f, stop:1 #020817);
}
#loginHero {
    background: rgba(15, 23, 42, 0.86);
    border: 1px solid rgba(59, 130, 246, 0.38);
    border-radius: 20px;
}
#loginBrand {
    color: #f8fafc;
    font-size: 26px;
    font-weight: 900;
}
#loginStatus {
    color: #f87171;
    font-weight: 700;
}
#navButton {
    padding-left: 16px;
    padding-right: 12px;
    min-height: 40px;
    text-align: left;
}
#navButton[collapsed="true"] {
    padding: 9px;
    min-width: 42px;
    max-width: 42px;
    min-height: 42px;
    max-height: 42px;
    text-align: center;
}
#sidebarToggle {
    background: rgba(15, 23, 42, 0.70);
    border: 1px solid rgba(59, 130, 246, 0.35);
    border-radius: 12px;
    color: #f8fafc;
    min-width: 38px;
    max-width: 38px;
    min-height: 34px;
    max-height: 34px;
    padding: 0;
    font-size: 16px;
    font-weight: 900;
    qproperty-iconSize: 20px 20px;
}
#sidebarToggle:hover {
    background: rgba(0, 123, 255, 0.20);
    border: 1px solid rgba(0, 170, 255, 0.85);
}
#topIconButton {
    min-width: 36px;
    max-width: 36px;
    min-height: 36px;
    max-height: 36px;
}
QTableWidget {
    font-size: 11px;
}
QTableWidget::item {
    padding: 8px 9px;
}
QHeaderView::section {
    padding: 8px 10px;
}
QMessageBox {
    background: #06101f;
    border: 1px solid rgba(59, 130, 246, 0.45);
    border-radius: 18px;
}
QMessageBox QLabel {
    color: #f8fafc;
    font-size: 13px;
    line-height: 145%;
    background: transparent;
}
QMessageBox QPushButton {
    min-width: 92px;
    min-height: 32px;
    padding: 7px 16px;
    background: rgba(15, 23, 42, 0.95);
    border: 1px solid rgba(59, 130, 246, 0.45);
    border-radius: 10px;
    color: #f8fafc;
    font-weight: 800;
}
QMessageBox QPushButton:hover {
    background: rgba(0, 123, 255, 0.22);
    border: 1px solid rgba(0, 170, 255, 0.85);
}
QToolTip {
    background-color: #0f172a;
    color: #f8fafc;
    border: 1px solid #00aaff;
    border-radius: 8px;
    padding: 8px 10px;
    font-size: 12px;
    font-weight: 700;
}
#projectDetailsPage {
    background: transparent;
}
#projectDetailsSidebar {
    background: rgba(6, 16, 31, 0.82);
    border: 1px solid rgba(59, 130, 246, 0.35);
    border-radius: 18px;
}
#projectDetailsHeader,
#projectDetailsContent {
    background: transparent;
}
#projectDetailsEyebrow {
    color: #00aaff;
    font-size: 10px;
    font-weight: 900;
    letter-spacing: 1px;
    text-transform: uppercase;
}
#projectDetailsSidebarTitle {
    color: #f8fafc;
    font-size: 14px;
    font-weight: 900;
    line-height: 140%;
}
#projectDetailsNavButton {
    background: transparent;
    color: #cbd5e1;
    border: 1px solid transparent;
    border-radius: 12px;
    padding: 10px 12px;
    text-align: left;
    font-weight: 800;
}
#projectDetailsNavButton:hover {
    background: rgba(0, 123, 255, 0.14);
    border: 1px solid rgba(59, 130, 246, 0.38);
}
#projectDetailsNavButton:checked {
    background: rgba(0, 123, 255, 0.28);
    border: 1px solid rgba(0, 170, 255, 0.8);
    color: #ffffff;
}
#projectDetailsHeader,
#projectMetricCard,
#projectInfoBox,
#projectHistoryRow {
    background: rgba(15, 23, 42, 0.85);
    border: 1px solid rgba(59, 130, 246, 0.35);
    border-radius: 16px;
}
#projectMetricCard:hover,
#projectInfoBox:hover,
#projectHistoryRow:hover {
    border: 1px solid rgba(0, 170, 255, 0.7);
    background: rgba(15, 23, 42, 0.96);
}
#projectStatusBadge {
    background: rgba(0, 123, 255, 0.18);
    border: 1px solid rgba(0, 170, 255, 0.65);
    border-radius: 14px;
    color: #f8fafc;
    font-weight: 900;
    padding: 8px 14px;
    min-width: 120px;
}
"""


class SolarProWindow(QMainWindow):
    def __init__(self, sync_client=None, current_user=None):
        super().__init__()
        initialize_database()
        self.sync_client = sync_client
        self.current_user = current_user or OFFLINE_USER
        self.clients = []
        self.budgets = []
        self.project_payments = []
        self.active_budget = None
        self.project_service = ProjectService()
        self.bill_importer_service = BillImporterService()
        self.project_documents = ProjectDocuments()

        self.setWindowTitle("Solar Pro")
        self.setWindowIcon(app_icon())
        self.resize(1280, 760)
        self.setMinimumSize(1000, 640)

        self.stack = QStackedWidget()
        self.nav_buttons = []
        self.sidebar_expanded_width = 218
        self.sidebar_collapsed_width = 72
        self.settings = QSettings("SolarPro", "SolarPro")
        self.sidebar_collapsed = (
            self.settings.value("ui/sidebar_collapsed", False, type=bool)
        )
        self.sidebar_animation = None
        self.sidebar_text_widgets = []
        self.sidebar_card_widgets = []
        self.client_inputs = {}
        self.editing_client_id = None
        self.selected_client_id = None
        self.monthly_consumption_inputs = []
        self.monthly_hsp_inputs = []
        self.sizing_preview_timer = QTimer(self)
        self.sizing_preview_timer.setSingleShot(True)
        self.sizing_preview_timer.setInterval(180)
        self.sizing_preview_timer.timeout.connect(self.update_sizing_preview)
        self.permission_key = self.normalize_permission(
            self.current_user.permissao
        )

        root = QWidget()
        root_layout = QHBoxLayout(root)
        root_layout.setContentsMargins(0, 0, 0, 0)
        root_layout.setSpacing(0)

        root_layout.addWidget(self.build_sidebar())
        root_layout.addWidget(self.build_main_area(), 1)
        self.setCentralWidget(root)

        self.apply_styles()
        self.refresh_all()
        self.apply_permissions()
        self.show_page(0)
        if self.current_user.matricula == "offline":
            self.status_label.setText("Modo offline: usando banco local")
        else:
            self.status_label.setText(
                f"Conectado como {self.current_user.nome}"
            )

    def kit_icon(self, name):
        return QIcon(str(resource_path(f"assets/ui_kit/{name}.png")))

    def svg_icon(self, name):
        return QIcon(str(resource_path(f"assets/icons/{name}.svg")))

    def build_sidebar(self):
        sidebar = QFrame()
        sidebar.setObjectName("sidebar")
        self.sidebar = sidebar
        sidebar.setMinimumWidth(self.sidebar_expanded_width)
        sidebar.setMaximumWidth(self.sidebar_expanded_width)
        layout = QVBoxLayout(sidebar)
        layout.setContentsMargins(12, 16, 12, 14)
        layout.setSpacing(12)
        self.sidebar_layout = layout

        toggle_row = QHBoxLayout()
        toggle_row.setContentsMargins(0, 0, 0, 0)
        toggle_row.addStretch()
        self.sidebar_toggle = QPushButton()
        self.sidebar_toggle.setObjectName("sidebarToggle")
        self.sidebar_toggle.setIcon(self.svg_icon("sidebar-collapse"))
        self.sidebar_toggle.setIconSize(QSize(20, 20))
        self.sidebar_toggle.setToolTip("Recolher menu")
        self.sidebar_toggle.clicked.connect(self.toggle_sidebar)
        toggle_row.addWidget(self.sidebar_toggle)
        layout.addLayout(toggle_row)

        role = self.display_role()
        user_text = (
            f"{self.current_user.nome}\n"
            f"Matrícula: {self.current_user.matricula}\n"
            f"Cargo: {role or '-'}"
        )
        user_badge = QLabel(user_text)
        user_badge.setObjectName("userBadge")
        user_badge.setWordWrap(True)
        self.sidebar_text_widgets.append(user_badge)
        layout.addWidget(user_badge)

        logo = QLabel()
        self.sidebar_logo = logo
        logo.setFixedHeight(74)
        logo.setAlignment(Qt.AlignLeft | Qt.AlignVCenter)
        logo_pixmap = QPixmap(str(resource_path("assets/ui_kit/logo_horizontal.png")))
        if not logo_pixmap.isNull():
            self.sidebar_logo_pixmap = logo_pixmap
            logo.setPixmap(
                logo_pixmap.scaled(
                    190,
                    70,
                    Qt.KeepAspectRatio,
                    Qt.SmoothTransformation,
                )
            )
        layout.addWidget(logo)
        layout.addSpacing(10)

        items = [
            ("Painel de Projetos", "dashboard", 0, "view_dashboard"),
            ("Clientes", "clients", 1, "view_clients"),
            ("Projeto Técnico", "sizing", 2, "create_sizing"),
            ("Financeiro", "finance", 3, "use_financing"),
            ("Gráficos", "charts", 4, "view_charts"),
            ("Projetos", "budgets", 5, "view_budgets"),
        ]
        for text, icon_name, index, permission in items:
            button = QPushButton(text)
            button.setObjectName("navButton")
            button.setIcon(self.svg_icon(icon_name))
            button.setIconSize(QSize(18, 18))
            button.setCheckable(True)
            button.setToolTip(text)
            button.setProperty("expanded_text", text)
            button.setEnabled(self.can(permission))
            if not self.can(permission):
                button.setToolTip("Seu perfil não tem acesso a esta área.")
            button.clicked.connect(lambda checked=False, page=index: self.show_page(page))
            self.nav_buttons.append(button)
            layout.addWidget(button)

        layout.addStretch()
        green_card = QFrame()
        green_card.setObjectName("greenCard")
        self.sidebar_card_widgets.append(green_card)
        green_layout = QVBoxLayout(green_card)
        green_layout.setContentsMargins(12, 12, 12, 12)
        green_title = QLabel("Energia limpa")
        green_title.setObjectName("greenTitle")
        green_text = QLabel("futuro sustentável.")
        green_text.setObjectName("greenText")
        green_layout.addWidget(green_title)
        green_layout.addWidget(green_text)
        layout.addWidget(green_card)

        version = QLabel("Versão 2.0.0")
        version.setObjectName("sidebarFooter")
        self.sidebar_text_widgets.append(version)
        layout.addWidget(version)
        powered = QLabel("Powered by Kevin Klécio © 2026")
        powered.setObjectName("poweredBy")
        powered.setWordWrap(True)
        self.sidebar_text_widgets.append(powered)
        layout.addWidget(powered)
        self.apply_sidebar_state(animated=False)
        return sidebar

    def toggle_sidebar(self):
        self.sidebar_collapsed = not self.sidebar_collapsed
        self.settings.setValue("ui/sidebar_collapsed", self.sidebar_collapsed)
        self.apply_sidebar_state(animated=True)

    def apply_sidebar_state(self, animated=True):
        target_width = (
            self.sidebar_collapsed_width
            if self.sidebar_collapsed
            else self.sidebar_expanded_width
        )

        self.update_sidebar_contents()

        if not animated:
            self.sidebar.setMinimumWidth(target_width)
            self.sidebar.setMaximumWidth(target_width)
            return

        self.sidebar_animation = QParallelAnimationGroup(self)
        for property_name in (b"minimumWidth", b"maximumWidth"):
            animation = QPropertyAnimation(self.sidebar, property_name)
            animation.setDuration(220)
            animation.setStartValue(self.sidebar.width())
            animation.setEndValue(target_width)
            animation.setEasingCurve(QEasingCurve.OutCubic)
            self.sidebar_animation.addAnimation(animation)
        self.sidebar_animation.start()

    def update_sidebar_contents(self):
        collapsed = self.sidebar_collapsed
        self.sidebar_toggle.setToolTip(
            "Expandir menu" if collapsed else "Recolher menu"
        )
        self.sidebar_toggle.setText("")
        self.sidebar_toggle.setIcon(
            self.svg_icon("sidebar-expand" if collapsed else "sidebar-collapse")
        )
        self.sidebar_toggle.setIconSize(QSize(20, 20))

        for widget in self.sidebar_text_widgets + self.sidebar_card_widgets:
            widget.setVisible(not collapsed)

        if hasattr(self, "sidebar_logo"):
            if collapsed:
                icon_pixmap = QPixmap(str(resource_path("assets/app_icon.png")))
                if not icon_pixmap.isNull():
                    self.sidebar_logo.setPixmap(
                        icon_pixmap.scaled(
                            42,
                            42,
                            Qt.KeepAspectRatio,
                            Qt.SmoothTransformation,
                        )
                    )
                self.sidebar_logo.setFixedHeight(52)
                self.sidebar_logo.setAlignment(Qt.AlignCenter)
            else:
                logo_pixmap = getattr(self, "sidebar_logo_pixmap", QPixmap())
                if not logo_pixmap.isNull():
                    self.sidebar_logo.setPixmap(
                        logo_pixmap.scaled(
                            190,
                            70,
                            Qt.KeepAspectRatio,
                            Qt.SmoothTransformation,
                        )
                    )
                self.sidebar_logo.setFixedHeight(74)
                self.sidebar_logo.setAlignment(Qt.AlignLeft | Qt.AlignVCenter)

        for button in self.nav_buttons:
            text = button.property("expanded_text") or ""
            button.setProperty("collapsed", collapsed)
            button.setText("" if collapsed else text)
            button.setIconSize(QSize(22, 22) if collapsed else QSize(18, 18))
            button.style().unpolish(button)
            button.style().polish(button)

        if collapsed:
            self.sidebar_layout.setContentsMargins(10, 16, 10, 14)
        else:
            self.sidebar_layout.setContentsMargins(12, 16, 12, 14)

    def build_main_area(self):
        shell = QFrame()
        shell.setObjectName("shell")
        layout = QVBoxLayout(shell)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        content = QWidget()
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(20, 16, 20, 0)
        content_layout.setSpacing(12)

        header_frame = QFrame()
        header_frame.setObjectName("headerPanel")
        header_layout = QHBoxLayout(header_frame)
        header_layout.setContentsMargins(16, 14, 16, 14)
        header_layout.setSpacing(14)

        title_box = QVBoxLayout()
        title_box.setSpacing(4)
        self.page_title = QLabel("Painel de Projetos")
        self.page_title.setObjectName("pageTitle")
        subtitle = QLabel("Gerencie clientes, projetos e acompanhe o progresso dos projetos.")
        subtitle.setObjectName("pageSubtitle")
        subtitle.setWordWrap(True)
        subtitle.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        title_box.addWidget(self.page_title)
        title_box.addWidget(subtitle)

        header_layout.addLayout(title_box, 1)

        status_widget = QWidget()
        status_layout = QHBoxLayout(status_widget)
        status_layout.setSpacing(10)
        status_layout.setContentsMargins(0, 0, 0, 0)
        project_label = QLabel("Projeto atual")
        project_label.setObjectName("muted")
        self.current_project = QComboBox()
        self.current_project.setMinimumWidth(220)
        self.current_project.setMaximumWidth(270)
        self.configure_combo(self.current_project)
        self.current_project.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)
        status_layout.addWidget(project_label)
        status_layout.addWidget(self.current_project)
        header_layout.addWidget(status_widget)

        action_box = QVBoxLayout()
        action_box.setSpacing(10)
        action_box.setContentsMargins(0, 0, 0, 0)
        new_button = QPushButton("Novo Projeto")
        new_button.setObjectName("primaryButton")
        new_button.setMinimumHeight(34)
        new_button.clicked.connect(lambda: self.show_page(2))
        self.new_budget_button = new_button
        action_box.addWidget(new_button)
        header_layout.addLayout(action_box)

        content_layout.addWidget(header_frame)

        self.stack.addWidget(self.dashboard_page())
        self.stack.addWidget(self.clients_page())
        self.stack.addWidget(self.sizing_page())
        self.stack.addWidget(self.finance_page())
        self.stack.addWidget(self.charts_page())
        self.stack.addWidget(self.budgets_page())
        self.stack.addWidget(self.project_details_page())
        content_layout.addWidget(self.stack, 1)

        statusbar = QFrame()
        statusbar.setObjectName("statusbar")
        status_layout = QHBoxLayout(statusbar)
        status_layout.setContentsMargins(22, 7, 22, 7)
        self.status_label = QLabel("Sistema pronto para uso")
        self.clock_label = QLabel(datetime.now().strftime("%d/%m/%Y %H:%M"))
        status_layout.addWidget(self.status_label)
        status_layout.addStretch()
        status_layout.addWidget(self.clock_label)

        layout.addWidget(content, 1)
        layout.addWidget(statusbar)
        return shell

    def wrap_scroll(self, widget):
        widget.setObjectName("page")
        scroll = QScrollArea()
        scroll.setObjectName("pageScroll")
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.viewport().setAutoFillBackground(False)
        scroll.setWidget(widget)
        return scroll

    def dashboard_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 8, 0)
        layout.setSpacing(14)

        self.status_card_grid = QGridLayout()
        self.status_card_grid.setHorizontalSpacing(12)
        self.status_card_grid.setVerticalSpacing(12)
        for column in range(5):
            self.status_card_grid.setColumnStretch(column, 1)
        layout.addLayout(self.status_card_grid)

        body = QHBoxLayout()
        body.setSpacing(14)

        left_column = QVBoxLayout()
        left_column.setSpacing(14)
        self.value_card_grid = QGridLayout()
        self.value_card_grid.setHorizontalSpacing(12)
        self.value_card_grid.setVerticalSpacing(12)
        for column in range(3):
            self.value_card_grid.setColumnStretch(column, 1)
        left_column.addLayout(self.value_card_grid)

        section = Section("Resumo de projetos")
        self.dashboard_table = QTableWidget(0, 7)
        self.dashboard_table.setHorizontalHeaderLabels([
            "Cliente", "Status", "Data", "kWp", "Geração anual", "Valor", "Payback"
        ])
        self.setup_table(self.dashboard_table)
        self.apply_table_layout(
            self.dashboard_table,
            [180, 150, 92, 72, 132, 118, 94],
            stretch_column=0,
        )
        self.dashboard_table.setMinimumHeight(310)
        self.dashboard_table.doubleClicked.connect(
            lambda index: self.open_project_details_from_table(self.dashboard_table)
        )
        section.layout.addWidget(self.dashboard_table)
        view_all = QPushButton("Ver todos os projetos")
        view_all.setObjectName("secondaryButton")
        view_all.clicked.connect(lambda: self.show_page(5))
        section.layout.addWidget(view_all, alignment=Qt.AlignLeft)
        left_column.addWidget(section, 1)
        body.addLayout(left_column, 5)

        right_column = QVBoxLayout()
        right_column.setSpacing(14)
        self.sales_funnel_card = SalesFunnelCard()
        self.recent_activities_card = RecentActivitiesCard()
        right_column.addWidget(self.sales_funnel_card)
        right_column.addWidget(self.recent_activities_card)
        right_column.addStretch()
        body.addLayout(right_column, 3)
        layout.addLayout(body, 1)
        return self.wrap_scroll(page)

    def clients_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)

        form = Section("Cadastrar Cliente")
        grid = QGridLayout()
        grid.setHorizontalSpacing(10)
        grid.setVerticalSpacing(8)
        for column in range(3):
            grid.setColumnStretch(column, 1)
        fields = [
            ("name", "Nome", "Nome completo"),
            ("document", "CPF/CNPJ", "000.000.000-00"),
            ("phone", "Telefone", "(00) 00000-0000"),
            ("email", "Email", "email@exemplo.com"),
            ("city", "Cidade", "Cidade"),
        ]
        for index, (key, label, placeholder) in enumerate(fields):
            box = QVBoxLayout()
            box.addWidget(QLabel(label))
            entry = QLineEdit()
            entry.setPlaceholderText(placeholder)
            self.client_inputs[key] = entry
            box.addWidget(entry)
            grid.addLayout(box, index // 3, index % 3)

        state_box = QVBoxLayout()
        state_box.addWidget(QLabel("Estado"))
        self.client_state = QComboBox()
        self.configure_combo(self.client_state, 8)
        self.client_state.addItems(BRAZIL_STATES)
        state_box.addWidget(self.client_state)
        grid.addLayout(state_box, 1, 2)
        form.layout.addLayout(grid)

        actions = QHBoxLayout()
        actions.setContentsMargins(0, 10, 0, 0)
        actions.addStretch()
        self.client_save_button = QPushButton("Salvar Cliente")
        self.client_save_button.setObjectName("primaryButton")
        self.client_save_button.setMinimumWidth(130)
        self.client_save_button.clicked.connect(self.save_client)
        clear = QPushButton("Limpar")
        clear.setMinimumWidth(92)
        clear.clicked.connect(self.clear_client_form)
        actions.addWidget(self.client_save_button)
        actions.addWidget(clear)
        form.layout.addLayout(actions)
        layout.addWidget(form)

        table_section = Section("Lista de Clientes")
        search_line = QHBoxLayout()
        self.client_search = QLineEdit()
        self.client_search.setPlaceholderText("Buscar cliente...")
        self.client_search.textChanged.connect(self.populate_clients_table)
        self.edit_client_button = QPushButton("Editar selecionado")
        self.edit_client_button.clicked.connect(self.load_selected_client)
        self.delete_client_button = QPushButton("Excluir cliente")
        self.delete_client_button.clicked.connect(self.delete_selected_client)
        search_line.addStretch()
        search_line.addWidget(self.client_search)
        search_line.addWidget(self.edit_client_button)
        search_line.addWidget(self.delete_client_button)
        table_section.layout.addLayout(search_line)
        self.clients_table = QTableWidget(0, 6)
        self.clients_table.setHorizontalHeaderLabels([
            "Nome", "CPF/CNPJ", "Telefone", "Email", "Cidade", "Estado"
        ])
        self.setup_table(self.clients_table)
        self.apply_table_layout(
            self.clients_table,
            [190, 130, 136, 220, 150, 72],
            stretch_column=3,
        )
        self.clients_table.setMinimumHeight(190)
        self.clients_table.itemSelectionChanged.connect(
            self.sync_selected_client
        )
        self.clients_table.doubleClicked.connect(
            lambda index: self.load_selected_client()
        )
        table_section.layout.addWidget(self.clients_table)
        layout.addWidget(table_section, 1)

        history_section = Section("Projetos do cliente")
        history_actions = QHBoxLayout()
        self.client_history_label = QLabel("Selecione um cliente para ver o histórico.")
        self.client_history_label.setObjectName("muted")
        new_for_client = QPushButton("Novo para este cliente")
        new_for_client.setObjectName("primaryButton")
        new_for_client.clicked.connect(self.start_sizing_for_selected_client)
        self.new_client_budget_button = new_for_client
        self.duplicate_budget_button = QPushButton("Duplicar projeto")
        self.duplicate_budget_button.clicked.connect(
            self.duplicate_selected_client_budget
        )
        history_actions.addWidget(self.client_history_label, 1)
        history_actions.addWidget(new_for_client)
        history_actions.addWidget(self.duplicate_budget_button)
        history_section.layout.addLayout(history_actions)
        self.client_budgets_table = QTableWidget(0, 7)
        self.client_budgets_table.setHorizontalHeaderLabels([
            "ID", "Data", "Status", "kWp", "Módulos", "Valor", "Payback"
        ])
        self.setup_table(self.client_budgets_table)
        self.apply_table_layout(
            self.client_budgets_table,
            [58, 92, 150, 82, 82, 126, 102],
            stretch_column=2,
        )
        self.client_budgets_table.setMinimumHeight(170)
        self.client_budgets_table.doubleClicked.connect(
            lambda index: self.duplicate_selected_client_budget()
        )
        history_section.layout.addWidget(self.client_budgets_table)
        layout.addWidget(history_section, 1)
        return self.wrap_scroll(page)

    def sizing_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)

        body = QHBoxLayout()
        body.setSpacing(12)

        form = Section("Novo Projeto Técnico")
        top_grid = QGridLayout()
        top_grid.setHorizontalSpacing(10)
        top_grid.setVerticalSpacing(8)
        for column in range(3):
            top_grid.setColumnStretch(column, 1)
        self.sizing_client = QComboBox()
        self.configure_combo(self.sizing_client)
        self.sizing_status = QComboBox()
        self.configure_combo(self.sizing_status)
        self.sizing_status.addItems(STATUSES)
        self.performance_ratio = QLineEdit("0,80")
        self.module_power = QLineEdit("550")
        self.energy_tariff = QLineEdit("0,95")
        self.extra_percent = QLineEdit("10")
        self.sizing_realtime_fields = [
            self.performance_ratio,
            self.module_power,
            self.energy_tariff,
            self.extra_percent,
        ]
        widgets = [
            ("Cliente", self.sizing_client),
            ("Status", self.sizing_status),
            ("Performance ratio", self.performance_ratio),
            ("Módulo W", self.module_power),
            ("Tarifa R$/kWh", self.energy_tariff),
            ("% geração extra", self.extra_percent),
        ]
        for index, (label, widget) in enumerate(widgets):
            box = QVBoxLayout()
            box.addWidget(QLabel(label))
            box.addWidget(widget)
            top_grid.addLayout(box, index // 3, index % 3)
        form.layout.addLayout(top_grid)

        monthly_grid = QGridLayout()
        monthly_grid.setHorizontalSpacing(8)
        monthly_grid.setVerticalSpacing(6)
        for column in range(4):
            monthly_grid.setColumnStretch(column, 1)
        self.monthly_consumption_inputs.clear()
        self.monthly_hsp_inputs.clear()
        for index, month in enumerate(MONTHS):
            month_box = QVBoxLayout()
            month_box.addWidget(QLabel(month))
            consumption = QLineEdit("500")
            hsp = QLineEdit("5,0")
            month_box.addWidget(consumption)
            month_box.addWidget(hsp)
            self.monthly_consumption_inputs.append(consumption)
            self.monthly_hsp_inputs.append(hsp)
            self.sizing_realtime_fields.extend([consumption, hsp])
            monthly_grid.addLayout(month_box, index // 4, index % 4)
        form.layout.addWidget(QLabel("Consumo kWh / HSP por mês"))
        form.layout.addLayout(monthly_grid)

        actions = QHBoxLayout()
        actions.addStretch()
        import_bill = QPushButton("Importar fatura PDF")
        import_bill.setObjectName("secondaryButton")
        import_bill.clicked.connect(self.import_bill_to_sizing_form)
        actions.addWidget(import_bill)
        calculate = QPushButton("Calcular e Salvar")
        calculate.setObjectName("primaryButton")
        calculate.clicked.connect(self.save_sizing)
        actions.addWidget(calculate)
        form.layout.addLayout(actions)
        body.addWidget(form, 5)

        preview = Section("Prévia em tempo real")
        self.sizing_preview_status = QLabel("Altere os campos para recalcular.")
        self.sizing_preview_status.setObjectName("muted")
        preview.layout.addWidget(self.sizing_preview_status)
        self.sizing_preview_values = {}
        for key, label in [
            ("system_power", "Potência instalada"),
            ("module_count", "Quantidade de módulos"),
            ("annual_generation", "Produção anual"),
            ("annual_savings", "Economia anual"),
            ("payback_years", "Payback"),
        ]:
            metric = QFrame()
            metric.setObjectName("metricStrip")
            metric_layout = QVBoxLayout(metric)
            metric_layout.setContentsMargins(12, 9, 12, 9)
            metric_layout.setSpacing(2)
            title = QLabel(label)
            title.setObjectName("metricLabel")
            value = QLabel("-")
            value.setObjectName("metricValue")
            value.setWordWrap(True)
            metric_layout.addWidget(title)
            metric_layout.addWidget(value)
            preview.layout.addWidget(metric)
            self.sizing_preview_values[key] = value
        preview.layout.addStretch()
        body.addWidget(preview, 2)
        layout.addLayout(body)

        result = Section("Resultado técnico")
        self.sizing_result = QLabel("Preencha os dados e salve o projeto técnico.")
        self.sizing_result.setObjectName("resultText")
        result.layout.addWidget(self.sizing_result)
        layout.addWidget(result)
        self.connect_sizing_realtime_signals()
        self.schedule_sizing_preview_update()
        return self.wrap_scroll(page)

    def connect_sizing_realtime_signals(self):
        for field in self.sizing_realtime_fields:
            field.textChanged.connect(self.schedule_sizing_preview_update)
        self.sizing_client.currentIndexChanged.connect(
            self.schedule_sizing_preview_update
        )
        self.sizing_status.currentIndexChanged.connect(
            self.schedule_sizing_preview_update
        )

    def schedule_sizing_preview_update(self, *args):
        if hasattr(self, "sizing_preview_timer"):
            self.sizing_preview_timer.start()

    def read_sizing_data(self, show_errors=False):
        try:
            monthly_consumptions = [
                parse_float(entry) for entry in self.monthly_consumption_inputs
            ]
            monthly_hsp = [
                parse_float(entry) for entry in self.monthly_hsp_inputs
            ]
            inputs = {
                "monthly_consumptions": monthly_consumptions,
                "monthly_hsp": monthly_hsp,
                "performance_ratio": parse_float(self.performance_ratio),
                "module_power": parse_float(self.module_power),
                "energy_tariff": parse_float(self.energy_tariff),
                "generation_extra_percent": parse_float(self.extra_percent),
            }
            if inputs["module_power"] <= 0 or inputs["performance_ratio"] <= 0:
                raise ValueError
            if any(value < 0 for value in monthly_consumptions):
                raise ValueError
            if any(value <= 0 for value in monthly_hsp):
                raise ValueError
            return inputs, calculate_sizing(**inputs)
        except (ValueError, ZeroDivisionError):
            if show_errors:
                self.warn("Confira os campos numéricos do projeto técnico.")
            return None, None

    def update_sizing_preview(self):
        if not hasattr(self, "sizing_preview_values"):
            return

        inputs, results = self.read_sizing_data(show_errors=False)
        if not results:
            self.sizing_preview_status.setText(
                "Preencha os campos técnicos para visualizar a prévia."
            )
            for value in self.sizing_preview_values.values():
                value.setText("-")
            return

        annual_savings = results["monthly_savings"] * 12
        payback = results.get("payback_years", 0)
        self.sizing_preview_status.setText(
            "Prévia atualizada automaticamente."
        )
        self.sizing_preview_values["system_power"].setText(
            f"{number(results['system_power'])} kWp"
        )
        self.sizing_preview_values["module_count"].setText(
            str(results["module_count"])
        )
        self.sizing_preview_values["annual_generation"].setText(
            f"{number(results['annual_generation'])} kWh"
        )
        self.sizing_preview_values["annual_savings"].setText(
            brl(annual_savings)
        )
        self.sizing_preview_values["payback_years"].setText(
            f"{number(payback)} anos" if payback else "Após financeiro"
        )

    def finance_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)

        summary = Section("Resumo financeiro")
        summary_grid = QGridLayout()
        summary_grid.setHorizontalSpacing(10)
        summary_grid.setVerticalSpacing(10)
        self.finance_summary_values = {}
        for index, (key, label) in enumerate([
            ("received", "Recebido"),
            ("pending", "Faltando pagar"),
            ("overdue", "Atrasado"),
        ]):
            metric = QFrame()
            metric.setObjectName("metricStrip")
            metric_layout = QVBoxLayout(metric)
            metric_layout.setContentsMargins(12, 9, 12, 9)
            metric_layout.setSpacing(2)
            title = QLabel(label)
            title.setObjectName("metricLabel")
            value = QLabel("-")
            value.setObjectName("metricValue")
            metric_layout.addWidget(title)
            metric_layout.addWidget(value)
            summary_grid.addWidget(metric, 0, index)
            self.finance_summary_values[key] = value
        summary.layout.addLayout(summary_grid)
        layout.addWidget(summary)

        form = Section("Plano financeiro do projeto")
        grid = QGridLayout()
        grid.setHorizontalSpacing(10)
        grid.setVerticalSpacing(8)
        for column in range(4):
            grid.setColumnStretch(column, 1)
        self.finance_budget = QComboBox()
        self.configure_combo(self.finance_budget, popup_width=520)
        self.finance_budget.currentIndexChanged.connect(self.load_selected_finance_project)
        self.finance_project_value = QLineEdit("0")
        self.finance_payment_type = QComboBox()
        self.configure_combo(self.finance_payment_type)
        self.finance_payment_type.addItems(PAYMENT_TYPES)
        self.finance_down_payment = QLineEdit("0")
        self.finance_discount = QLineEdit("0")
        self.finance_installments = QLineEdit("0")
        self.finance_installment_value = QLineEdit("0")
        self.finance_first_due_date = QLineEdit("")
        self.finance_first_due_date.setPlaceholderText("AAAA-MM-DD")
        fields = [
            ("Projeto", self.finance_budget),
            ("Valor do projeto", self.finance_project_value),
            ("Tipo de pagamento", self.finance_payment_type),
            ("Entrada", self.finance_down_payment),
            ("Desconto", self.finance_discount),
            ("Parcelas", self.finance_installments),
            ("Valor da parcela", self.finance_installment_value),
            ("Primeiro vencimento", self.finance_first_due_date),
        ]
        for index, (label, widget) in enumerate(fields):
            box = QVBoxLayout()
            box.addWidget(QLabel(label))
            box.addWidget(widget)
            grid.addLayout(box, index // 4, index % 4)
        form.layout.addLayout(grid)

        note_box = QVBoxLayout()
        note_box.addWidget(QLabel("Observações"))
        self.finance_notes = QTextEdit()
        self.finance_notes.setPlaceholderText("Condições combinadas, parcelas, descontos ou detalhes do pagamento.")
        self.finance_notes.setMaximumHeight(86)
        note_box.addWidget(self.finance_notes)
        form.layout.addLayout(note_box)

        actions = QHBoxLayout()
        actions.addStretch()
        save = QPushButton("Salvar plano financeiro")
        save.setObjectName("primaryButton")
        save.clicked.connect(self.save_financial_plan)
        self.finance_save_button = save
        actions.addWidget(save)
        form.layout.addLayout(actions)
        layout.addWidget(form)

        payment = Section("Registrar pagamento")
        payment_grid = QGridLayout()
        payment_grid.setHorizontalSpacing(10)
        payment_grid.setVerticalSpacing(8)
        self.finance_payment_amount = QLineEdit("0")
        self.finance_payment_method = QComboBox()
        self.configure_combo(self.finance_payment_method)
        self.finance_payment_method.addItems(PAYMENT_TYPES)
        self.finance_payment_date = QLineEdit(datetime.now().strftime("%Y-%m-%d"))
        self.finance_payment_notes = QLineEdit()
        self.finance_payment_notes.setPlaceholderText("Observação opcional")
        payment_fields = [
            ("Valor pago", self.finance_payment_amount),
            ("Tipo", self.finance_payment_method),
            ("Data", self.finance_payment_date),
            ("Observação", self.finance_payment_notes),
        ]
        for index, (label, widget) in enumerate(payment_fields):
            box = QVBoxLayout()
            box.addWidget(QLabel(label))
            box.addWidget(widget)
            payment_grid.addLayout(box, index // 4, index % 4)
        payment.layout.addLayout(payment_grid)
        payment_actions = QHBoxLayout()
        payment_actions.addStretch()
        add_payment = QPushButton("Adicionar pagamento")
        add_payment.setObjectName("primaryButton")
        add_payment.clicked.connect(self.add_project_payment)
        self.finance_add_payment_button = add_payment
        cancel_payment = QPushButton("Cancelar selecionado")
        cancel_payment.clicked.connect(self.cancel_selected_payment)
        self.finance_cancel_payment_button = cancel_payment
        payment_actions.addWidget(add_payment)
        payment_actions.addWidget(cancel_payment)
        payment.layout.addLayout(payment_actions)
        layout.addWidget(payment)

        result = Section("Situação do projeto")
        self.finance_result = QLabel("Selecione um projeto para ver recebidos, descontos e saldo.")
        self.finance_result.setObjectName("resultText")
        result.layout.addWidget(self.finance_result)
        self.finance_payments_table = QTableWidget(0, 5)
        self.finance_payments_table.setHorizontalHeaderLabels([
            "ID", "Data", "Tipo", "Valor", "Observação"
        ])
        self.setup_table(self.finance_payments_table)
        self.apply_table_layout(
            self.finance_payments_table,
            [58, 110, 138, 126, 260],
            stretch_column=4,
        )
        self.finance_payments_table.setMinimumHeight(190)
        result.layout.addWidget(self.finance_payments_table)
        layout.addWidget(result)
        return self.wrap_scroll(page)

    def charts_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        section = Section("Geração x Consumo")
        row = QHBoxLayout()
        self.chart_budget = QComboBox()
        self.configure_combo(self.chart_budget, popup_width=420)
        self.chart_budget.setMaximumWidth(520)
        self.chart_budget.currentIndexChanged.connect(self.update_chart)
        row.addWidget(QLabel("Projeto"))
        row.addWidget(self.chart_budget)
        row.addStretch()
        section.layout.addLayout(row)

        metrics = QHBoxLayout()
        metrics.setSpacing(8)
        self.chart_metric_labels = {}
        for key, label in [
            ("consumption", "Consumo anual"),
            ("generation", "Geração anual"),
            ("balance", "Saldo anual"),
            ("power", "Potência"),
        ]:
            metric = QFrame()
            metric.setObjectName("metricStrip")
            metric_layout = QVBoxLayout(metric)
            metric_layout.setContentsMargins(12, 8, 12, 8)
            metric_layout.setSpacing(2)
            title = QLabel(label)
            title.setObjectName("metricLabel")
            value = QLabel("-")
            value.setObjectName("metricValue")
            metric_layout.addWidget(title)
            metric_layout.addWidget(value)
            metrics.addWidget(metric)
            self.chart_metric_labels[key] = value
        section.layout.addLayout(metrics)

        self.chart = ChartWidget()
        section.layout.addWidget(self.chart)
        layout.addWidget(section)
        return self.wrap_scroll(page)

    def budgets_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(12)
        section = Section("Banco de Projetos")
        filters = QHBoxLayout()
        self.budget_search = QLineEdit()
        self.budget_search.setPlaceholderText("Buscar projeto...")
        self.budget_search.textChanged.connect(self.populate_budgets_table)
        self.status_filter = QComboBox()
        self.configure_combo(self.status_filter)
        self.status_filter.addItems(["Todos"] + STATUSES)
        self.status_filter.currentIndexChanged.connect(self.populate_budgets_table)
        filters.addWidget(self.budget_search, 1)
        filters.addWidget(self.status_filter)
        section.layout.addLayout(filters)

        self.budgets_table = QTableWidget(0, 9)
        self.budgets_table.setHorizontalHeaderLabels([
            "ID", "Cliente", "Status", "Data", "kWp", "Módulos",
            "Valor do projeto", "Parcela", "Payback"
        ])
        self.setup_table(self.budgets_table)
        self.apply_table_layout(
            self.budgets_table,
            [58, 190, 150, 92, 82, 82, 142, 126, 104],
            stretch_column=1,
        )
        self.budgets_table.setMinimumHeight(280)
        self.budgets_table.itemSelectionChanged.connect(self.sync_selected_budget)
        self.budgets_table.doubleClicked.connect(
            lambda index: self.open_project_details_from_table(self.budgets_table)
        )
        section.layout.addWidget(self.budgets_table)

        actions = QHBoxLayout()
        self.update_status_combo = QComboBox()
        self.configure_combo(self.update_status_combo)
        self.update_status_combo.addItems(STATUSES)
        details = QPushButton("Ver detalhes")
        details.clicked.connect(self.open_selected_project_details)
        self.project_details_button = details
        update = QPushButton("Atualizar Status")
        update.clicked.connect(self.change_selected_status)
        self.update_status_button = update
        self.delete_budget_button = QPushButton("Excluir Projeto")
        self.delete_budget_button.clicked.connect(self.delete_selected_budget)
        actions.addStretch()
        actions.addWidget(self.update_status_combo)
        actions.addWidget(details)
        actions.addWidget(update)
        actions.addWidget(self.delete_budget_button)
        section.layout.addLayout(actions)
        layout.addWidget(section)
        return self.wrap_scroll(page)

    def project_details_page(self):
        self.project_details = ProjectDetailsPage(
            on_back=lambda: self.show_page(5),
            on_dimensioning=self.open_project_dimensioning,
            on_financing=self.open_project_financing,
            on_upload_document=self.upload_project_document,
            on_open_document=self.open_project_document,
            on_delete_document=self.delete_project_document,
            document_categories=DOCUMENT_CATEGORIES,
        )
        return self.project_details

    def setup_table(self, table):
        table.setAlternatingRowColors(True)
        table.verticalHeader().setVisible(False)
        table.verticalHeader().setDefaultSectionSize(36)
        table.setSelectionBehavior(QTableWidget.SelectRows)
        table.setEditTriggers(QTableWidget.NoEditTriggers)
        table.setWordWrap(False)
        table.horizontalHeader().setStretchLastSection(False)
        table.horizontalHeader().setSectionResizeMode(QHeaderView.Interactive)
        table.setMinimumHeight(220)
        table.setShowGrid(False)

    def make_table_item(self, value):
        text = str(value)
        item = QTableWidgetItem(text)
        item.setToolTip(text)
        return item

    def apply_table_layout(self, table, widths, stretch_column=0):
        header = table.horizontalHeader()
        for column, width in enumerate(widths):
            header.setSectionResizeMode(column, QHeaderView.Interactive)
            table.setColumnWidth(column, width)
        if 0 <= stretch_column < table.columnCount():
            header.setSectionResizeMode(stretch_column, QHeaderView.Stretch)

    def apply_status_style(self, item, status):
        palette = {
            "Em negociação": ("#ff9800", "#ffb84d"),
            "Fechado": ("#48e13b", "#8ff486"),
            "Concluído": ("#00aaff", "#7dd3fc"),
            "Não aprovado": ("#8a3ffc", "#c4a5ff"),
        }
        dot_color, foreground = palette.get(status, ("#94a3b8", "#cbd5e1"))
        item.setText(f"● {status}")
        item.setToolTip(status)
        item.setForeground(QColor(foreground))
        font = item.font()
        font.setBold(True)
        item.setFont(font)

    def configure_combo(self, combo, max_items=6, popup_width=420):
        combo.setMaxVisibleItems(max_items)
        combo.setSizeAdjustPolicy(QComboBox.AdjustToMinimumContentsLengthWithIcon)
        combo.setMinimumContentsLength(18)
        combo.view().setObjectName("comboPopup")
        combo.view().setTextElideMode(Qt.ElideRight)
        combo.view().setMinimumWidth(min(popup_width, 420))
        combo.view().setMaximumWidth(popup_width)
        combo.view().setStyleSheet(
            """
            QListView#comboPopup {
                background: #06101f;
                color: #f8fafc;
                border: 1px solid rgba(0, 170, 255, 0.65);
                border-radius: 12px;
                padding: 6px;
                outline: 0;
            }
            QListView#comboPopup::item {
                min-height: 28px;
                padding: 7px 10px;
                color: #f8fafc;
                background: #06101f;
            }
            QListView#comboPopup::item:selected {
                color: #ffffff;
                background: #007bff;
            }
            """
        )

    def normalize_permission(self, permission):
        value = (permission or "").strip().lower()
        value = value.replace(" ", "_").replace("-", "_")
        aliases = {
            "projetos": "assessor_projetos",
            "assessor_de_projetos": "assessor_projetos",
            "assesor_de_projetos": "assessor_projetos",
            "assesor_projetos": "assessor_projetos",
            "assessor_projetos": "assessor_projetos",
            "daf": "assessor_daf",
            "assessor_daf": "assessor_daf",
            "assessor_do_daf": "assessor_daf",
            "assesor_do_daf": "assessor_daf",
            "diretor": "diretor",
            "admin": "diretor",
            "owner": "diretor",
            "usuario": "assessor_projetos",
            "offline": "offline",
        }
        return aliases.get(value, value or "assessor_projetos")

    def display_role(self):
        return ROLE_LABELS.get(
            self.permission_key,
            self.current_user.cargo or self.current_user.permissao or "-",
        )

    def can(self, permission):
        permissions = {
            "assessor_projetos": {
                "view_dashboard",
                "view_clients",
                "create_client",
                "create_sizing",
                "view_charts",
                "view_budgets",
            },
            "assessor_daf": {
                "view_dashboard",
                "view_clients",
                "create_client",
                "create_sizing",
                "use_financing",
                "view_charts",
                "view_budgets",
                "update_budget_status",
            },
            "diretor": {
                "view_dashboard",
                "view_clients",
                "create_client",
                "edit_client",
                "delete_client",
                "create_sizing",
                "use_financing",
                "view_charts",
                "view_budgets",
                "update_budget_status",
                "delete_budget",
            },
            "offline": {
                "view_dashboard",
                "view_clients",
                "create_client",
                "create_sizing",
                "use_financing",
                "view_charts",
                "view_budgets",
                "update_budget_status",
            },
        }
        return permission in permissions.get(self.permission_key, set())

    def require_permission(self, permission, message):
        if self.can(permission):
            return True
        self.warn(message)
        return False

    def apply_permissions(self):
        role = self.display_role()
        if hasattr(self, "status_label"):
            self.status_label.setToolTip(f"Perfil: {role}")

        controls = [
            ("client_save_button", "create_client"),
            ("edit_client_button", "edit_client"),
            ("delete_client_button", "delete_client"),
            ("new_client_budget_button", "create_sizing"),
            ("duplicate_budget_button", "create_sizing"),
            ("finance_save_button", "use_financing"),
            ("project_details_button", "view_budgets"),
            ("update_status_combo", "update_budget_status"),
            ("update_status_button", "update_budget_status"),
            ("delete_budget_button", "delete_budget"),
            ("new_budget_button", "create_sizing"),
        ]
        for attribute, permission in controls:
            widget = getattr(self, attribute, None)
            if widget is not None:
                allowed = self.can(permission)
                widget.setEnabled(allowed)
                if not allowed:
                    widget.setToolTip(
                        f"Perfil {role} não tem permissão para esta ação."
                    )

        if hasattr(self, "finance_result") and not self.can("use_financing"):
            self.finance_result.setText(
                "Seu perfil permite projeto técnico, mas não libera cálculo "
                "de financiamento."
            )

    def show_page(self, index):
        titles = [
            "Painel de Projetos",
            "Clientes",
            "Projeto Técnico",
            "Financeiro",
            "Gráficos",
            "Projetos",
            "Detalhes do Projeto",
        ]
        required = [
            "view_dashboard",
            "view_clients",
            "create_sizing",
            "use_financing",
            "view_charts",
            "view_budgets",
            "view_budgets",
        ]
        if index < len(required) and not self.can(required[index]):
            self.warn("Seu perfil não tem acesso a esta área.")
            return
        self.stack.setCurrentIndex(index)
        self.page_title.setText(titles[index])
        for button_index, button in enumerate(self.nav_buttons):
            button.setChecked(button_index == index)
        if index == 0 and hasattr(self, "dashboard_table"):
            self.refresh_dashboard()

    def refresh_all(self):
        self.clients = [row_to_dict(row) for row in list_clients()]
        self.budgets = [row_to_dict(row) for row in self.project_service.list()]
        self.project_payments = [
            row_to_dict(row)
            for row in self.project_service.list_payments()
        ]
        self.populate_client_combos()
        self.populate_budget_combos()
        self.populate_dashboard()
        self.populate_clients_table()
        self.populate_client_budgets_table()
        self.populate_budgets_table()
        self.update_financial_summary()
        if hasattr(self, "finance_budget") and self.finance_budget.currentData():
            self.load_selected_finance_project()
        self.update_chart()

    def refresh_dashboard(self):
        self.budgets = [row_to_dict(row) for row in self.project_service.list()]
        self.project_payments = [
            row_to_dict(row)
            for row in self.project_service.list_payments()
        ]
        self.populate_dashboard()

    def populate_client_combos(self):
        self.sizing_client.clear()
        for client in self.clients:
            self.sizing_client.addItem(client["name"], client["id"])

    def populate_budget_combos(self):
        combos = [self.finance_budget, self.chart_budget, self.current_project]
        for combo in combos:
            combo.blockSignals(True)
            combo.clear()
            for budget in self.budgets:
                label = f"#{budget['id']} - {budget['client_name']}"
                combo.addItem(label, budget["id"])
            combo.blockSignals(False)
        if hasattr(self, "finance_budget"):
            self.load_selected_finance_project()

    def update_financial_summary(self):
        if not hasattr(self, "finance_summary_values"):
            return

        received = sum(
            float(payment.get("amount") or 0)
            for payment in self.project_payments
            if payment.get("status") == "paid"
        )
        pending = sum(self.remaining_for_project(project) for project in self.budgets)
        overdue = 0
        today = datetime.now().date()
        for project in self.budgets:
            due_text = str(project.get("first_due_date") or "")
            due_date = None
            try:
                due_date = datetime.fromisoformat(due_text).date() if due_text else None
            except ValueError:
                due_date = None
            if due_date and due_date < today and self.remaining_for_project(project) > 0:
                overdue += self.remaining_for_project(project)

        self.finance_summary_values["received"].setText(brl(received))
        self.finance_summary_values["pending"].setText(brl(pending))
        self.finance_summary_values["overdue"].setText(brl(overdue))

    def populate_dashboard(self):
        for grid in (self.status_card_grid, self.value_card_grid):
            while grid.count():
                item = grid.takeAt(0)
                if item.widget():
                    item.widget().deleteLater()

        totals = get_dashboard_totals()
        status_cards = [
            ("Projetos", str(totals["budget_count"]), "Total geral", "#1d6cff", "orcamentos"),
            ("Em negociação", str(totals["negotiating"]), "Em andamento", "#ff9800", "negociacao"),
            ("Fechados", str(totals["closed"]), "Convertidos", "#48e13b", "fechados"),
            ("Concluídos", str(totals["completed"]), "Finalizados", "#00aaff", "concluidos"),
            ("Não aprovados", str(totals["not_approved"]), "Perdidos", "#8a3ffc", "nao_aprovados"),
        ]
        value_cards = [
            ("Receita prevista", brl(totals["forecast_revenue"]), "Pipeline válido", "#48e13b", "valor_total"),
            ("Receita fechada", brl(totals["closed_revenue"]), "Fechados + concluídos", "#00aaff", "recebimentos"),
            ("Taxa de conversão", f"{number(totals['conversion_rate'])}%", "Projetos convertidos", "#8a3ffc", "metas"),
            ("Potência vendida", f"{number(totals['sold_power'])} kWp", "Fechados + concluídos", "#007bff", "kwp_total"),
            ("Projetos ativos", str(totals["active_projects"]), "Negociação + fechados", "#ff9800", "orcamentos"),
        ]
        payment_totals = get_project_payment_totals()
        pending_total = sum(self.remaining_for_project(project) for project in self.budgets)
        value_cards.extend([
            ("Recebido no mês", brl(payment_totals["received_month"] or 0), "Pagamentos registrados", "#48e13b", "recebimentos"),
            ("Pendente", brl(pending_total), "Faltando pagar", "#ff9800", "pagamentos"),
            ("Recebido total", brl(payment_totals["received"] or 0), "Histórico financeiro", "#00aaff", "valor_total"),
        ])
        for index, args in enumerate(status_cards):
            self.status_card_grid.addWidget(Card(*args), 0, index)
        for index, args in enumerate(value_cards):
            self.value_card_grid.addWidget(Card(*args), index // 3, index % 3)

        if hasattr(self, "sales_funnel_card"):
            self.sales_funnel_card.set_data([
                ("Em negociação", totals["negotiating"], "#007bff"),
                ("Concluídos", totals["completed"], "#ff9800"),
                ("Fechados", totals["closed"], "#48e13b"),
                ("Não aprovados", totals["not_approved"], "#8a3ffc"),
            ])
        if hasattr(self, "recent_activities_card"):
            self.recent_activities_card.set_activities(
                self.build_recent_activities()
            )

        latest = self.budgets[:8]
        self.dashboard_table.setRowCount(len(latest))
        for row_index, budget in enumerate(latest):
            values = [
                budget["client_name"],
                budget["status"],
                budget["budget_date"],
                number(budget["system_power"]),
                f"{number(budget['annual_generation'])} kWh",
                brl(budget["investment"]),
                f"{number(budget['payback_years'])} anos" if budget["payback_years"] else "-",
            ]
            for column, value in enumerate(values):
                item = self.make_table_item(value)
                if column == 0:
                    item.setData(Qt.UserRole, budget["id"])
                if column == 1:
                    self.apply_status_style(item, str(value))
                self.dashboard_table.setItem(row_index, column, item)

    def build_recent_activities(self):
        activities = []
        colors = {
            "Em negociação": "#ff9800",
            "Fechado": "#48e13b",
            "Concluído": "#00aaff",
            "Não aprovado": "#8a3ffc",
        }
        icons = {
            "Em negociação": "negociacao",
            "Fechado": "fechados",
            "Concluído": "concluidos",
            "Não aprovado": "nao_aprovados",
        }
        for budget in self.budgets[:4]:
            status = budget["status"]
            activities.append({
                "icon": "",
                "icon_name": icons.get(status, "orcamentos"),
                "color": colors.get(status, "#007bff"),
                "title": f"Projeto #{budget['id']} - {status.lower()}",
                "subtitle": budget["client_name"],
                "date": budget["budget_date"],
            })
        return activities

    def populate_clients_table(self):
        text = self.client_search.text().strip().lower() if hasattr(self, "client_search") else ""
        filtered = [
            client for client in self.clients
            if not text or text in " ".join(str(v).lower() for v in client.values())
        ]
        self.clients_table.setRowCount(len(filtered))
        for row, client in enumerate(filtered):
            values = [
                client["name"], client["document"], client["phone"],
                client["email"], client["city"], client["state"],
            ]
            for column, value in enumerate(values):
                item = self.make_table_item(value)
                if column == 0:
                    item.setData(Qt.UserRole, client["id"])
                self.clients_table.setItem(row, column, item)

    def populate_client_budgets_table(self):
        if not hasattr(self, "client_budgets_table"):
            return

        if not self.selected_client_id:
            self.client_budgets_table.setRowCount(0)
            self.client_history_label.setText(
                "Selecione um cliente para ver o histórico."
            )
            return

        client = self.find_client(self.selected_client_id)
        client_budgets = [
            budget for budget in self.budgets
            if budget["client_id"] == self.selected_client_id
        ]
        self.client_history_label.setText(
            f"{client['name']}: {len(client_budgets)} projeto(s)"
            if client
            else f"{len(client_budgets)} projeto(s)"
        )
        self.client_budgets_table.setRowCount(len(client_budgets))
        for row, budget in enumerate(client_budgets):
            values = [
                budget["id"],
                budget["budget_date"],
                budget["status"],
                number(budget["system_power"]),
                budget["module_count"],
                brl(budget["investment"]),
                f"{number(budget['payback_years'])} anos"
                if budget["payback_years"]
                else "-",
            ]
            for column, value in enumerate(values):
                item = self.make_table_item(value)
                if column == 0:
                    item.setData(Qt.UserRole, budget["id"])
                if column == 2:
                    self.apply_status_style(item, str(value))
                self.client_budgets_table.setItem(row, column, item)

    def populate_budgets_table(self):
        text = self.budget_search.text().strip().lower() if hasattr(self, "budget_search") else ""
        selected_status = self.status_filter.currentText() if hasattr(self, "status_filter") else "Todos"
        filtered = []
        for budget in self.budgets:
            haystack = " ".join(str(v).lower() for v in budget.values())
            if text and text not in haystack:
                continue
            if selected_status != "Todos" and budget["status"] != selected_status:
                continue
            filtered.append(budget)

        self.budgets_table.setRowCount(len(filtered))
        for row, budget in enumerate(filtered):
            values = [
                budget["id"],
                budget["client_name"],
                budget["status"],
                budget["budget_date"],
                number(budget["system_power"]),
                budget["module_count"],
                brl(budget["investment"]),
                brl(budget["monthly_payment"]),
                f"{number(budget['payback_years'])} anos" if budget["payback_years"] else "-",
            ]
            for column, value in enumerate(values):
                item = self.make_table_item(value)
                if column == 0:
                    item.setData(Qt.UserRole, budget["id"])
                if column == 2:
                    self.apply_status_style(item, str(value))
                self.budgets_table.setItem(row, column, item)

    def save_client(self):
        if self.editing_client_id:
            if not self.require_permission(
                "edit_client",
                "Somente o perfil Diretor pode editar clientes.",
            ):
                return
        elif not self.require_permission(
            "create_client",
            "Seu perfil não pode cadastrar clientes.",
        ):
            return

        name = self.client_inputs["name"].text().strip()
        document = self.client_inputs["document"].text().strip()
        phone = self.client_inputs["phone"].text().strip()
        email = self.client_inputs["email"].text().strip()
        city = self.client_inputs["city"].text().strip()
        state = self.client_state.currentText()

        if not all([name, document, phone, email, city, state]):
            self.warn("Preencha todos os campos do cliente.")
            return
        if not validate_document(document):
            self.warn("CPF/CNPJ inválido.")
            return
        if not validate_phone(phone):
            self.warn("Telefone inválido.")
            return
        if not validate_email(email):
            self.warn("Email inválido.")
            return

        formatted_document = format_document(document)
        formatted_phone = format_phone(phone)
        normalized_email = email.strip().lower()

        if self.editing_client_id:
            update_client(
                self.editing_client_id,
                name,
                formatted_document,
                formatted_phone,
                normalized_email,
                city,
                state,
            )
            title = "Cliente atualizado"
            message = f"O cliente {name} foi atualizado com sucesso."
            action = "atualizou"
        else:
            create_client(
                name,
                formatted_document,
                formatted_phone,
                normalized_email,
                city,
                state,
            )
            title = "Cliente cadastrado"
            message = f"O cliente {name} foi salvo com sucesso."
            action = "criou"

        self.clear_client_form()
        self.refresh_all()
        self.confirm_action(
            title,
            message,
            action,
            "cliente",
            name,
        )

    def clear_client_form(self):
        for entry in self.client_inputs.values():
            entry.clear()
        self.client_state.setCurrentIndex(0)
        self.editing_client_id = None
        if hasattr(self, "client_save_button"):
            self.client_save_button.setText("Salvar Cliente")

    def load_selected_client(self):
        if not self.require_permission(
            "edit_client",
            "Somente o perfil Diretor pode editar clientes.",
        ):
            return

        rows = self.clients_table.selectionModel().selectedRows()
        if not rows:
            self.warn("Selecione um cliente na tabela.")
            return

        client_id = self.clients_table.item(rows[0].row(), 0).data(Qt.UserRole)
        client = self.find_client(client_id)
        if not client:
            self.warn("Cliente não encontrado.")
            return

        self.editing_client_id = client["id"]
        self.client_inputs["name"].setText(client["name"])
        self.client_inputs["document"].setText(client["document"])
        self.client_inputs["phone"].setText(client["phone"])
        self.client_inputs["email"].setText(client["email"])
        self.client_inputs["city"].setText(client["city"])
        self.client_state.setCurrentText(client["state"])
        self.client_save_button.setText("Atualizar Cliente")
        self.status_label.setText(f"Editando cliente: {client['name']}")
        self.selected_client_id = client["id"]
        self.populate_client_budgets_table()

    def delete_selected_client(self):
        if not self.require_permission(
            "delete_client",
            "Somente o perfil Diretor pode excluir clientes.",
        ):
            return

        rows = self.clients_table.selectionModel().selectedRows()
        if not rows:
            self.warn("Selecione um cliente na tabela.")
            return

        client_id = self.clients_table.item(rows[0].row(), 0).data(Qt.UserRole)
        client = self.find_client(client_id)
        if not client:
            self.warn("Cliente não encontrado.")
            return

        if not self.ask_confirmation(
            "Excluir cliente",
            (
                f"Excluir {client['name']}?\n\n"
                "Todos os projetos desse cliente também serão excluídos."
            ),
        ):
            return

        delete_client(client_id)
        self.clear_client_form()
        self.selected_client_id = None
        self.refresh_all()
        self.confirm_action(
            "Cliente excluído",
            f"O cliente {client['name']} foi excluído com sucesso.",
            "excluiu",
            "cliente",
            client["name"],
        )

    def sync_selected_client(self):
        rows = self.clients_table.selectionModel().selectedRows()
        if not rows:
            return

        client_id = self.clients_table.item(rows[0].row(), 0).data(Qt.UserRole)
        self.selected_client_id = client_id
        self.populate_client_budgets_table()

    def start_sizing_for_selected_client(self):
        if not self.require_permission(
            "create_sizing",
            "Seu perfil não pode criar projetos.",
        ):
            return

        if not self.selected_client_id:
            self.warn("Selecione um cliente primeiro.")
            return

        index = self.sizing_client.findData(self.selected_client_id)
        if index >= 0:
            self.sizing_client.setCurrentIndex(index)
        self.show_page(2)
        client = self.find_client(self.selected_client_id)
        self.status_label.setText(
            f"Novo projeto técnico para {client['name']}"
            if client
            else "Novo projeto técnico"
        )

    def duplicate_selected_client_budget(self):
        if not self.require_permission(
            "create_sizing",
            "Seu perfil não pode duplicar projetos.",
        ):
            return

        rows = self.client_budgets_table.selectionModel().selectedRows()
        if not rows:
            self.warn("Selecione um projeto técnico do cliente.")
            return

        budget_id = int(self.client_budgets_table.item(rows[0].row(), 0).text())
        budget = self.find_budget(budget_id)
        if not budget:
            self.warn("Projeto Técnico não encontrado.")
            return

        self.load_budget_into_sizing_form(budget)
        self.show_page(2)
        self.status_label.setText(
            f"Projeto #{budget_id} duplicado para novo projeto técnico"
        )

    def load_budget_into_sizing_form(self, budget):
        client_index = self.sizing_client.findData(budget["client_id"])
        if client_index >= 0:
            self.sizing_client.setCurrentIndex(client_index)
        self.sizing_status.setCurrentText("Em negociação")
        self.performance_ratio.setText(number(budget.get("performance_ratio", 0)))
        self.module_power.setText(number(budget.get("module_power", 0), 0))
        self.energy_tariff.setText(number(budget.get("energy_tariff", 0)))
        self.extra_percent.setText(
            number(budget.get("generation_extra_percent", 0))
        )

        consumptions = json.loads(budget["monthly_consumptions"] or "[]")
        hsp_values = json.loads(budget["monthly_hsp"] or "[]")
        for index, entry in enumerate(self.monthly_consumption_inputs):
            value = consumptions[index] if index < len(consumptions) else 0
            entry.setText(number(value, 0))
        for index, entry in enumerate(self.monthly_hsp_inputs):
            value = hsp_values[index] if index < len(hsp_values) else 0
            entry.setText(number(value))

    def import_bill_to_sizing_form(self):
        pdf_path, _ = QFileDialog.getOpenFileName(
            self,
            "Importar fatura de energia",
            "",
            "Arquivos PDF (*.pdf)",
        )
        if not pdf_path:
            return

        try:
            result = self.bill_importer_service.import_pdf(pdf_path)
        except Exception as exc:
            self.warn(f"Não foi possível importar a fatura.\n\n{exc}")
            return

        if not any(result.monthly_consumptions):
            self.warn("Não encontrei consumo mensal em kWh nessa fatura.")
            return

        for index, entry in enumerate(self.monthly_consumption_inputs):
            value = result.monthly_consumptions[index]
            entry.setText(number(value, 0))

        selected_client = self.select_imported_bill_client(result.client_name)
        self.schedule_sizing_preview_update()

        client_message = (
            f"Cliente selecionado: {selected_client}"
            if selected_client
            else f"Cliente identificado: {result.client_name or 'não identificado'}"
        )
        self.sizing_result.setText(
            "Fatura importada com sucesso.\n"
            f"{client_message}\n"
            f"UC: {result.uc or 'não identificada'}\n"
            f"Consumo médio: {number(result.average_consumption)} kWh/mês\n"
            f"Consumo anual: {number(result.annual_consumption)} kWh"
        )
        self.status_label.setText(
            f"Fatura importada: {Path(pdf_path).name}"
        )

    def select_imported_bill_client(self, client_name):
        if not client_name:
            return ""

        normalized_name = self.normalize_search_text(client_name)
        for client in self.clients:
            local_name = self.normalize_search_text(client["name"])
            if normalized_name in local_name or local_name in normalized_name:
                index = self.sizing_client.findData(client["id"])
                if index >= 0:
                    self.sizing_client.setCurrentIndex(index)
                    return client["name"]
        return ""

    def normalize_search_text(self, value):
        text = str(value or "").strip().lower()
        replacements = {
            "á": "a",
            "à": "a",
            "ã": "a",
            "â": "a",
            "é": "e",
            "ê": "e",
            "í": "i",
            "ó": "o",
            "õ": "o",
            "ô": "o",
            "ú": "u",
            "ç": "c",
        }
        for source, target in replacements.items():
            text = text.replace(source, target)
        return " ".join(text.split())

    def save_sizing(self):
        if not self.require_permission(
            "create_sizing",
            "Seu perfil não pode salvar projetos.",
        ):
            return

        if self.sizing_client.currentData() is None:
            self.warn("Cadastre ou selecione um cliente antes de salvar.")
            return

        inputs, results = self.read_sizing_data(show_errors=True)
        if not results:
            return

        budget_id = self.project_service.create_dimensioning(
            self.sizing_client.currentData(),
            datetime.now().strftime("%d/%m/%Y"),
            self.sizing_status.currentText(),
            inputs,
            results,
        )
        self.sizing_result.setText(
            f"Projeto #{budget_id} salvo\n"
            f"Potência: {number(results['system_power'])} kWp\n"
            f"Módulos: {results['module_count']}\n"
            f"Consumo anual: {number(results['annual_consumption'])} kWh\n"
            f"Geração anual: {number(results['annual_generation'])} kWh\n"
            f"Economia média: {brl(results['monthly_savings'])}/mês"
        )
        self.refresh_all()
        self.confirm_action(
            "Projeto Técnico salvo",
            f"O projeto #{budget_id} foi criado com sucesso.",
            "criou",
            "projeto",
            f"Projeto #{budget_id}",
        )

    def save_financial_plan(self):
        if not self.require_permission(
            "use_financing",
            "Seu perfil não pode editar o financeiro.",
        ):
            return

        budget_id = self.finance_budget.currentData()
        budget = self.find_budget(budget_id)
        if not budget:
            self.warn("Selecione um projeto para atualizar.")
            return
        try:
            project_value = parse_float(self.finance_project_value)
            down_payment = parse_float(self.finance_down_payment)
            discount = parse_float(self.finance_discount)
            installments = parse_int(self.finance_installments)
            installment_value = parse_float(self.finance_installment_value)
            first_due_date = self.finance_first_due_date.text().strip()
            if (
                project_value < 0
                or down_payment < 0
                or discount < 0
                or installments < 0
                or installment_value < 0
            ):
                raise ValueError
        except (ValueError, ZeroDivisionError):
            self.warn("Confira os campos financeiros.")
            return

        self.project_service.update_financial_plan(
            budget_id,
            self.finance_payment_type.currentText(),
            down_payment,
            discount,
            installments,
            installment_value,
            first_due_date,
            self.finance_notes.toPlainText().strip(),
        )

        # Mantém compatibilidade com as telas antigas que usam project_value/payback.
        monthly_savings = float(budget.get("monthly_savings") or 0)
        payback = (
            max(project_value - discount - down_payment, 0) / (monthly_savings * 12)
            if monthly_savings > 0
            else 0
        )
        self.project_service.update_financing(
            budget_id,
            project_value,
            down_payment,
            0,
            installments,
            {
                "financed_amount": max(project_value - discount - down_payment, 0),
                "monthly_payment": installment_value,
                "total_paid": down_payment + (installments * installment_value),
                "total_interest": 0,
                "payback_years": payback,
            },
        )
        self.refresh_all()
        self.load_finance_project_by_id(budget_id)
        self.confirm_action(
            "Financeiro salvo",
            f"O financeiro do projeto #{budget_id} foi atualizado.",
            "atualizou",
            "financeiro",
            f"Projeto #{budget_id}",
        )

    def save_financing(self):
        self.save_financial_plan()

    def add_project_payment(self):
        if not self.require_permission(
            "use_financing",
            "Seu perfil não pode registrar pagamentos.",
        ):
            return

        project_id = self.finance_budget.currentData()
        if not self.find_budget(project_id):
            self.warn("Selecione um projeto.")
            return
        try:
            amount = parse_float(self.finance_payment_amount)
            if amount <= 0:
                raise ValueError
        except ValueError:
            self.warn("Informe um valor pago válido.")
            return

        paid_at = self.finance_payment_date.text().strip() or datetime.now().strftime("%Y-%m-%d")
        self.project_service.create_payment(
            project_id,
            amount,
            self.finance_payment_method.currentText(),
            paid_at,
            self.finance_payment_notes.text().strip(),
        )
        self.finance_payment_amount.setText("0")
        self.finance_payment_notes.clear()
        self.refresh_all()
        self.load_finance_project_by_id(project_id)
        self.confirm_action(
            "Pagamento registrado",
            f"O pagamento de {brl(amount)} foi vinculado ao projeto #{project_id}.",
            "registrou",
            "pagamento",
            f"Projeto #{project_id}",
        )

    def cancel_selected_payment(self):
        if not self.require_permission(
            "use_financing",
            "Seu perfil não pode cancelar pagamentos.",
        ):
            return

        rows = self.finance_payments_table.selectionModel().selectedRows()
        if not rows:
            self.warn("Selecione um pagamento na tabela.")
            return
        payment_id = int(self.finance_payments_table.item(rows[0].row(), 0).text())
        if not self.ask_confirmation(
            "Cancelar pagamento",
            f"Cancelar o pagamento #{payment_id}?",
        ):
            return
        project_id = self.finance_budget.currentData()
        self.project_service.cancel_payment(payment_id)
        self.refresh_all()
        self.load_finance_project_by_id(project_id)
        self.confirm_action(
            "Pagamento cancelado",
            f"O pagamento #{payment_id} foi cancelado.",
            "cancelou",
            "pagamento",
            f"Pagamento #{payment_id}",
        )

    def load_selected_finance_project(self, *args):
        self.load_finance_project_by_id(self.finance_budget.currentData())

    def load_finance_project_by_id(self, project_id):
        project = self.find_budget(project_id)
        if not project or not hasattr(self, "finance_result"):
            return

        self.finance_project_value.setText(number(float(project.get("project_value", 0) or 0)))
        payment_type = project.get("payment_type") or PAYMENT_TYPES[0]
        if self.finance_payment_type.findText(payment_type) < 0:
            self.finance_payment_type.addItem(payment_type)
        self.finance_payment_type.setCurrentText(payment_type)
        self.finance_down_payment.setText(number(float(project.get("down_payment", 0) or 0)))
        self.finance_discount.setText(number(float(project.get("discount", 0) or 0)))
        self.finance_installments.setText(str(int(project.get("installments_count", 0) or 0)))
        self.finance_installment_value.setText(number(float(project.get("installment_value", 0) or 0)))
        self.finance_first_due_date.setText(str(project.get("first_due_date") or ""))
        self.finance_notes.setPlainText(str(project.get("financial_notes") or ""))
        self.populate_project_payments_table(project_id)
        self.update_finance_project_result(project)

    def payments_for_project(self, project_id):
        return [
            payment for payment in self.project_payments
            if payment["project_id"] == project_id and payment["status"] != "canceled"
        ]

    def paid_for_project(self, project_id):
        return sum(
            float(payment.get("amount") or 0)
            for payment in self.payments_for_project(project_id)
            if payment.get("status") == "paid"
        )

    def remaining_for_project(self, project):
        total = max(
            float(project.get("project_value") or 0)
            - float(project.get("discount") or 0),
            0,
        )
        paid = float(project.get("down_payment") or 0) + self.paid_for_project(project["id"])
        return max(total - paid, 0)

    def update_finance_project_result(self, project):
        total = float(project.get("project_value") or 0)
        discount = float(project.get("discount") or 0)
        down_payment = float(project.get("down_payment") or 0)
        paid = self.paid_for_project(project["id"])
        remaining = self.remaining_for_project(project)
        self.finance_result.setText(
            f"Cliente: {project.get('client_name', '-')}\n"
            f"Valor do projeto: {brl(total)}\n"
            f"Desconto: {brl(discount)}\n"
            f"Entrada: {brl(down_payment)}\n"
            f"Recebido: {brl(paid)}\n"
            f"Faltando pagar: {brl(remaining)}\n"
            f"Parcelas: {int(project.get('installments_count') or 0)}x de "
            f"{brl(float(project.get('installment_value') or 0))}"
        )

    def populate_project_payments_table(self, project_id):
        payments = self.payments_for_project(project_id)
        self.finance_payments_table.setRowCount(len(payments))
        for row, payment in enumerate(payments):
            values = [
                payment["id"],
                payment.get("paid_at") or "-",
                payment.get("payment_type") or "-",
                brl(float(payment.get("amount") or 0)),
                payment.get("notes") or "",
            ]
            for column, value in enumerate(values):
                item = self.make_table_item(value)
                if column == 0:
                    item.setData(Qt.UserRole, payment["id"])
                self.finance_payments_table.setItem(row, column, item)

    def update_chart(self):
        budget = self.find_budget(self.chart_budget.currentData()) if hasattr(self, "chart_budget") else None
        if not budget:
            if hasattr(self, "chart"):
                self.chart.set_data([], [], [])
            if hasattr(self, "chart_metric_labels"):
                for label in self.chart_metric_labels.values():
                    label.setText("-")
            return
        consumption = json.loads(budget["monthly_consumptions"] or "[]")
        generation = json.loads(budget["monthly_generations"] or "[]")
        balance = json.loads(budget["monthly_balances"] or "[]")
        self.chart.set_data(consumption, generation, balance)
        if hasattr(self, "chart_metric_labels"):
            self.chart_metric_labels["consumption"].setText(
                f"{number(sum(consumption))} kWh"
            )
            self.chart_metric_labels["generation"].setText(
                f"{number(sum(generation))} kWh"
            )
            self.chart_metric_labels["balance"].setText(
                f"{number(sum(balance))} kWh"
            )
            self.chart_metric_labels["power"].setText(
                f"{number(budget['system_power'])} kWp"
            )

    def sync_selected_budget(self):
        rows = self.budgets_table.selectionModel().selectedRows()
        if not rows:
            return
        budget_id = int(self.budgets_table.item(rows[0].row(), 0).text())
        budget = self.find_budget(budget_id)
        if budget:
            self.update_status_combo.setCurrentText(budget["status"])

    def open_selected_project_details(self):
        rows = self.budgets_table.selectionModel().selectedRows()
        if not rows:
            self.warn("Selecione um projeto na tabela.")
            return
        self.open_project_details_from_table(self.budgets_table)

    def open_project_details_from_table(self, table):
        rows = table.selectionModel().selectedRows()
        if not rows:
            return

        id_item = table.item(rows[0].row(), 0)
        if not id_item:
            return

        project_id = id_item.data(Qt.UserRole) or id_item.text()
        try:
            project_id = int(project_id)
        except (TypeError, ValueError):
            return

        project = self.find_budget(project_id)
        if not project:
            self.warn("Projeto não encontrado.")
            return

        self.project_details.set_project(project)
        self.load_project_documents(project["id"])
        self.show_page(6)

    def open_project_dimensioning(self, project):
        if not project:
            return
        self.load_budget_into_sizing_form(project)
        self.show_page(2)
        self.status_label.setText(f"Base técnica do projeto #{project['id']} carregada.")

    def open_project_financing(self, project):
        if not project:
            return
        index = self.finance_budget.findData(project["id"])
        if index >= 0:
            self.finance_budget.setCurrentIndex(index)
        self.load_finance_project_by_id(project["id"])
        self.show_page(3)
        self.status_label.setText(f"Financeiro do projeto #{project['id']} carregado.")

    def load_project_documents(self, project_id):
        documents = self.project_documents.list(project_id)
        self.project_details.set_documents(documents)

    def upload_project_document(self, project):
        if not project:
            return

        file_path, _ = QFileDialog.getOpenFileName(
            self,
            "Adicionar documento ao projeto",
            "",
            "Todos os arquivos (*.*)",
        )
        if not file_path:
            return

        category, accepted = QInputDialog.getItem(
            self,
            "Categoria do documento",
            "Selecione a categoria:",
            DOCUMENT_CATEGORIES,
            0,
            False,
        )
        if not accepted:
            return

        try:
            self.project_documents.upload(project["id"], file_path, category)
        except Exception as exc:
            self.warn(f"Não foi possível salvar o documento.\n\n{exc}")
            return

        self.load_project_documents(project["id"])
        self.confirm_action(
            "Documento adicionado",
            "O arquivo foi vinculado ao projeto com sucesso.",
            "adicionou",
            "documento",
            f"Projeto #{project['id']}",
        )

    def open_project_document(self, document_id):
        try:
            self.project_documents.open(document_id)
        except Exception as exc:
            self.warn(f"Não foi possível abrir o documento.\n\n{exc}")

    def delete_project_document(self, document_id):
        project = getattr(self.project_details, "project", None)
        if not project:
            return
        if not self.ask_confirmation(
            "Excluir documento",
            "Excluir o documento selecionado do projeto?",
        ):
            return

        try:
            deleted = self.project_documents.delete(document_id)
        except Exception as exc:
            self.warn(f"Não foi possível excluir o documento.\n\n{exc}")
            return

        if deleted:
            self.load_project_documents(project["id"])
            self.confirm_action(
                "Documento excluído",
                "O documento foi removido do projeto.",
                "excluiu",
                "documento",
                f"Projeto #{project['id']}",
            )

    def change_selected_status(self):
        if not self.require_permission(
            "update_budget_status",
            "Seu perfil não pode atualizar status de projeto.",
        ):
            return

        rows = self.budgets_table.selectionModel().selectedRows()
        if not rows:
            self.warn("Selecione um projeto na tabela.")
            return
        budget_id = int(self.budgets_table.item(rows[0].row(), 0).text())
        status = self.update_status_combo.currentText()
        self.project_service.update_status(budget_id, status)
        self.refresh_all()
        self.confirm_action(
            "Status atualizado",
            f"O projeto #{budget_id} agora está como {status}.",
            "atualizou",
            "status",
            f"Projeto #{budget_id}: {status}",
        )

    def delete_selected_budget(self):
        if not self.require_permission(
            "delete_budget",
            "Somente o perfil Diretor pode excluir projetos.",
        ):
            return

        rows = self.budgets_table.selectionModel().selectedRows()
        if not rows:
            self.warn("Selecione um projeto na tabela.")
            return

        budget_id = int(self.budgets_table.item(rows[0].row(), 0).text())
        if not self.ask_confirmation(
            "Excluir projeto",
            f"Excluir o projeto #{budget_id}?",
        ):
            return

        self.project_service.delete(budget_id)
        self.refresh_all()
        self.confirm_action(
            "Projeto excluído",
            f"O projeto #{budget_id} foi excluído com sucesso.",
            "excluiu",
            "projeto",
            f"Projeto #{budget_id}",
        )

    def find_budget(self, budget_id):
        for budget in self.budgets:
            if budget["id"] == budget_id:
                return budget
        return None

    def find_client(self, client_id):
        for client in self.clients:
            if client["id"] == client_id:
                return client
        return None

    def show_message(self, title, message, icon=QMessageBox.Information):
        dialog = QMessageBox(self)
        dialog.setWindowTitle("Solar Pro")
        dialog.setText(title)
        dialog.setInformativeText(message)
        dialog.setIcon(icon)
        dialog.setMinimumWidth(420)
        dialog.setStyleSheet(APP_STYLES)
        dialog.exec()

    def ask_confirmation(self, title, message):
        dialog = QMessageBox(self)
        dialog.setWindowTitle("Solar Pro")
        dialog.setText(title)
        dialog.setInformativeText(message)
        dialog.setIcon(QMessageBox.Question)
        dialog.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
        dialog.setDefaultButton(QMessageBox.No)
        dialog.button(QMessageBox.Yes).setText("Confirmar")
        dialog.button(QMessageBox.No).setText("Cancelar")
        dialog.setMinimumWidth(440)
        dialog.setStyleSheet(APP_STYLES)
        return dialog.exec() == QMessageBox.Yes

    def warn(self, message):
        self.show_message("Atenção", message, QMessageBox.Warning)

    def confirm_action(self, title, message, action, entity, detail):
        synced, sync_message = self.sync_after_change(action, entity, detail)
        provider = getattr(self.sync_client, "provider_name", "nuvem")

        if synced:
            self.status_label.setText(f"{title}: sincronizado")
            self.show_message(
                title,
                f"{message}\n\nSincronizado com {provider}.",
                QMessageBox.Information,
            )
            return

        if sync_message:
            self.status_label.setText(f"{title}: salvo apenas localmente")
            self.show_message(
                title,
                (
                    f"{message}\n\n"
                    "A ação foi salva no banco local, mas não foi possível "
                    f"sincronizar com {provider}.\n\n"
                    f"Detalhe: {sync_message}"
                ),
                QMessageBox.Warning,
            )
            return

        self.status_label.setText(title)
        self.show_message(
            title,
            f"{message}\n\nModo offline: salvo no banco local.",
            QMessageBox.Information,
        )

    def sync_after_change(self, action, entity, detail):
        if (
            not self.sync_client
            or not self.sync_client.is_configured()
            or self.current_user.matricula == "offline"
        ):
            return False, ""

        try:
            self.sync_client.push_from_local(
                self.current_user,
                action,
                entity,
                detail,
            )
            return True, ""
        except SyncError as error:
            return False, str(error)
        except Exception as error:
            return False, str(error)

    def apply_styles(self):
        self.setStyleSheet(APP_STYLES)


def main():
    app = QApplication(sys.argv)
    app.setStyle(QStyleFactory.create("Fusion"))
    app.setWindowIcon(app_icon())
    palette = app.palette()
    palette.setColor(QPalette.Window, QColor("#020817"))
    palette.setColor(QPalette.Base, QColor("#06101f"))
    palette.setColor(QPalette.AlternateBase, QColor("#0f172a"))
    palette.setColor(QPalette.Text, QColor("#f8fafc"))
    palette.setColor(QPalette.Button, QColor("#0f172a"))
    palette.setColor(QPalette.ButtonText, QColor("#f8fafc"))
    palette.setColor(QPalette.Highlight, QColor("#1267f1"))
    palette.setColor(QPalette.HighlightedText, QColor("#ffffff"))
    palette.setColor(QPalette.ToolTipBase, QColor("#0f172a"))
    palette.setColor(QPalette.ToolTipText, QColor("#f8fafc"))
    app.setPalette(palette)
    app.setStyleSheet(APP_STYLES)

    sync_client = SupabaseSync.from_config()
    current_user = OFFLINE_USER

    if sync_client.is_configured():
        login = LoginDialog(sync_client)
        if login.exec() != QDialog.Accepted:
            sys.exit(0)
        current_user = login.user or OFFLINE_USER

        if current_user.matricula != "offline":
            try:
                clients_count, budgets_count = sync_client.pull_to_local()
                QMessageBox.information(
                    None,
                    "Solar Pro",
                    (
                        "Sincronização concluída.\n"
                        f"Clientes: {clients_count}\n"
                        f"Projetos: {budgets_count}"
                    ),
                )
            except SyncError as error:
                QMessageBox.warning(
                    None,
                    "Solar Pro",
                    (
                        "Não foi possível atualizar pela nuvem.\n"
                        "O programa continuará com o banco local.\n\n"
                        f"Detalhe: {error}"
                    ),
                )
            except Exception as error:
                QMessageBox.warning(
                    None,
                    "Solar Pro",
                    (
                        "Não foi possível atualizar pela nuvem.\n"
                        "O programa continuará com o banco local.\n\n"
                        f"Detalhe: {error}"
                    ),
                )
    window = SolarProWindow(sync_client, current_user)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
