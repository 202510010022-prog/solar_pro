# Solar Pro Admin

Painel administrativo da plataforma Solar Pro.

O app é Flutter e pode rodar como:

- Web local para testes.
- Desktop Linux/Windows/macOS.

## Configurar Ambiente

Crie o arquivo real de ambiente na raiz do projeto:

```bash
cp dart_define.example.json dart_define.json
```

Preencha `dart_define.json` com a `Project URL` e a publishable/anon key do
Supabase. Esse arquivo real fica fora do Git.

## Rodar Desktop Linux

```bash
cd admin_app
../.tools/flutter/bin/flutter run -d linux --dart-define-from-file=../dart_define.json
```

## Gerar Executável Linux

```bash
cd admin_app
../.tools/flutter/bin/flutter build linux --release --dart-define-from-file=../dart_define.json
```

Executável gerado:

```bash
admin_app/build/linux/x64/release/bundle/solarpro_admin
```

## Rodar Web Local

```bash
cd admin_app
../.tools/flutter/bin/flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081 --dart-define-from-file=../dart_define.json
```

## Validar

```bash
cd admin_app
../.tools/flutter/bin/flutter analyze
../.tools/flutter/bin/flutter test
```
