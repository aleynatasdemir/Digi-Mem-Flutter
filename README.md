# DigiMem - Flutter Mobile Application

Dijital anılarınızı güvenle saklayın ve düzenleyin. Flutter ile geliştirilmiş mobil uygulama.

## 📱 Özellikler

- ✅ Fotoğraf, video, ses kaydı, metin ve müzik anıları
- ✅ Gemini AI ile akıllı kolaj oluşturma (haftalık/aylık)
- ✅ Takvim görünümü ile anılara kolay erişim
- ✅ İstatistikler ve analiz ekranı
- ✅ Spotify entegrasyonu
- ✅ Light mode arayüz
- ✅ Windows, Android, iOS desteği

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.x veya üzeri)
- .NET 8.0 SDK
- Visual Studio 2022 veya Visual Studio Code
- Git

### Backend Kurulumu

1. Backend klasörüne git:
```bash
cd backend
```

2. Gerekli paketleri yükle:
```bash
dotnet restore
```

3. `appsettings.Development.json` dosyasını oluştur:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=digimem.db"
  },
  "Jwt": {
    "Key": "your-super-secret-key-min-32-characters-long",
    "Issuer": "DigiMem",
    "Audience": "DigiMem"
  },
  "Spotify": {
    "ClientId": "your-spotify-client-id",
    "ClientSecret": "your-spotify-client-secret"
  },
  "Gemini": {
    "ApiKey": "your-gemini-api-key"
  }
}
```

4. Database migration'larını çalıştır:
```bash
dotnet ef database update
```

5. Backend'i başlat:
```bash
dotnet run
```

Backend varsayılan olarak `http://localhost:5299` adresinde çalışacaktır.

### Flutter App Kurulumu

1. Mobile app klasörüne git:
```bash
cd mobile_app
```

2. Gerekli paketleri yükle:
```bash
flutter pub get
```

3. Windows için çalıştır:
```bash
flutter run -d windows
```

4. Android için çalıştır:
```bash
flutter run -d android
```

## 🔧 Yapılandırma

### API Endpoint'leri

`mobile_app/lib/utils/api_constants.dart` dosyasında API URL'leri platform bazlı ayarlanmıştır:

- **Windows/iOS/Web**: `http://localhost:5299`
- **Android Emulator**: `http://10.0.2.2:5299`

Canlı ortam için bu dosyayı güncelleyin.

### Gemini AI Kurulumu

1. [Google AI Studio](https://makersuite.google.com/app/apikey) adresinden API key alın
2. Backend `appsettings.Development.json` dosyasına ekleyin
3. Haftalık/aylık kolaj özellikleri otomatik çalışacaktır

### Spotify Entegrasyonu

1. [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) adresinden uygulama oluşturun
2. Client ID ve Client Secret alın
3. Redirect URI olarak `http://localhost:5299/api/spotify-auth/callback` ekleyin
4. Backend `appsettings.Development.json` dosyasına ekleyin

## 📂 Proje Yapısı

```
digimem_flutter/
├── backend/                    # ASP.NET Core Web API
│   ├── Controllers/           # API endpoint'leri
│   ├── Data/                  # Database context ve migrations
│   ├── Models/                # Veri modelleri
│   ├── Services/              # İş mantığı servisleri
│   └── wwwroot/               # Static dosyalar (yüklenen medya)
│
├── mobile_app/                # Flutter uygulaması
│   ├── lib/
│   │   ├── main.dart         # Uygulama giriş noktası
│   │   ├── models/           # Veri modelleri
│   │   ├── screens/          # Ekranlar
│   │   ├── services/         # API servisleri
│   │   ├── utils/            # Yardımcı fonksiyonlar
│   │   └── widgets/          # Özel widget'lar
│   └── pubspec.yaml          # Flutter bağımlılıkları
│
└── README.md                  # Bu dosya
```

## 🎯 Kullanım

### Yeni Anı Ekleme

1. Ana sayfadan istediğiniz anı tipini seçin (Fotoğraf, Video, Ses, Şarkı, Metin)
2. Gerekli bilgileri doldurun
3. Kaydet butonuna basın

### AI Kolaj Oluşturma

1. **Analiz** sekmesine gidin
2. **Haftalık Özet** veya **Aylık Özet** seçin
3. Yıl, ay (ve hafta) seçin
4. **AI ile Oluştur** butonuna basın
5. Gemini AI otomatik olarak anılarınızdan kolaj oluşturacak
6. Oluşan kolajı görüntüleyin ve indirin

### Arşiv Görünümü

1. **Arşiv** sekmesinde takvim görünümünü kullanın
2. Günlere tıklayarak o günün anılarını görün
3. Anılara tıklayarak detayları görüntüleyin

## 🔐 Güvenlik

- JWT tabanlı kimlik doğrulama
- Şifreler hash'lenerek saklanır
- HTTPS kullanımı önerilir (production)

## 🛠️ Geliştirme

### Debug Mode

```bash
cd backend
dotnet run --launch-profile "http"

cd mobile_app
flutter run -d windows --debug
```

### Build

```bash
cd mobile_app

# Windows için
flutter build windows --release

# Android için
flutter build apk --release

# iOS için
flutter build ios --release
```

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📧 İletişim

Sorularınız için issue açabilirsiniz.

## 🙏 Teşekkürler

- Flutter Team
- ASP.NET Core Team
- Google Gemini AI
- Spotify API
