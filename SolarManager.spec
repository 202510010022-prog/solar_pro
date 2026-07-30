# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['desktop_app/main.py'],
    pathex=[],
    binaries=[],
    datas=[('desktop_app/sheets_config.json', 'desktop_app')],
    hiddenimports=['desktop_app.calculations', 'desktop_app.database', 'desktop_app.validators', 'desktop_app.sheets_sync', 'google.oauth2.service_account', 'googleapiclient.discovery'],
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
    name='SolarManager',
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
