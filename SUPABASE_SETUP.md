# SolarPro + Supabase

## 1. Criar projeto

1. Crie um projeto no Supabase.
2. Copie `Project URL` e `anon public key`.
3. No SQL Editor, rode o arquivo:

```text
supabase/schema.sql
```

Se o banco ja estava criado antes da tabela de documentos, aplique tambem:

```text
supabase/migrations/20260602_create_project_documents.sql
```

## 2. Configurar o app

### Flutter mobile/admin

Copie:

```text
dart_define.example.json
```

para:

```text
dart_define.json
```

Preencha:

```json
{
  "SUPABASE_URL": "https://SEU-PROJETO.supabase.co",
  "SUPABASE_ANON_KEY": "SUA_SUPABASE_ANON_KEY"
}
```

Rode os apps Flutter com:

```bash
flutter run --dart-define-from-file=../dart_define.json
```

Use sempre a publishable/anon key. Nunca coloque a `service_role key` nos apps
mobile, web, admin ou desktop.

### Desktop Python

Copie:

```text
desktop_app/supabase_config.example.json
```

para:

```text
desktop_app/supabase_config.json
```

Preencha:

```json
{
  "enabled": true,
  "url": "https://SEU-PROJETO.supabase.co",
  "anon_key": "SUA_SUPABASE_ANON_KEY",
  "auth_mode": "email_password"
}
```

Nunca coloque a `service_role key` dentro do aplicativo desktop.

## 3. Criar primeiro usuário

1. Crie uma empresa na tabela `companies`.
2. Crie um usuário em Authentication > Users.
3. Copie o ID do usuário.
4. Crie um registro em `profiles` com esse ID, `company_id`, nome,
   matrícula, cargo/permissão e `active = true`.

O login inicial do app usa email e senha do Supabase Auth. A matrícula fica no
perfil e aparece no sistema.

## 4. Sincronizacao offline-first

O aplicativo usa SQLite local para permitir trabalho offline. Ao autenticar no
Supabase, o sistema sincroniza:

- clientes
- projetos
- metadados de documentos do projeto
- historico de acoes

Os arquivos anexados aos projetos ainda ficam armazenados no computador local.
Para uso comercial com varias maquinas, a evolucao recomendada e ativar
Supabase Storage para os arquivos e manter no SQLite/Supabase apenas o caminho
remoto do arquivo.

## 5. Usuários de teste

Depois de rodar `supabase/schema.sql`, crie os usuários no Supabase Auth
pelo painel ou pela Admin API. Depois rode o seed para criar a empresa e
vincular os perfis:

```text
supabase/seed_test_users.sql
```

Logins usados no ambiente de teste:

```text
projetos.teste@solarpro.com.br / SolarPro@2026
daf.teste@solarpro.com.br / SolarPro@2026
diretor.teste@solarpro.com.br / SolarPro@2026
```

Use esses usuários apenas para teste. Antes de colocar o sistema em produção,
apague-os ou troque as senhas no painel do Supabase.
