# Solar Pro Mobile

Aplicativo principal do Solar Pro para Android e Web, feito em Flutter.

O mobile agora e o centro do produto. O desktop continua existindo como modulo
avancado para PDF, importacao de faturas, documentos e simulacoes financeiras
mais pesadas.

## Funcionalidades atuais

- Login com Supabase Auth.
- Dashboard comercial com KPIs.
- Consulta, busca, cadastro e edicao de clientes.
- Consulta, busca e filtro de projetos.
- Tela de detalhes do projeto.
- Atualizacao de status do projeto por permissao.
- Dimensionamento rapido.
- Salvamento de dimensionamento como projeto no Supabase.
- Cache local simples para leitura offline.

## Fora do mobile

- Geracao de PDF.
- Importacao de fatura.
- Gestao completa de documentos.
- Recursos administrativos avancados.

Essas partes continuam no app desktop.

## Rodar

Crie o arquivo real de ambiente na raiz do projeto:

```bash
cp dart_define.example.json dart_define.json
```

Preencha `dart_define.json` com a `Project URL` e a publishable/anon key do
Supabase. Esse arquivo real fica fora do Git.

Instale Flutter e rode:

```bash
cd mobile_app
flutter pub get
flutter run --dart-define-from-file=../dart_define.json
```

Rodar no navegador:

```bash
cd mobile_app
flutter run -d chrome --dart-define-from-file=../dart_define.json
```

Build web:

```bash
cd mobile_app
flutter build web --release --dart-define-from-file=../dart_define.json
```

Build APK:

```bash
cd mobile_app
flutter build apk --release --dart-define-from-file=../dart_define.json
```

Arquivo gerado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## iOS

Para gerar iOS e necessario rodar em macOS com Xcode:

```bash
cd mobile_app
flutter build ios --dart-define-from-file=../dart_define.json
```

Para publicar na App Store:

- Conta Apple Developer.
- Bundle ID.
- Certificados de assinatura.
- Politica de privacidade.
- TestFlight para validacao.

## Supabase

A configuracao de Supabase e lida por `--dart-define-from-file`:

```text
../dart_define.json
```

O app usa a mesma base do desktop. A chave usada no app deve ser sempre a anon
publishable key, nunca a service role key.
