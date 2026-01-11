# Docker ile PostgreSQL Kullanımı

## Sadece PostgreSQL Başlatma

```bash
docker-compose up -d postgres
```

Bu komut sadece PostgreSQL veritabanını başlatır:
- **Port**: 5433 (Flutter) / 5434 (Web)
- **Database**: digimem
- **User**: app
- **Password**: app_pass

## Backend Connection String

PostgreSQL kullanmak için `appsettings.Development.json` dosyasını şu şekilde güncelle:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5433;Database=digimem;Username=app;Password=app_pass"
  }
}
```

## Migration Çalıştırma

```bash
cd backend
dotnet ef database update
```

## Tüm Servisleri Başlatma

```bash
docker-compose up -d
```

Bu komut tüm servisleri başlatır:
- PostgreSQL
- Backend API
- (Web projesinde Frontend de)

## Durumu Kontrol Etme

```bash
docker-compose ps
docker-compose logs postgres
```

## Durdurma

```bash
docker-compose down
```

## Veritabanını Temizleme (Dikkat: Tüm veri silinir!)

```bash
docker-compose down -v
```
