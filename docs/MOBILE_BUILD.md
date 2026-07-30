# Solar Pro Mobile Build

## Ambiente local instalado

Flutter e Dart:

```text
/home/kevinklecio96/solar_manager/.tools/flutter
```

Android SDK:

```text
/home/kevinklecio96/solar_manager/.tools/android-sdk
```

Variaveis adicionadas em `~/.zshrc`, `~/.zprofile`, `~/.bashrc` e `~/.profile`:

```bash
export PATH="/home/kevinklecio96/solar_manager/.tools/flutter/bin:$PATH"
export ANDROID_SDK_ROOT="/home/kevinklecio96/solar_manager/.tools/android-sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
```

## Android

Gerar APK:

```bash
cd mobile_app
flutter build apk --release
```

Saida:

```text
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

Gerar AAB para Google Play:

```bash
cd mobile_app
flutter build appbundle --release
```

Saida:

```text
mobile_app/build/app/outputs/bundle/release/app-release.aab
```

## iOS

Nao e possivel compilar iOS neste Linux. O build iOS exige macOS com:

- Xcode
- CocoaPods
- Apple Developer account
- Certificados/perfis de assinatura

No Mac:

```bash
cd mobile_app
flutter pub get
flutter build ios --release
```

Para TestFlight/App Store, abrir `ios/Runner.xcworkspace` no Xcode e configurar:

- Team
- Bundle Identifier
- Signing & Capabilities
- Version/Build
