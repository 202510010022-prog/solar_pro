@echo off
REM ╔══════════════════════════════════════════════════╗
REM ║    SOLAR MANAGER - Build Windows Automático     ║
REM ║           Versão 2.0 - One Click!               ║
REM ╚══════════════════════════════════════════════════╝

setlocal enabledelayedexpansion
cd /d "%~dp0"

cls
echo.
echo ╔════════════════════════════════════════════════╗
echo ║  SOLAR MANAGER - Gerador de Executável        ║
echo ║         Windows (Portável + ZIP)              ║
echo ╚════════════════════════════════════════════════╝
echo.

REM Verificar se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python não encontrado!
    echo.
    echo Faça isso:
    echo   1. Baixe Python em: https://www.python.org/downloads/
    echo   2. Instale marcando "Add Python to PATH"
    echo   3. Abra novo CMD e tente novamente
    echo.
    pause
    exit /b 1
)

REM Criar venv se não existir
if not exist "venv" (
    echo ▶ Criando ambiente virtual...
    python -m venv venv
    echo ✅ Ambiente virtual criado
    echo.
)

REM Ativar venv
echo ▶ Ativando ambiente virtual...
call venv\Scripts\activate.bat

REM Instalar dependências
echo ▶ Verificando dependências...
pip install -q -r requirements.txt
if errorlevel 1 (
    echo ❌ Erro ao instalar dependências!
    pause
    exit /b 1
)
echo ✅ Dependências OK
echo.

REM Perguntar ao usuário
echo Escolha uma opção:
echo.
echo   1^) Gerar SolarPro.exe SOMENTE
echo   2^) Gerar SolarPro.exe ^+ ZIP portável 🎁 (RECOMENDADO)
echo   3^) Limpar e refazer tudo (se teve erro)
echo   0^) Sair
echo.

set /p choice="Sua escolha (0-3): "

if "%choice%"=="0" (
    echo.
    echo Até logo! 👋
    pause
    exit /b 0
)

REM Limpar se escolheu opção 3
if "%choice%"=="3" (
    echo.
    echo ▶ Limpando builds antigos...
    if exist "build" (
        rmdir /s /q build >nul 2>&1
        echo   ✓ Pasta build removida
    )
    if exist "dist" (
        rmdir /s /q dist >nul 2>&1
        echo   ✓ Pasta dist removida
    )
    echo ✅ Limpeza concluída
    echo.
)

REM Se escolheu 1 ou 3, faz só o exe
if "%choice%"=="1" goto build_exe
if "%choice%"=="3" goto build_exe

REM Se escolheu 2, faz exe + zip
if "%choice%"=="2" goto build_all

echo ❌ Opção inválida!
pause
exit /b 1

:build_exe
cls
echo.
echo ╔════════════════════════════════════════════════╗
echo ║     Gerando SolarPro.exe...                   ║
echo ║     (isso pode levar 1-3 minutos)             ║
echo ╚════════════════════════════════════════════════╝
echo.

pyinstaller SolarPro.spec --distpath dist --buildpath build --specpath .

if not exist "dist\SolarPro.exe" (
    echo.
    echo ❌ Erro ao gerar executável!
    echo.
    pause
    exit /b 1
)

call :copy_runtime_files

echo.
echo ✅ SolarPro.exe gerado com sucesso!
echo.
call :show_summary
pause
exit /b 0

:build_all
cls
echo.
echo ╔════════════════════════════════════════════════╗
echo ║  Gerando SolarPro.exe...                      ║
echo ║  (Passo 1 de 2 - pode levar 1-3 minutos)     ║
echo ╚════════════════════════════════════════════════╝
echo.

pyinstaller SolarPro.spec --distpath dist --buildpath build --specpath .

if not exist "dist\SolarPro.exe" (
    echo.
    echo ❌ Erro ao gerar executável!
    pause
    exit /b 1
)

call :copy_runtime_files

echo.
echo ✅ SolarPro.exe gerado!
echo.

cls
echo.
echo ╔════════════════════════════════════════════════╗
echo ║  Criando versão portável (ZIP)...             ║
echo ║  (Passo 2 de 2)                              ║
echo ╚════════════════════════════════════════════════╝
echo.

REM Gerar ZIP com data/hora
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)

set zipname=SolarPro_Portable_%mydate%_%mytime%.zip

echo ▶ Compactando em %zipname%...

REM Usar PowerShell para criar ZIP (disponível em Windows 7+)
powershell -command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('dist', '%zipname%')" >nul 2>&1

if exist "%zipname%" (
    echo ✅ ZIP criado com sucesso!
    echo.
    call :show_summary
) else (
    echo ⚠️  Não foi possível criar ZIP automaticamente.
    echo ▶ Criando manualmente...
    REM Fallback: Python
    python -c "import shutil, datetime; shutil.make_archive('SolarPro_Portable_' + datetime.datetime.now().strftime('%%Y%%m%%d_%%H%%M%%S'), 'zip', 'dist')" >nul 2>&1
    echo ✅ ZIP criado!
    echo.
    call :show_summary
)

pause
exit /b 0

:copy_runtime_files
echo.
echo ▶ Copiando arquivos de configuração...
if exist "desktop_app\supabase_config.json" (
    copy /y "desktop_app\supabase_config.json" "dist\supabase_config.json" >nul
    echo   ✓ supabase_config.json
)
exit /b 0

:show_summary
echo ╔════════════════════════════════════════════════╗
echo ║           ✨ RESUMO FINAL                      ║
echo ╚════════════════════════════════════════════════╝
echo.

if exist "dist\SolarPro.exe" (
    for /f %%A in ('powershell -Command "(Get-Item 'dist\SolarPro.exe').Length / 1MB"') do set size=%%A
    echo ✅ dist\SolarPro.exe
    echo    Tamanho: ~!size:~0,3! MB
)

for /f %%f in ('dir /b SolarPro_Portable_*.zip 2^>nul') do (
    for /f %%A in ('powershell -Command "(Get-Item '%%f').Length / 1MB"') do set zipsize=%%A
    echo.
    echo ✅ %%f
    echo    Tamanho: ~!zipsize:~0,3! MB
)

echo.
echo ╔════════════════════════════════════════════════╗
echo ║              📦 PRÓXIMO PASSO                  ║
echo ╚════════════════════════════════════════════════╝
echo.
echo Você tem 3 opções para compartilhar:
echo.
echo 1️⃣  COPIAR DIRETO:
echo    dist\SolarPro.exe → outro PC
echo.
echo 2️⃣  ENVIAR POR EMAIL/DRIVE:
echo    SolarPro_Portable_*.zip → Google Drive
echo.
echo 3️⃣  COPIAR EM PENDRIVE:
echo    Pasta dist/ → Pendrive
echo.
echo Descompacte e clique 2x em SolarPro.exe para rodar!
echo.
echo 🎉 Pronto para distribuir!
echo.
