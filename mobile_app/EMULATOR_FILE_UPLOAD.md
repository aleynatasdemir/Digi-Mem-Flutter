# Flutter Emülatöre Dosya Yükleme Rehberi

## 1. Android Emülatörü Çalıştırma

Önce bir Android emülatörü başlatmalısın. VS Code terminalde:

```bash
# Emülatörleri listele
emulator -list-avds

# Belirli bir emülatörü başlat (örneğin "Pixel_4_API_30")
emulator -avd Pixel_4_API_30
# veya
flutter emulators --launch Pixel_4_API_30
```

## 2. Fotoğraf/Dosya Yükleme Yöntemleri

### Yöntem 1: Emülatör Menüsü ile Dosya Yükleme (En Kolay)

1. **Emülatörün sağ tarafındaki kontrol panelini aç** (Android Emulator'ün yanındaki 3 nokta veya kontrol paneli)
2. **"Files" veya "Media" sekmesine git**
3. **Bilgisayarından fotoğraf veya video seç**
4. **Emülatöre drag-drop et**

### Yöntem 2: ADB ile Dosya Gönderme

```bash
# Emülatörde mevcut dosyaları görmek
adb shell ls /sdcard/DCIM/Camera

# Bilgisayardan emülatöre fotoğraf kopyala
adb push "C:\Users\90552\Pictures\photo.jpg" /sdcard/DCIM/Camera/

# Emülatöre video gönderme
adb push "C:\Users\90552\Videos\video.mp4" /sdcard/Movies/

# Gönderilen dosyayı doğrula
adb shell ls -la /sdcard/DCIM/Camera/
```

### Yöntem 3: Emülatör İçinde Galeriye Resim Ekle

```bash
# 1. Sample image oluştur
adb shell screencap -p /sdcard/DCIM/Camera/screenshot.png

# 2. Medya tarayıcısını refresh et
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/DCIM/Camera/screenshot.png
```

## 3. Flutter Uygulamada Dosya Seçme

Uygulamada ana sayfadaki "Fotoğraf" butonuna tıklayınca:

```
Fotoğraf Yükle Ekranı Açılacak
        ↓
"Galeriden Seç" Tap Et
        ↓
Emülatör Galerisi Açılacak
        ↓
Yüklediğin Fotoğraf Görünecek
        ↓
Fotoğraf Seç
        ↓
Anı Detayı Doldur (Başlık, Etiket vs)
        ↓
"Kaydet" Tap Et
```

## 4. Test İçin Hızlı Dosya İndirme

Test etmek için işletim sisteminde varsayılan resimleri kullanabilirsin:

**Windows:**
```bash
# Eğer test fotoğrafı yoksa bilinen konumlardan kopyala
copy "C:\Windows\Web\Wallpaper\Windows\img0.jpg" "C:\Users\90552\Pictures\test.jpg"
```

**macOS:**
```bash
cp /Library/Desktop\ Pictures/Leaf.jpg ~/Pictures/test.jpg
```

**Linux:**
```bash
cp /usr/share/backgrounds/*.jpg ~/Pictures/test.jpg
```

## 5. Emülatörde Fotoğrafları Kontrol Etme

```bash
# Galeride hangi dosyalar var
adb shell ls -la /sdcard/DCIM/Camera/

# Fotoğraf dosyasını bilgisayara indir
adb pull /sdcard/DCIM/Camera/photo.jpg

# Yüklenen dosyaları görmek
adb shell find /sdcard/DCIM/ -name "*.jpg"
```

## 6. Pratik Kullanım Akışı

```bash
# 1. Emülatörü başlat
emulator -avd Pixel_4_API_30

# 2. Yeni terminal sekmesinde Flutter uygulamayı çalıştır
flutter run

# 3. Başka bir terminal sekmesinde test fotoğrafı gönder
adb push "C:\Users\90552\Pictures\test.jpg" /sdcard/DCIM/Camera/

# 4. Emülatörde:
# - Ana Sayfaya Git
# - "Fotoğraf" butonuna tap et
# - "Galeriden Seç" (veya Image Picker aç)
# - Test fotoğrafını seç
# - Başlık ve etiket ekle
# - Kaydet butonu tap et
```

## 7. Sorun Giderme

### Galeri Görünmüyor
```bash
# Medya tarayıcısını yenile
adb shell am startservice -a android.intent.action.MEDIA_SCANNER_SCAN_FILE
```

### Dosya Yüklemi Görmüyor
```bash
# Emülatörü restart et
adb reboot

# Veya galeriden yenile
adb shell am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///sdcard/
```

### Permission Hataları
```bash
# Uygulamaya izin ver
adb shell pm grant com.example.digimem android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant com.example.digimem android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm grant com.example.digimem android.permission.CAMERA
```

## 8. Video Yükleme Örneği

```bash
# Video dosyasını emülatöre gönder
adb push "C:\Users\90552\Videos\sample.mp4" /sdcard/Movies/

# Uygulamada Video tipini seç ve galeriden seç
```

## 9. Ses Dosyası Yükleme

```bash
# Ses dosyasını gönder
adb push "C:\Users\90552\Music\audio.mp3" /sdcard/Music/

# Uygulamada Ses Kaydı tipini seç
```

## 10. iOS Emülatöründe (Eğer Mac'in varsa)

```bash
# iOS Simulator'ü başlat
open -a Simulator

# Fotoğraf ekle: Simulator menüsü → Features → Toggle Device Appearance → Add Photo
```

---

### Kısayol Script (Windows PowerShell)

`test-upload.ps1` adında dosya oluştur:

```powershell
# Android emülatörüne test dosyası gönder
$testImagePath = "C:\Users\90552\Pictures\test.jpg"
adb push $testImagePath /sdcard/DCIM/Camera/
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/DCIM/Camera/test.jpg
Write-Host "Test fotoğrafı emülatöre gönderildi!"
```

Çalıştır:
```powershell
.\test-upload.ps1
```

---

**Tür Önerileri:**
- **Fotoğraf:** JPG, PNG (1-5 MB)
- **Video:** MP4 (H.264 codec) (5-50 MB)
- **Ses:** MP3, M4A (2-10 MB)
- **Metin:** String olarak direkt gir

Başarılı yüklemeler sonrası, arşiv sekmesinde tarihe göre gruplanmış anılarını görebilirsin! 📸
