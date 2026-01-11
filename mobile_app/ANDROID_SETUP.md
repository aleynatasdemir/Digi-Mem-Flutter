# Android Studio Kurulum ve Yapılandırma

## 🔧 Android Toolchain Hatalarını Düzeltme

### Hata: cmdline-tools component is missing

**Çözüm:**

1. **Android Studio'yu açın**
2. **Welcome ekranında:** More Actions → SDK Manager
   **VEYA açık projede:** Tools → SDK Manager

3. **SDK Manager penceresinde:**
   - **SDK Tools** sekmesine geçin
   - **"Show Package Details"** işaretini kaldırın (daha basit görünüm)
   - Şunları işaretleyin:
     - ☑️ Android SDK Command-line Tools (latest)
     - ☑️ Android SDK Build-Tools
     - ☑️ Android SDK Platform-Tools
     - ☑️ Android Emulator
     - ☑️ Google Play Services (opsiyonel)
   - **Apply** → **OK** tıklayın
   - İndirme ve kurulum tamamlanana kadar bekleyin

4. **Terminal'de kontrol edin:**
```powershell
flutter doctor --android-licenses
# "y" yazıp Enter ile tüm lisansları kabul edin

flutter doctor
# Artık tüm kontrollerden geçmeli
```

## 📱 Emulator Oluşturma

### 1. Device Manager'ı Açın
- Android Studio → Tools → Device Manager
- VEYA Welcome ekranında → More Actions → Virtual Device Manager

### 2. Yeni Sanal Cihaz Oluşturun
1. **Create Device** butonuna tıklayın
2. **Cihaz seçin:** 
   - Önerilen: Pixel 5, Pixel 6, Pixel 7
   - **Next**
3. **Sistem görüntüsü seçin:**
   - Önerilen: **API Level 33 (Android 13.0 - Tiramisu)** veya üstü
   - **Download** yapın (henüz indirilmediyse)
   - **Next**
4. **Ayarları onaylayın:**
   - AVD Name: Pixel_5_API_33 (varsayılan)
   - **Finish**

### 3. Emulator'ü Başlatın
- Device Manager'da yeni cihazınızın yanındaki ▶️ **Play** butonuna basın
- İlk açılış biraz zaman alabilir

## 🚀 Flutter Projesini Çalıştırma

### Terminal'de:
```powershell
cd C:\Users\90552\OneDrive\Belgeler\GitHub\Digi-Mem\mobile_app

# Paketleri yükle
flutter pub get

# Cihazları kontrol et
flutter devices

# Uygulamayı çalıştır
flutter run
```

### Android Studio'da:
1. **File → Open** → `mobile_app` klasörünü seçin
2. Üst menüde emulator/cihazınızı seçin
3. Yeşil **Play** butonuna basın (Shift+F10)

## ⚙️ ANDROID_HOME Ortam Değişkeni (Gerekirse)

Eğer hala sorun yaşarsanız:

1. **Sistem Ortam Değişkenleri:**
   - Windows Arama → "environment" → "Edit system environment variables"
   - **Environment Variables** butonuna tıklayın

2. **Yeni Kullanıcı Değişkeni:**
   - **New** tıklayın
   - Variable name: `ANDROID_HOME`
   - Variable value: `C:\Users\90552\AppData\Local\Android\Sdk`
   - **OK**

3. **Path'e Ekle:**
   - **Path** değişkenini seçin → **Edit**
   - **New** tıklayın, şunu ekleyin:
     - `%ANDROID_HOME%\platform-tools`
     - `%ANDROID_HOME%\cmdline-tools\latest\bin`
     - `%ANDROID_HOME%\emulator`
   - **OK** → **OK**

4. **PowerShell'i yeniden başlatın** ve `flutter doctor` çalıştırın

## 🎯 Backend Bağlantısı için IP Ayarı

### Emulator İçin:
`lib/utils/api_constants.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

### Fiziksel Cihaz İçin:
```powershell
# Bilgisayarınızın IP'sini bulun
ipconfig

# Örnek: 192.168.1.100
# Sonra api_constants.dart'ta:
# static const String baseUrl = 'http://192.168.1.100:5000/api';
```

## ✅ Başarı Kontrol Listesi

- [ ] Android Studio yüklü
- [ ] SDK Command-line Tools yüklü
- [ ] `flutter doctor` tüm kontrollerden geçiyor
- [ ] Emulator oluşturuldu ve çalışıyor
- [ ] Backend çalışıyor (`dotnet run`)
- [ ] PostgreSQL aktif (`docker-compose up -d`)
- [ ] API URL doğru ayarlandı
- [ ] `flutter run` komutu çalışıyor

## 🆘 Sorun Giderme

### Emulator çok yavaş:
```
Device Manager → Emulator ayarları
→ Show Advanced Settings
→ RAM: 4GB
→ VM heap: 512MB
→ Graphics: Hardware - GLES 2.0
```

### Gradle build hatası:
```powershell
cd mobile_app
flutter clean
flutter pub get
flutter run
```

### Backend'e bağlanamıyor:
1. Backend'in çalıştığını kontrol edin
2. Windows Defender Firewall'da 5000 portunu açın
3. API URL'sini doğrulayın (10.0.2.2 emulator için)
