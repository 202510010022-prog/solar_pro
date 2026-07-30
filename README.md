# Solar Pro Platform

Solar Pro e uma plataforma mobile-first para empresas de energia solar, com app
Android/Web em Flutter, banco central Supabase e modulo desktop avancado para
operacoes pesadas.

## Produto principal

```text
mobile_app/
```

O app Flutter e a experiencia principal do Solar Pro:

- Android para uso em campo.
- Web para acesso rapido da equipe.
- Login via Supabase Auth.
- CRM de clientes.
- Projetos e orcamentos.
- Dimensionamento fotovoltaico.
- Dashboard comercial.
- Cache local para leitura offline.

## Modulo desktop avancado

```text
desktop_app_qt/
```

O desktop continua como ferramenta profissional para rotinas mais completas:

- Simulacao Financeira: valor do projeto, entrada, juros, parcelas, ROI, TIR,
  VPL e fluxo de caixa.
- Propostas Comerciais: geracao de PDF profissional com resumo, graficos e
  assinatura.
- Documentos do Projeto: upload, visualizacao, exclusao e organizacao por
  categoria.
- Importacao de Faturas: leitura de PDF para identificar cliente, UC e consumo.
- Sincronizacao em Equipe: clientes, projetos e documentos sincronizados pelo
  Supabase.

## Arquitetura

```text
desktop_app/
  database.py              # SQLite, migrations locais e consultas
  project_service.py       # CRUD orientado a projetos
  supabase_sync.py         # sincronizacao offline-first com Supabase

desktop_app_qt/
  main.py                  # aplicacao PySide6
  ui_components.py         # componentes visuais dark/neon
  project_details_page.py  # tela interna do projeto

services/
  bill_importer_service.py
  financial_analysis_service.py
  project_documents.py
  proposal_pdf_service.py

supabase/
  schema.sql
  migrations/
```

## Rodar o app principal

```bash
cd mobile_app
flutter pub get
flutter run -d chrome
```

Gerar APK:

```bash
cd mobile_app
flutter build apk --release
```

## Rodar desktop em desenvolvimento

```bash
./venv/bin/python desktop_app_qt/main.py
```

## Executavel gerado

```bash
./dist/SolarPro
```

## Gerar novo executavel

```bash
./venv/bin/pyinstaller --clean --onefile --windowed --name SolarPro desktop_app_qt/main.py
```

## Banco local

Em desenvolvimento, o SQLite fica em:

```text
desktop_app/solar_manager_desktop.db
```

No executavel, o banco fica ao lado do binario para permitir uso offline.

## Supabase

Configure o arquivo:

```text
desktop_app/supabase_config.json
```

Use apenas a `anon public key` no aplicativo desktop. Nunca embuta
`service_role key` no programa.

Para preparar o banco remoto, rode `supabase/schema.sql` ou aplique as
migrations em `supabase/migrations/`.

## Observacao sobre documentos

Hoje o Solar Pro sincroniza os metadados dos documentos do projeto. Os arquivos
continuam salvos localmente. Para uso comercial em varios computadores, a proxima
etapa recomendada e salvar os arquivos no Supabase Storage e sincronizar o
`storage_path`.

## Estrategia de branches

Para desenvolvimento solo ou pequena equipe, use um fluxo simples:

- `main`: branch estavel, sempre pronta para release.
- `feature/nome-curto`: novas funcionalidades ou refatoracoes planejadas.
- `fix/nome-curto`: correcoes pequenas e bugs de producao.
- `release/x.y.z`: preparacao de versoes publicas antes de distribuir.

Evite commits diretos grandes em `main` depois do commit inicial. Trabalhe em
branches curtas, valide, depois integre na `main`.
