# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['desktop_app_qt/main.py'],
    pathex=['.'],
    binaries=[],
    datas=[('desktop_app_qt/assets', 'assets')],
    hiddenimports=[
        'desktop_app.calculations',
        'desktop_app.database',
        'desktop_app.models',
        'desktop_app.project_service',
        'desktop_app.validators',
        'desktop_app.sync_types',
        'desktop_app.supabase_sync',
        'desktop_app_qt.project_details_page',
        'services.bill_importer_service',
        'services.project_documents',
        'pdfplumber',
        'pandas',
        'PySide6.QtSvg',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='SolarPro',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['desktop_app_qt/assets/app_icon.ico'],
)
