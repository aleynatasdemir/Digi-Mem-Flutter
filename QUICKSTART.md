# DigiMem Flutter - Hızlı Başlangıç

## Backend Başlatma

```bash
cd backend
dotnet restore
dotnet ef database update
dotnet run
```

Backend: http://localhost:5299

## Flutter App Başlatma

```bash
cd mobile_app
flutter pub get
flutter run -d windows
```

## Önemli Notlar

- Backend önce başlatılmalı
- `appsettings.Development.json` dosyasını oluşturmayı unutmayın
- Gemini API key gerekli (AI kolaj için)
- Spotify credentials opsiyonel (müzik anıları için)

Detaylı bilgi için `README.md` dosyasına bakın.
