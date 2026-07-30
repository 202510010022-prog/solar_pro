# Solar Pro Qt

Nova interface desktop em PySide6/Qt para o Solar Manager.

Ela reaproveita o mesmo banco SQLite e as mesmas regras de cálculo do app
Tkinter atual, mas com layout profissional inspirado em painel desktop moderno.

## Rodar em desenvolvimento

```bash
python desktop_app_qt/main.py
```

## Supabase centralizado

O app usa Supabase para login da equipe e sincronização dos dados. A planilha
compartilhada não faz mais parte do fluxo principal.

1. Configure `desktop_app/supabase_config.json`.
2. Rode `supabase/schema.sql` no projeto Supabase.
3. Crie os usuários pelo Supabase Auth.
4. Vincule os usuários na tabela `profiles`.

Exemplo de configuração:

```json
{
  "enabled": true,
  "url": "https://SEU-PROJETO.supabase.co",
  "anon_key": "SUA_SUPABASE_PUBLISHABLE_KEY",
  "auth_mode": "email_password"
}
```

Ao abrir, o app valida email/senha no Supabase. Depois baixa `Clientes` e
`Projetos` para o banco SQLite local. Ao salvar alterações, o app envia os
dados para o Supabase.

## Gerar executável

```bash
pyinstaller --onefile --windowed --name SolarPro --icon desktop_app_qt/assets/app_icon.png --paths . --add-data desktop_app_qt/assets:assets --hidden-import desktop_app.calculations --hidden-import desktop_app.database --hidden-import desktop_app.validators --hidden-import desktop_app.sync_types --hidden-import desktop_app.supabase_sync desktop_app_qt/main.py
```

O banco continua sendo o arquivo `solar_manager_desktop.db`. Em modo executável,
ele fica ao lado do programa gerado.
