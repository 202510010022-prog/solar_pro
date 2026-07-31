#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
DART_BIN="${DART_BIN:-dart}"
DART_DEFINE_FILE="$ROOT_DIR/dart_define.json"
RELEASES_DIR="$ROOT_DIR/releases"

fail() {
  echo
  echo "ERRO: $1"
  echo "Nenhum build foi gerado."
  exit 1
}

run_step() {
  local label="$1"
  shift

  echo
  echo "==> $label"
  "$@" || fail "$label falhou."
}

extract_version() {
  local pubspec="$1"
  awk '/^version:/ { print $2; exit }' "$pubspec"
}

safe_version_name() {
  echo "$1" | tr '+/' '__'
}

copy_dir_clean() {
  local source="$1"
  local target="$2"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  cp -R "$source" "$target"
}

echo "Solar Pro - release pipeline"
echo "Workspace: $ROOT_DIR"

if [ ! -f "$DART_DEFINE_FILE" ]; then
  fail "Arquivo dart_define.json nao encontrado em $ROOT_DIR. Crie a partir de dart_define.example.json antes de gerar release."
fi

echo
echo "Etapa 1/4 - validacoes e testes"
run_step "mobile_app: flutter pub get" bash -c "cd '$ROOT_DIR/mobile_app' && '$FLUTTER_BIN' pub get"
run_step "mobile_app: flutter analyze" bash -c "cd '$ROOT_DIR/mobile_app' && '$FLUTTER_BIN' analyze"
run_step "mobile_app: flutter test" bash -c "cd '$ROOT_DIR/mobile_app' && '$FLUTTER_BIN' test"
run_step "admin_app: flutter pub get" bash -c "cd '$ROOT_DIR/admin_app' && '$FLUTTER_BIN' pub get"
run_step "admin_app: flutter analyze" bash -c "cd '$ROOT_DIR/admin_app' && '$FLUTTER_BIN' analyze"
run_step "admin_app: flutter test" bash -c "cd '$ROOT_DIR/admin_app' && '$FLUTTER_BIN' test"

echo
echo "==> integration_tests: dart test"
echo "Aviso: este passo requer integration_tests/.env configurado com o Supabase de teste."
if [ -f "$ROOT_DIR/integration_tests/.env" ]; then
  (cd "$ROOT_DIR/integration_tests" && "$DART_BIN" test) || fail "integration_tests: dart test falhou."
else
  echo "Aviso: integration_tests/.env nao encontrado. Pulando testes de integracao neste ambiente."
fi

echo
echo "Etapa 2/4 - versoes"
MOBILE_VERSION="$(extract_version "$ROOT_DIR/mobile_app/pubspec.yaml")"
ADMIN_VERSION="$(extract_version "$ROOT_DIR/admin_app/pubspec.yaml")"
MOBILE_RELEASE_NAME="mobile_$(safe_version_name "$MOBILE_VERSION")"
ADMIN_RELEASE_NAME="admin_$(safe_version_name "$ADMIN_VERSION")"
MOBILE_RELEASE_DIR="$RELEASES_DIR/$MOBILE_RELEASE_NAME"
ADMIN_RELEASE_DIR="$RELEASES_DIR/$ADMIN_RELEASE_NAME"

if [ -z "$MOBILE_VERSION" ]; then
  fail "Nao foi possivel ler version em mobile_app/pubspec.yaml."
fi

if [ -z "$ADMIN_VERSION" ]; then
  fail "Nao foi possivel ler version em admin_app/pubspec.yaml."
fi

echo "Mobile version: $MOBILE_VERSION"
echo "Admin version:  $ADMIN_VERSION"

if [ -z "${KEYSTORE_PATH:-}" ]; then
  fail "Variavel de ambiente KEYSTORE_PATH nao definida. Configure a assinatura Android antes de gerar APK/AAB."
fi

if [ -z "${KEYSTORE_PASSWORD:-}" ]; then
  fail "Variavel de ambiente KEYSTORE_PASSWORD nao definida. Configure a assinatura Android antes de gerar APK/AAB."
fi

if [ -z "${KEY_ALIAS:-}" ]; then
  fail "Variavel de ambiente KEY_ALIAS nao definida. Configure a assinatura Android antes de gerar APK/AAB."
fi

if [ -z "${KEY_PASSWORD:-}" ]; then
  fail "Variavel de ambiente KEY_PASSWORD nao definida. Configure a assinatura Android antes de gerar APK/AAB."
fi

echo
echo "Etapa 3/4 - builds"
run_step "mobile_app: build APK release" bash -c "cd '$ROOT_DIR/mobile_app' && '$FLUTTER_BIN' build apk --release --dart-define-from-file=../dart_define.json"
run_step "mobile_app: build AAB release" bash -c "cd '$ROOT_DIR/mobile_app' && '$FLUTTER_BIN' build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=../dart_define.json"
run_step "mobile_app: build web release" bash -c "cd '$ROOT_DIR/mobile_app' && '$FLUTTER_BIN' build web --release --dart-define-from-file=../dart_define.json"
run_step "admin_app: build web release" bash -c "cd '$ROOT_DIR/admin_app' && '$FLUTTER_BIN' build web --release --dart-define-from-file=../dart_define.json"

echo
echo "Etapa 4/4 - organizando artefatos"
rm -rf "$MOBILE_RELEASE_DIR" "$ADMIN_RELEASE_DIR"
mkdir -p "$MOBILE_RELEASE_DIR" "$ADMIN_RELEASE_DIR"

cp "$ROOT_DIR/mobile_app/build/app/outputs/flutter-apk/app-release.apk" "$MOBILE_RELEASE_DIR/app-release.apk"
cp "$ROOT_DIR/mobile_app/build/app/outputs/bundle/release/app-release.aab" "$MOBILE_RELEASE_DIR/app-release.aab"
copy_dir_clean "$ROOT_DIR/mobile_app/build/web" "$MOBILE_RELEASE_DIR/web"
copy_dir_clean "$ROOT_DIR/admin_app/build/web" "$ADMIN_RELEASE_DIR/web"

if [ -d "$ROOT_DIR/mobile_app/build/symbols" ]; then
  copy_dir_clean "$ROOT_DIR/mobile_app/build/symbols" "$MOBILE_RELEASE_DIR/symbols"
fi

echo
echo "Release gerada com sucesso."
echo
echo "Resumo:"
echo "- Mobile: $MOBILE_VERSION"
echo "  APK: $MOBILE_RELEASE_DIR/app-release.apk"
echo "  AAB: $MOBILE_RELEASE_DIR/app-release.aab"
echo "  Web: $MOBILE_RELEASE_DIR/web/"
if [ -d "$MOBILE_RELEASE_DIR/symbols" ]; then
  echo "  Simbolos: $MOBILE_RELEASE_DIR/symbols/"
fi
echo "- Admin: $ADMIN_VERSION"
echo "  Web: $ADMIN_RELEASE_DIR/web/"
echo
echo "Proximos passos manuais:"
echo "- Enviar o AAB para o Play Console."
echo "- Testar o APK em um dispositivo real antes de distribuir."
echo "- Fazer deploy dos diretórios web do mobile e do admin no provedor escolhido."
echo "- Atualizar notas de versao/changelog e materiais do Play Console quando necessario."
