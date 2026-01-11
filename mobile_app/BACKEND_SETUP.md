# Digi-Mem Backend CORS Ayarları Güncellemesi

Backend'inizin mobil uygulamadan gelen istekleri kabul etmesi için CORS yapılandırması gerekiyor.

## Güncelleme:

`backend/Program.cs` dosyasını açın ve CORS ayarlarını güncelleyin:

```csharp
// CORS politikasını ekleyin (builder.Services kısmına)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Middleware'e ekleyin (app.Use... kısmında)
app.UseCors("AllowAll");
```

## PostgreSQL Bağlantı Ayarları:

`backend/appsettings.Development.json` dosyasında connection string'i kontrol edin:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=digimem;Username=postgres;Password=postgres"
  },
  "Jwt": {
    "Secret": "your-super-secret-key-min-32-characters-long!"
  }
}
```

Bu güncellemeler mobil uygulamanın backend'e sorunsuz bağlanmasını sağlayacak.
