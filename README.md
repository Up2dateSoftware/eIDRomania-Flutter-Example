# eIDRomania Flutter SDK — Example Application

Demonstrates how to integrate the **Romanian eID SDK for Flutter** to read Romanian electronic identity cards (CEI) via NFC.

## What this example shows

- Initializing the SDK with a license key
- Reading an ID card with CAN + PIN (full data including CNP, address, face photo)
- Reading a passport with BAC (MRZ data)
- Real-time progress callbacks during NFC reading
- Typed error handling (wrong CAN, wrong PIN, card locked, NFC unavailable, etc.)
- Displaying card data and face photo

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Flutter 3.10+ | With Dart 3.0+ |
| Android 8.0+ (API 28) | NFC-capable device required |
| iOS 15.0+ | iPhone 7 or later |
| Romanian eID card (CEI) | Physical card required |
| eIDRomania SDK license key | Contact [office@up2date.ro](mailto:office@up2date.ro) |

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Android setup

Add the eIDRomania SDK repository to `android/settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        // eIDRomania Android SDK (public — no credentials required)
        maven {
            url = uri("https://europe-west1-maven.pkg.dev/eid-romania/eid-romania-sdk")
        }
    }
}
```

### 3. iOS setup

Add NFC capability in Xcode and update `ios/Runner/Info.plist`:

```xml
<key>NFCReaderUsageDescription</key>
<string>This app uses NFC to read electronic identity documents.</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
    <string>A000000077030C60000000FE00000500</string>
    <string>E828BD080FA000000167454441544100</string>
</array>
```

### 4. Add your license key

Edit `lib/main.dart` and enter your license key in the app.

## Run

```bash
flutter run
```

> The app requires a physical device with NFC — it does not work on emulators/simulators.

## SDK dependency

The SDK is installed from [pub.dev](https://pub.dev/packages/romanian_eid_sdk):

```yaml
dependencies:
  romanian_eid_sdk: ^1.0.0
```

## License

This example application is provided by **Up2Date Software SRL** for integration reference.
The SDK itself requires a separate commercial license — contact [office@up2date.ro](mailto:office@up2date.ro).
