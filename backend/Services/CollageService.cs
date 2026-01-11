using Microsoft.EntityFrameworkCore;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.PixelFormats;
using DigiMem.Data;

namespace DigiMem.Services;

public class CollageService : ICollageService
{
    private readonly AppDbContext _context;
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<CollageService> _logger;
    private readonly HttpClient _httpClient;

    public CollageService(
        AppDbContext context, 
        IWebHostEnvironment env,
        ILogger<CollageService> logger,
        IHttpClientFactory httpClientFactory)
    {
        _context = context;
        _env = env;
        _logger = logger;
        _httpClient = httpClientFactory.CreateClient();
    }

    public async Task<List<WeekInfo>> GetAvailableWeeksAsync(string userId, int year, int month)
    {
        var startDate = new DateTime(year, month, 1);
        var endDate = startDate.AddMonths(1);

        var photos = await _context.Memories
            .Where(m => m.UserId == userId && 
                       m.Type == "photo" && 
                       m.FileUrl != null)
            .Select(m => new { m.CreatedAt, m.MemoryDate })
            .ToListAsync();

        // MemoryDate varsa onu kullan, yoksa CreatedAt kullan
        var photoDates = photos
            .Select(p => p.MemoryDate ?? p.CreatedAt)
            .Where(d => d >= startDate && d < endDate)
            .ToList();

        _logger.LogInformation("Found {Count} photos for {Year}-{Month}. Dates: {Dates}", 
            photoDates.Count, year, month, string.Join(", ", photoDates.Select(p => p.ToString("yyyy-MM-dd HH:mm"))));

        var weeks = new List<WeekInfo>();
        var seenWeeks = new HashSet<string>();
        var currentDate = startDate;

        // Ayın tüm haftalarını göster
        while (currentDate < endDate)
        {
            // Haftanın başlangıcını bul (Pazar = 0)
            var dayOfWeek = (int)currentDate.DayOfWeek;
            var weekStart = currentDate.Date.AddDays(-dayOfWeek);
            var weekEnd = weekStart.AddDays(7); // Bir sonraki haftanın başlangıcı
            
            // Hafta anahtarı oluştur (tekrar eklememek için)
            var weekKey = weekStart.ToString("yyyy-MM-dd");
            
            if (!seenWeeks.Contains(weekKey))
            {
                seenWeeks.Add(weekKey);
                
                // Bu haftadaki fotoğraf sayısını say (weekEnd dahil değil, bir sonraki hafta)
                var photoCount = photoDates.Count(p => p >= weekStart && p < weekEnd);
                
                _logger.LogInformation("Week {WeekStart} - {WeekEnd}: {PhotoCount} photos", 
                    weekStart.ToString("yyyy-MM-dd"), weekEnd.ToString("yyyy-MM-dd"), photoCount);
                
                // Tüm haftaları ekle, fotoğraf olsun olmasın
                weeks.Add(new WeekInfo(weekStart, weekEnd, photoCount));
            }
            
            // Bir sonraki haftaya geç
            currentDate = currentDate.AddDays(7);
        }

        // Tarihe göre sırala
        return weeks.OrderBy(w => w.WeekStart).ToList();
    }

    public async Task<string> GenerateWeeklyCollageAsync(string userId, DateTime weekStart)
    {
        var weekEnd = weekStart.AddDays(7);
        var gridSize = 3; // 3x3 grid for weekly
        return await GenerateCollageAsync(userId, weekStart, weekEnd, gridSize, "weekly");
    }

    public async Task<string> GenerateMonthlyCollageAsync(string userId, int year, int month)
    {
        var monthStart = new DateTime(year, month, 1);
        var monthEnd = monthStart.AddMonths(1);
        var gridSize = 4; // 4x4 grid for monthly
        return await GenerateCollageAsync(userId, monthStart, monthEnd, gridSize, "monthly");
    }

    public async Task<string> GenerateYearlyCollageAsync(string userId, int year)
    {
        var yearStart = new DateTime(year, 1, 1);
        var yearEnd = yearStart.AddYears(1);
        var gridSize = 5; // 5x5 grid for yearly
        return await GenerateCollageAsync(userId, yearStart, yearEnd, gridSize, "yearly");
    }

    private async Task<string> GenerateCollageAsync(
        string userId, 
        DateTime startDate, 
        DateTime endDate, 
        int gridSize, 
        string periodType)
    {
        // Fetch photos from the period
        var maxPhotos = gridSize * gridSize;
        var photos = await _context.Memories
            .Where(m => m.UserId == userId && 
                       m.Type == "photo" && 
                       m.CreatedAt >= startDate && 
                       m.CreatedAt < endDate &&
                       m.FileUrl != null)
            .OrderByDescending(m => m.CreatedAt)
            .Take(maxPhotos)
            .Select(m => m.FileUrl)
            .ToListAsync();

        if (photos.Count == 0)
        {
            throw new InvalidOperationException("No photos found for the selected period");
        }

        // Create collage
        const int cellSize = 400; // Each photo will be 400x400
        const int padding = 10;
        var collageSize = (cellSize * gridSize) + (padding * (gridSize + 1));

        using var collage = new Image<Rgba32>(collageSize, collageSize);

        // Fill background with white
        collage.Mutate(ctx => ctx.BackgroundColor(Color.White));

        // Download and place images
        int photoIndex = 0;
        for (int row = 0; row < gridSize && photoIndex < photos.Count; row++)
        {
            for (int col = 0; col < gridSize && photoIndex < photos.Count; col++)
            {
                try
                {
                    var photoUrl = photos[photoIndex];
                    var imageBytes = await DownloadImageAsync(photoUrl);

                    if (imageBytes != null)
                    {
                        using var photo = Image.Load<Rgba32>(imageBytes);
                        
                        // Resize to fit cell
                        photo.Mutate(ctx => ctx.Resize(new ResizeOptions
                        {
                            Size = new Size(cellSize, cellSize),
                            Mode = ResizeMode.Crop
                        }));

                        // Calculate position
                        var x = padding + (col * (cellSize + padding));
                        var y = padding + (row * (cellSize + padding));

                        // Draw photo onto collage
                        collage.Mutate(ctx => ctx.DrawImage(photo, new Point(x, y), 1f));
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to process photo at index {Index}", photoIndex);
                }

                photoIndex++;
            }
        }

        // Save collage
        var collagesDir = Path.Combine(_env.WebRootPath, "collages");
        Directory.CreateDirectory(collagesDir);

        var filename = $"{periodType}_{userId}_{startDate:yyyyMMdd}_{Guid.NewGuid():N}.jpg";
        var filepath = Path.Combine(collagesDir, filename);

        await collage.SaveAsJpegAsync(filepath);

        return filename;
    }

    private async Task<byte[]?> DownloadImageAsync(string? url)
    {
        if (string.IsNullOrEmpty(url))
            return null;

        try
        {
            // Handle local file URLs
            if (url.StartsWith("/uploads/"))
            {
                var localPath = Path.Combine(_env.WebRootPath, url.TrimStart('/'));
                if (File.Exists(localPath))
                {
                    return await File.ReadAllBytesAsync(localPath);
                }
            }
            // Handle HTTP URLs
            else if (url.StartsWith("http://") || url.StartsWith("https://"))
            {
                return await _httpClient.GetByteArrayAsync(url);
            }

            return null;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to download image from {Url}", url);
            return null;
        }
    }
}
