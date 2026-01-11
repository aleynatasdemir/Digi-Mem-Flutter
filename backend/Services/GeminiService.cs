using Microsoft.EntityFrameworkCore;
using DigiMem.Data;
using System.Text;
using System.Text.Json;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.PixelFormats;

namespace DigiMem.Services;

public class GeminiService : IGeminiService
{
    private readonly AppDbContext _context;
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<GeminiService> _logger;
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;

    public GeminiService(
        AppDbContext context,
        IWebHostEnvironment env,
        ILogger<GeminiService> logger,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration)
    {
        _context = context;
        _env = env;
        _logger = logger;
        _httpClient = httpClientFactory.CreateClient();
        _apiKey = configuration["GEMINI_API_KEY"] 
            ?? throw new InvalidOperationException("GEMINI_API_KEY not configured");
    }

    public async Task<string> GenerateSummaryImageAsync(
        string userId,
        DateTime startDate,
        DateTime endDate,
        string periodType)
    {
        // Fetch photos from the period (take up to 10 for analysis)
        // Use MemoryDate if available, otherwise CreatedAt
        var photos = await _context.Memories
            .Where(m => m.UserId == userId &&
                       m.Type == "photo" &&
                       m.FileUrl != null)
            .Select(m => new { m.FileUrl, m.CreatedAt, m.MemoryDate, m.Title, m.Description })
            .ToListAsync();

        // Filter by MemoryDate or CreatedAt
        var filteredPhotos = photos
            .Where(m => {
                var date = m.MemoryDate ?? m.CreatedAt;
                return date >= startDate && date < endDate;
            })
            .OrderByDescending(m => m.MemoryDate ?? m.CreatedAt)
            .Take(10)
            .ToList();

        if (filteredPhotos.Count == 0)
        {
            throw new InvalidOperationException("Bu dönem için fotoğraf bulunamadı");
        }

        _logger.LogInformation("Found {Count} photos for summary generation", filteredPhotos.Count);

        // Convert images to base64
        var imageDataList = new List<string>();
        foreach (var photo in filteredPhotos.Take(5)) // Limit to 5 images for API
        {
            var imageBytes = await DownloadImageAsync(photo.FileUrl);
            if (imageBytes != null)
            {
                var base64 = Convert.ToBase64String(imageBytes);
                imageDataList.Add(base64);
            }
        }

        if (imageDataList.Count == 0)
        {
            throw new InvalidOperationException("Fotoğraflar yüklenemedi");
        }

        // Generate summary text using Gemini
        var summaryText = await GenerateTextSummaryAsync(imageDataList, periodType, startDate, endDate);

        // Generate a new image using Gemini Nano Banana
        var generatedImageBytes = await GenerateImageWithGeminiAsync(imageDataList, summaryText, periodType);

        // Save the generated image
        var filename = await SaveGeneratedImageAsync(generatedImageBytes, periodType, userId, startDate);

        return filename;
    }

    private async Task<string> GenerateTextSummaryAsync(
        List<string> base64Images,
        string periodType,
        DateTime startDate,
        DateTime endDate)
    {
        try
        {
            var periodText = periodType switch
            {
                "weekly" => $"{startDate:dd MMMM} - {endDate:dd MMMM yyyy} haftası",
                "monthly" => $"{startDate:MMMM yyyy} ayı",
                _ => $"{startDate:yyyy} yılı"
            };

            // Prepare the request for Gemini API
            var parts = new List<object>();
            
            // Add text prompt
            parts.Add(new
            {
                text = $@"Bu görseller {periodText} için kullanıcının anılarından. 
Lütfen bu görselleri analiz ederek SADECE 2-3 cümlelik Türkçe bir özet oluştur. 
Özet nostaljik, duygusal ve kişisel olmalı. 
Örnekler: 
- 'Renkli anılarla dolu bir hafta geçirdiniz. Güzel manzaralar ve özel anlar.'
- 'Bu ay sevdiklerinizle güzel zamanlar geçirdiniz. Mutluluk dolu anlar.'
Sadece özet metnini ver, başka bir şey ekleme."
            });

            // Add images (up to 3 for better performance)
            foreach (var base64Image in base64Images.Take(3))
            {
                parts.Add(new
                {
                    inline_data = new
                    {
                        mime_type = "image/jpeg",
                        data = base64Image
                    }
                });
            }

            var requestBody = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = parts.ToArray()
                    }
                }
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(
                $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={_apiKey}",
                content);

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogError("Gemini API error: {Error}", errorContent);
                return "Anılarınızdan güzel bir özet oluşturduk.";
            }

            var responseJson = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<JsonElement>(responseJson);

            if (result.TryGetProperty("candidates", out var candidates) &&
                candidates.GetArrayLength() > 0 &&
                candidates[0].TryGetProperty("content", out var contentProp) &&
                contentProp.TryGetProperty("parts", out var partsProp) &&
                partsProp.GetArrayLength() > 0 &&
                partsProp[0].TryGetProperty("text", out var textProp))
            {
                var summary = textProp.GetString()?.Trim() ?? "Anılarınızdan güzel bir özet oluşturduk.";
                _logger.LogInformation("Generated summary: {Summary}", summary);
                return summary;
            }

            return "Anılarınızdan güzel bir özet oluşturduk.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating text summary with Gemini");
            return "Anılarınızdan güzel bir özet oluşturduk.";
        }
    }

    private async Task<byte[]> GenerateImageWithGeminiAsync(
        List<string> base64Images,
        string summaryText,
        string periodType)
    {
        try
        {
            var periodText = periodType switch
            {
                "weekly" => "haftalık",
                "monthly" => "aylık",
                _ => "yıllık"
            };

            // Prepare the request for Gemini Image Generation
            var parts = new List<object>();
            
            // Add the prompt for image generation
            parts.Add(new
            {
                text = $@"Bu görsellere dayalı olarak tek bir artistik ve yaratıcı kompozisyon oluştur.

Kullanıcının {periodText} anılarından bu fotoğraflar var. Özet: {summaryText}

Bu fotoğraflardan ilham alarak:
- Tamamen yeni, birleştirilmiş, sanatsal bir görsel oluştur
- Orijinal fotoğrafların ruhunu ve duygusunu yansıt
- Nostaljik ve duygusal bir atmosfer oluştur
- Profesyonel ve estetik bir kompozisyon yap
- Renkler canlı ve uyumlu olsun
- Minimalist ve modern bir stil kullan

NOT: Grid veya kolaj yapma, tamamen yeni bir görsel üret!"
            });

            // Add reference images (up to 3)
            foreach (var base64Image in base64Images.Take(3))
            {
                parts.Add(new
                {
                    inline_data = new
                    {
                        mime_type = "image/jpeg",
                        data = base64Image
                    }
                });
            }

            var requestBody = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = parts.ToArray()
                    }
                },
                generationConfig = new
                {
                    response_modalities = new[] { "IMAGE" }
                }
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(
                $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={_apiKey}",
                content);

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogError("Gemini Image API error: {Error}", errorContent);
                throw new InvalidOperationException("Görsel oluşturulamadı");
            }

            var responseJson = await response.Content.ReadAsStringAsync();
            _logger.LogInformation("Gemini Image API Response received");
            
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            var result = JsonSerializer.Deserialize<JsonElement>(responseJson, options);

            // Extract the generated image
            if (result.TryGetProperty("candidates", out var candidates) &&
                candidates.GetArrayLength() > 0 &&
                candidates[0].TryGetProperty("content", out var contentProp) &&
                contentProp.TryGetProperty("parts", out var partsProp) &&
                partsProp.GetArrayLength() > 0)
            {
                foreach (var part in partsProp.EnumerateArray())
                {
                    // Try both inline_data and inlineData
                    if ((part.TryGetProperty("inline_data", out var inlineData) || 
                         part.TryGetProperty("inlineData", out inlineData)) &&
                        inlineData.TryGetProperty("data", out var imageData))
                    {
                        var base64Data = imageData.GetString();
                        if (!string.IsNullOrEmpty(base64Data))
                        {
                            _logger.LogInformation("Successfully generated image with Gemini Nano Banana");
                            return Convert.FromBase64String(base64Data);
                        }
                    }
                }
            }

            _logger.LogError("Could not find image in response");
            throw new InvalidOperationException("Görsel yanıtta bulunamadı");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating image with Gemini");
            throw;
        }
    }

    private async Task<string> SaveGeneratedImageAsync(
        byte[] imageBytes,
        string periodType,
        string userId,
        DateTime startDate)
    {
        var summariesDir = Path.Combine(_env.WebRootPath, "summaries");
        Directory.CreateDirectory(summariesDir);

        var filename = $"{periodType}_{userId}_{startDate:yyyyMMdd}_{Guid.NewGuid():N}.jpg";
        var filepath = Path.Combine(summariesDir, filename);

        await File.WriteAllBytesAsync(filepath, imageBytes);

        _logger.LogInformation("Saved generated image to {FilePath}", filepath);

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
