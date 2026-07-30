# Faxina profissional do Solar Pro

Data: 2026-07-02

## Objetivo

Separar codigo-fonte de artefatos locais, builds, bancos de teste, backups e
credenciais antigas.

## Backup local criado

Arquivos sensiveis e bancos locais foram movidos para:

```text
.local/private_backup_20260702_191852/
```

Essa pasta fica ignorada pelo Git.

## Itens movidos para o backup

- `desktop_app/sheets_config.json`
- `desktop_app/supabase_config.json`
- `desktop_app/solar_manager_desktop.db`
- `desktop_app/backups/`
- `desktop_app_qt/service_account.json`
- `dist/supabase_config.json`
- `dist/solar_manager_desktop.db`
- `dist/backups/`

## Itens removidos

Foram removidos apenas artefatos gerados:

- `build/`
- `dist/`
- `mobile_app/build/`
- `mobile_app/.dart_tool/`
- `admin_app/build/`
- `admin_app/.dart_tool/`
- `__pycache__/`
- caches Android/Flutter locais

## O que continua local

A pasta `.tools/` foi mantida para continuar usando Flutter, Android SDK e
Supabase CLI instalados neste workspace, mas ela agora esta ignorada pelo Git.

## Como restaurar uma config antiga

Exemplo:

```bash
cp .local/private_backup_20260702_191852/desktop_app/supabase_config.json desktop_app/supabase_config.json
```

## Recriar dependencias apos a limpeza

Mobile:

```bash
cd mobile_app
../.tools/flutter/bin/flutter pub get
```

Admin:

```bash
cd admin_app
../.tools/flutter/bin/flutter pub get
```

Desktop Python:

```bash
./venv/bin/python desktop_app_qt/main.py
```

## Observacao sobre Git

O diretorio `.git` atual estava incompleto/vazio no momento da limpeza. Antes
de subir para GitHub ou CI, inicialize um repositorio limpo:

```bash
git init
git add .
git status
```

Confira cuidadosamente se nenhum arquivo sensivel aparece no `git status`.
