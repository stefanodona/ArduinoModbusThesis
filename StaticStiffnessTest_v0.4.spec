# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['GUI\\main.py'],
    pathex=[],
    binaries=[],
    datas=[('c:\\users\\stefa\\anaconda3\\envs\\thesis\\lib\\site-packages\\customtkinter', 'customtkinter\\')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['jaraco.text'],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='StaticStiffnessTest_v0.4',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['GUI\\icon.ico'],
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='StaticStiffnessTest_v0.4',
)
