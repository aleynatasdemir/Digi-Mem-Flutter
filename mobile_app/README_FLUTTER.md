# Digi-Mem Flutter Mobil Uygulaması

## 📱 Android Studio'da Nasıl Çalıştırılır?

### 1. Ön Gereksinimler

✅ **Android Studio yüklü** (Zaten yüklü)
✅ **Flutter SDK yüklü olmalı**
- Flutter'ı indirin: https://docs.flutter.dev/get-started/install/windows
- Flutter SDK'yı bir klasöre çıkarın (örn: `C:\flutter`)
- Sistem ortam değişkenlerine `C:\flutter\bin` ekleyin

### 2. Flutter Kurulumunu Kontrol Et

PowerShell'de şu komutları çalıştırın:

```powershell
# Flutter doktor kontrolü
flutter doctor

# Eksik bileşenleri gösterir, gerekli kurulumları yapın
```

### 3. Backend'i Çalıştır

Backend'in çalışır durumda olması gerekiyor:

```powershell
# Backend klasörüne git
cd C:\Users\90552\OneDrive\Belgeler\GitHub\Digi-Mem\backend

# PostgreSQL veritabanını başlat (Docker ile)
cd ..
docker-compose up -d

# Backend'i çalıştır
cd backend
dotnet run
```

Backend şu adreste çalışacak: `http://localhost:5000`

### 4. API URL'ini Ayarla

**ÖNEMLİ:** Emulator'da `localhost` çalışmaz!

`mobile_app/lib/utils/api_constants.dart` dosyasını açın:

```dart
// EMULATOR için:
static const String baseUrl = 'http://10.0.2.2:5000/api';

// FİZİKSEL CİHAZ için (WiFi üzerinden):
// Bilgisayarınızın IP adresini bulun ve kullanın:
// static const String baseUrl = 'http://192.168.1.100:5000/api';
```

**IP Adresinizi Bulmak İçin:**
```powershell
ipconfig
# "IPv4 Address" değerini kullanın (örn: 192.168.1.100)
```

### 5. Android Studio'da Projeyi Aç

1. **Android Studio'yu açın**
2. **File → Open** seçin
3. `C:\Users\90552\OneDrive\Belgeler\GitHub\Digi-Mem\mobile_app` klasörünü seçin
4. **OK** tıklayın

### 6. Bağımlılıkları Yükle

Android Studio terminalinde:

```powershell
# Proje klasörüne git
cd mobile_app

# Flutter paketlerini yükle
flutter pub get
```

### 7. Emulator veya Cihaz Hazırla

#### Emulator Kullanımı:
1. Android Studio'da **Tools → Device Manager**
2. **Create Device** butonu
3. Bir cihaz seçin (örn: Pixel 5)
4. Sistem görüntüsü seçin (örn: API 33 - Android 13)
5. **Finish** ve sonra **Play** butonuna basın

#### Fiziksel Cihaz Kullanımı:
1. Telefonda **Developer Options** açın
2. **USB Debugging** etkinleştirin
3. USB ile bilgisayara bağlayın
4. Cihazda çıkan izin isteğini onaylayın

### 8. Uygulamayı Çalıştır

**Android Studio'da:**
1. Üst menüde cihaz/emulator'ünüzün seçili olduğundan emin olun
2. Yeşil **Play** butonuna basın (veya Shift+F10)

**VEYA Terminal'de:**
```powershell
flutter run
```

### 9. Hot Reload Kullanımı

Uygulama çalışırken kod değişikliği yaptığınızda:
- **r** tuşuna basın → Hot reload
- **R** tuşuna basın → Hot restart
- **q** tuşuna basın → Çıkış

## 🔧 Sık Karşılaşılan Sorunlar

### Problem: "Unable to connect to the server"
**Çözüm:**
- Backend'in çalıştığından emin olun (`dotnet run`)
- API URL'sinin doğru olduğunu kontrol edin
- Emulator kullanıyorsanız `10.0.2.2` kullanın
- Fiziksel cihaz kullanıyorsanız bilgisayarın IP'sini kullanın
- Firewall'un 5000 portunu engellediğini kontrol edin

### Problem: "Camera/Gallery permission denied"
**Çözüm:**
- Emulator/cihaz ayarlarından uygulama izinlerini verin
- Uygulamayı yeniden başlatın

### Problem: "Gradle build failed"
**Çözüm:**
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

## 📁 Proje Yapısı

```
mobile_app/
├── lib/
│   ├── main.dart              # Ana uygulama giriş noktası
│   ├── models/                # Data modelleri
│   │   ├── user.dart
│   │   └── memory.dart
│   ├── services/              # API servisleri
│   │   ├── auth_service.dart
│   │   └── memory_service.dart
│   ├── screens/               # Uygulama sayfaları
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── profile_screen.dart
│   │   └── add_memory_screen.dart
│   ├── widgets/               # Tekrar kullanılabilir widget'lar
│   │   └── memory_card.dart
│   └── utils/                 # Yardımcı dosyalar
│       ├── api_constants.dart
│       └── theme.dart
├── android/                   # Android özel dosyalar
├── pubspec.yaml              # Bağımlılıklar
└── README_FLUTTER.md         # Bu dosya
```

## 🎯 Özellikler

✅ Login/Register (Backend'e bağlı)
✅ Anı listeleme
✅ Yeni anı ekleme (Fotoğraf, Video, Ses, Metin)
✅ Anı silme
✅ Profil görüntüleme
✅ İstatistikler
✅ Dark/Light tema desteği
✅ Material 3 tasarımı

## 🚀 Build ve Release

### Debug APK Oluşturma:
```powershell
flutter build apk --debug
```

### Release APK Oluşturma:
```powershell
flutter build apk --release
```

APK dosyası: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (Google Play için):
```powershell
flutter build appbundle --release
```

## 📝 Notlar

- Backend API'nin çalışır durumda olması gerekiyor
- Emulator'da internet bağlantısı olmalı
- İlk açılışta kayıt olun veya giriş yapın
- Test email: `test@example.com` / Şifre: `123456` (Backend'de oluşturmanız gerekir)

## 🤝 Destek

Sorun yaşarsanız:
1. `flutter doctor` çalıştırın
2. `flutter clean` ve `flutter pub get` yapın
3. Android Studio'yu yeniden başlatın
4. Emulator'ü yeniden başlatın
