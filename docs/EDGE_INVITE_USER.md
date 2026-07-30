# Edge Function - invite-user

## Objetivo

Criar usuarios da equipe com seguranca, sem expor chave `service_role` no app mobile ou web.

## URL

```text
https://uaomsrfbwthfgnayfdoa.supabase.co/functions/v1/invite-user
```

## Seguranca

A funcao valida manualmente:

- token JWT enviado em `Authorization`;
- usuario autenticado no Supabase Auth;
- perfil ativo em `profiles`;
- permissao `diretor`, `admin` ou `owner`;
- limite de usuarios do plano atual;
- matricula unica dentro da empresa.

## Payload

```json
{
  "name": "Nome do Usuario",
  "email": "usuario@empresa.com",
  "matricula": "2026001",
  "permission": "assessor_projetos",
  "role": "Assessor de Projetos",
  "password": "SenhaOpcional@123"
}
```

## Permissoes permitidas para novo usuario

- `assessor_projetos`
- `assessor_daf`
- `diretor`

## Senha

Se `password` for enviada, a funcao usa essa senha.

Se `password` nao for enviada, a funcao gera uma senha temporaria e retorna em `temporary_password`.

## Exemplo com cURL

```bash
curl -X POST \
  'https://uaomsrfbwthfgnayfdoa.supabase.co/functions/v1/invite-user' \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H 'Content-Type: application/json' \
  --data '{
    "name": "Novo Usuario",
    "email": "novo.usuario@solarpro.test",
    "matricula": "2026001",
    "permission": "assessor_projetos"
  }'
```

## Resposta de sucesso

```json
{
  "ok": true,
  "user": {
    "id": "uuid",
    "email": "novo.usuario@solarpro.test",
    "name": "Novo Usuario",
    "matricula": "2026001",
    "role": "Assessor de Projetos",
    "permission": "assessor_projetos"
  },
  "temporary_password": "SolarPro@senha",
  "message": "Usuario criado com senha temporaria."
}
```

## Deploy

```bash
./.tools/supabase-cli/supabase functions deploy invite-user --no-verify-jwt
```

## Proximo passo

Conectar essa funcao a uma tela `Usuarios da equipe` no app, disponivel somente para diretor/admin/owner.
