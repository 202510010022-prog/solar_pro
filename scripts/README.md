# Scripts do Solar Pro

## Release

O script `release.sh` gera os artefatos principais de release:

- APK release do `mobile_app`.
- AAB release do `mobile_app`.
- Build web do `mobile_app`.
- Build web do `admin_app`.

Antes de gerar qualquer build, ele roda:

- `flutter analyze` e `flutter test` no `mobile_app`.
- `flutter analyze` e `flutter test` no `admin_app`.
- `dart test` em `integration_tests`, quando `integration_tests/.env` existir.

Se qualquer validação falhar, o script aborta e nenhum build é gerado.

## Pré-requisitos

Crie o arquivo real de ambiente na raiz do projeto:

```bash
cp dart_define.example.json dart_define.json
```

Preencha `dart_define.json` com a URL e a publishable/anon key do Supabase.
Esse arquivo não deve ir para o Git.

Para rodar os testes de integração, crie também:

```text
integration_tests/.env
```

com as credenciais do Supabase de teste, conforme `integration_tests/.env.example`.
Se esse arquivo não existir, o script pula os testes de integração com aviso.

## Como rodar

```bash
./scripts/release.sh
```

Os artefatos finais ficam em:

```text
releases/
```

Essa pasta é ignorada pelo Git.
