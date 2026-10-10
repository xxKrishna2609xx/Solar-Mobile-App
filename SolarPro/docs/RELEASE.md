# SolarPro Android Release Guide

This document outlines the standard release procedure for generating production Android APK and App Bundle (AAB) builds for the SolarPro application.

---

## 1. Prerequisites

Ensure your build environment meets the following specifications:
- **Flutter SDK**: `3.22.x` or later (`flutter doctor -v`)
- **Dart SDK**: `>=3.0.0 <4.0.0`
- **Java JDK**: OpenJDK 17 (`java -version`)
- **Android SDK**: Build tools 34.0.0, Platform API 34, NDK installed

---

## 2. Signing Configuration

### A. Generate Release Keystore
If a production upload keystore does not already exist, generate one using Java `keytool`:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storetype JKS
```

### B. Configure `key.properties`
Create `android/key.properties` (never commit this file to public git):
```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

### C. Verify `android/app/build.gradle`
Ensure `signingConfigs` in `android/app/build.gradle` loads from `key.properties`:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 3. Pre-Flight Verification Checklist

Before triggering a release build, always execute the validation suite:

1. **Clean build artifacts**:
   ```powershell
   flutter clean
   flutter pub get
   ```

2. **Run Static Analysis (must report 0 issues)**:
   ```powershell
   flutter analyze
   ```

3. **Run Unit & Integration Test Suites**:
   ```powershell
   flutter test
   ```

4. **Run Cross-Portal Compatibility Check**:
   ```powershell
   dart run tools/check_compat.dart
   ```
   *Expected output: `Verdict: ALL PORTALS COMPATIBLE`.*

---

## 4. Release Build Commands

### Universal Release APK (For QA & Sideloading):
```powershell
flutter build apk --release
```
Output path: `build/app/outputs/flutter-apk/app-release.apk`

### Split-per-ABI APKs (Smaller download size per architecture):
```powershell
flutter build apk --release --split-per-abi
```
Outputs:
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

### Production Google Play App Bundle (AAB):
```powershell
flutter build appbundle --release
```
Output path: `build/app/outputs/bundle/release/app-release.aab`

---

## 5. Post-Build Verification

1. Install APK on a physical Android test device or emulator:
   ```powershell
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
2. Verify role routing for:
   - `admin` -> Admin Dashboard
   - `salesman` -> Salesman Portal
   - `electrician` / `structure` / `civil` -> Site Operations
   - `kedl` -> KEDL Discom Portal
   - `service` -> Service Desk
   - `client` -> Client Dashboard
3. Verify offline upload persistence:
   - Turn on airplane mode
   - Queue an upload or job start
   - Restart the app
   - Open Profile > "Offline Sync & Pending Uploads"
   - Confirm pending items are preserved and resume upload when connected.
