# Solar Pro Android Release

Guia para gerar build Android release do app Flutter sem gravar segredos no
repositorio.

## Arquivos seguros fora do repositorio

- Keystore: `~/.solarpro/keystores/solarpro-release-keystore.jks`
- Artefatos da versao: `~/.solarpro/releases/0.1.0+2001/`
- Simbolos Dart: `~/.solarpro/releases/0.1.0+2001/symbols/`

Guarde o keystore e a senha em local seguro. Perder o keystore pode impedir
atualizacoes futuras do app na Play Store.

## Variaveis de ambiente

Defina as variaveis antes de gerar release:

```bash
export KEYSTORE_PATH="$HOME/.solarpro/keystores/solarpro-release-keystore.jks"
export KEYSTORE_PASSWORD="..."
export KEY_ALIAS="release"
export KEY_PASSWORD="..."
```

Nao salve senhas em arquivos versionados.

## Build AAB para Play Console

```bash
cd mobile_app
../.tools/flutter/bin/flutter clean
../.tools/flutter/bin/flutter pub get
../.tools/flutter/bin/flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Saida esperada:

```text
build/app/outputs/bundle/release/app-release.aab
```

## APKs por ABI para teste

```bash
cd mobile_app
../.tools/flutter/bin/flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

Saidas esperadas:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

## Verificacoes

```bash
aapt dump badging build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
unzip -l build/app/outputs/flutter-apk/app-arm64-v8a-release.apk | grep -E "kernel_blob.bin|libVkLayer_khronos_validation" || true
jarsigner -verify build/app/outputs/bundle/release/app-release.aab
```

Checklist:

- `application-debuggable` nao deve aparecer no badging release.
- `kernel_blob.bin` nao deve aparecer no APK release.
- `libVkLayer_khronos_validation.so` nao deve aparecer no APK release.
- `jarsigner` deve retornar `jar verified`.

## CI recomendado

Configure segredos no provedor de CI:

- `KEYSTORE_BASE64` ou arquivo seguro equivalente
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

Exemplo:

```bash
echo "$KEYSTORE_BASE64" | base64 -d > "$RUNNER_TEMP/release-keystore.jks"
export KEYSTORE_PATH="$RUNNER_TEMP/release-keystore.jks"
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

