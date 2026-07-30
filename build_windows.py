#!/usr/bin/env python3
"""
Script automatizado para gerar executável Windows portável.
Uso: python build_windows.py
"""

import subprocess
import sys
import shutil
from pathlib import Path
from datetime import datetime


def print_header(text):
    """Imprimir cabeçalho colorido"""
    print("\n" + "=" * 60)
    print(f"  {text}")
    print("=" * 60 + "\n")


def run_command(cmd, description):
    """Executar comando e retornar sucesso"""
    print(f"▶ {description}...")
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=False)
        print(f"✅ {description} - OK\n")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} falhou!\n")
        return False


def build_exe():
    """Gerar executável com PyInstaller"""
    
    print_header("GERANDO EXECUTÁVEL")
    
    # Verificar se venv existe
    venv_python = Path("venv/Scripts/python.exe")
    if not venv_python.exists():
        print("❌ Ambiente virtual não encontrado!")
        print("Execute antes: python -m venv venv")
        return False
    
    # Gerar SolarPro.exe
    if not run_command(
        f'"{venv_python}" -m PyInstaller SolarPro.spec --distpath dist --buildpath build --specpath .',
        "Gerando SolarPro.exe"
    ):
        return False

    prepare_runtime_files()
    
    return True


def prepare_runtime_files():
    """Copiar arquivos externos usados pelo executável."""

    dist_dir = Path("dist")
    dist_dir.mkdir(exist_ok=True)

    supabase_config_source = Path("desktop_app/supabase_config.json")
    if supabase_config_source.exists():
        shutil.copy2(supabase_config_source, dist_dir / "supabase_config.json")
        print("✓ Configuração copiada: supabase_config.json")


def create_portable():
    """Criar versão portável em ZIP"""
    
    print_header("CRIANDO VERSÃO PORTÁVEL")
    
    exe_path = Path("dist/SolarPro.exe")
    if not exe_path.exists():
        print("❌ SolarPro.exe não encontrado!")
        print("Execute build_windows.py first")
        return False
    
    # Criar pasta portable
    portable_dir = Path("portable_solarpro")
    if portable_dir.exists():
        shutil.rmtree(portable_dir)
    
    portable_dir.mkdir()
    
    # Copiar tudo de dist/
    dist_folder = Path("dist")
    for item in dist_folder.iterdir():
        if item.is_file():
            shutil.copy2(item, portable_dir / item.name)
            print(f"✓ Copiado: {item.name}")
        elif item.is_dir():
            shutil.copytree(item, portable_dir / item.name)
            print(f"✓ Copiado pasta: {item.name}")
    
    # Criar ZIP
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    zip_name = f"SolarPro_Portable_{timestamp}.zip"
    
    print(f"\n▶ Criando {zip_name}...")
    shutil.make_archive(
        f"SolarPro_Portable_{timestamp}",
        'zip',
        portable_dir
    )
    
    # Limpar pasta temporária
    shutil.rmtree(portable_dir)
    
    print(f"✅ Versão portável criada: {zip_name}\n")
    print(f"📦 Tamanho: {Path(f'{zip_name}').stat().st_size / (1024*1024):.1f} MB")
    
    return True


def show_summary():
    """Mostrar resumo do que foi gerado"""
    
    print_header("RESUMO")
    
    exe_path = Path("dist/SolarPro.exe")
    if exe_path.exists():
        size_mb = exe_path.stat().st_size / (1024*1024)
        print(f"✅ SolarPro.exe gerado com sucesso!")
        print(f"   Tamanho: {size_mb:.1f} MB")
        print(f"   Local: dist/SolarPro.exe")
    
    zip_files = list(Path(".").glob("SolarPro_Portable_*.zip"))
    if zip_files:
        print(f"\n✅ Versão portável criada!")
        for zip_file in zip_files:
            size_mb = zip_file.stat().st_size / (1024*1024)
            print(f"   📦 {zip_file.name} ({size_mb:.1f} MB)")
    
    print("\n" + "=" * 60)
    print("🚀 PRÓXIMO PASSO:")
    print("   1. Copiar dist/SolarPro.exe para outro PC")
    print("   2. Ou descompactar o .zip e rodar SolarPro.exe")
    print("=" * 60 + "\n")


def main():
    """Menu principal"""
    
    print("\n")
    print("╔════════════════════════════════════════════╗")
    print("║     SOLAR MANAGER - Build for Windows      ║")
    print("║              v1.0                          ║")
    print("╚════════════════════════════════════════════╝\n")
    
    print("Escolha uma opção:\n")
    print("1) Gerar executável (.exe)")
    print("2) Gerar versão portável (.zip)")
    print("3) Fazer tudo (recomendado)")
    print("0) Sair\n")
    
    choice = input("Sua escolha (0-3): ").strip()
    
    if choice == "0":
        print("Saindo...\n")
        sys.exit(0)
    
    elif choice == "1":
        if build_exe():
            show_summary()
    
    elif choice == "2":
        if create_portable():
            show_summary()
    
    elif choice == "3":
        if build_exe() and create_portable():
            show_summary()
    
    else:
        print("❌ Opção inválida!\n")
        main()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Cancelado pelo usuário\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erro: {e}\n")
        sys.exit(1)
