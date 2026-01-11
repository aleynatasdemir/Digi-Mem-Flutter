using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DigiMem.Data;
using DigiMem.Models;
using System.Security.Claims;

namespace DigiMem.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MemoriesController : ControllerBase
{
    private readonly AppDbContext _context;

    public MemoriesController(AppDbContext context)
    {
        _context = context;
    }

    private string GetUserId()
    {
        return User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new UnauthorizedAccessException();
    }

    // GET: api/memories
    [HttpGet]
    public async Task<ActionResult<object>> GetMemories(
        [FromQuery] string? view = null,
        [FromQuery] string? from = null,
        [FromQuery] string? to = null,
        [FromQuery] string? types = null,
        [FromQuery] string? tags = null,
        [FromQuery] string? q = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = GetUserId();
        var query = _context.Memories.Where(m => m.UserId == userId);

        // Filter by date range
        if (!string.IsNullOrEmpty(from) && DateTime.TryParse(from, out var fromDate))
        {
            query = query.Where(m => m.CreatedAt >= fromDate);
        }

        if (!string.IsNullOrEmpty(to) && DateTime.TryParse(to, out var toDate))
        {
            query = query.Where(m => m.CreatedAt <= toDate);
        }

        // Filter by types
        if (!string.IsNullOrEmpty(types))
        {
            var typeList = types.Split(',').Select(t => t.Trim()).ToList();
            query = query.Where(m => typeList.Contains(m.Type));
        }

        // Search query
        if (!string.IsNullOrEmpty(q))
        {
            query = query.Where(m => 
                (m.Title != null && m.Title.Contains(q)) || 
                (m.Description != null && m.Description.Contains(q)));
        }

        var total = await query.CountAsync();
        var memories = await query
            .OrderByDescending(m => m.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Ok(new
        {
            items = memories,
            total,
            page,
            pageSize,
            totalPages = (int)Math.Ceiling((double)total / pageSize)
        });
    }

    // GET: api/memories/{id}
    [HttpGet("{id:int}")]
    public async Task<ActionResult<Memory>> GetMemory(int id)
    {
        var userId = GetUserId();
        var memory = await _context.Memories
            .FirstOrDefaultAsync(m => m.Id == id && m.UserId == userId);

        if (memory == null)
        {
            return NotFound();
        }

        return Ok(memory);
    }

    // POST: api/memories
    [HttpPost]
    public async Task<ActionResult<Memory>> CreateMemory([FromBody] CreateMemoryRequest request)
    {
        var userId = GetUserId();

        var memory = new Memory
        {
            Type = request.Type,
            Title = request.Title,
            Description = request.Description,
            MemoryDate = request.Date,
            Tags = request.Tags,
            FileUrl = request.FileUrl,
            ThumbnailUrl = request.ThumbnailUrl,
            MimeType = request.MimeType,
            FileSize = request.FileSize,
            DurationSeconds = request.DurationSeconds,
            TranscriptionText = request.TranscriptionText,
            SpotifyTrackId = request.SpotifyTrackId,
            SongTitle = request.SongTitle,
            ArtistName = request.ArtistName,
            AlbumName = request.AlbumName,
            AlbumArtUrl = request.AlbumArtUrl,
            UserId = userId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Memories.Add(memory);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetMemory), new { id = memory.Id }, memory);
    }

    // PUT: api/memories/{id}
    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdateMemory(int id, [FromBody] UpdateMemoryRequest request)
    {
        var userId = GetUserId();
        var memory = await _context.Memories
            .FirstOrDefaultAsync(m => m.Id == id && m.UserId == userId);

        if (memory == null)
        {
            return NotFound();
        }

        memory.Title = request.Title;
        memory.Description = request.Description;
        memory.Tags = request.Tags;
        memory.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(memory);
    }

    // DELETE: api/memories/{id}
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteMemory(int id)
    {
        var userId = GetUserId();
        var memory = await _context.Memories
            .FirstOrDefaultAsync(m => m.Id == id && m.UserId == userId);

        if (memory == null)
        {
            return NotFound();
        }

        _context.Memories.Remove(memory);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // GET: api/memories/stats
    [HttpGet("stats")]
    public async Task<ActionResult<object>> GetStats([FromQuery] string? period = "all")
    {
        var userId = GetUserId();
        var now = DateTime.UtcNow;

        // Calculate date ranges - use MemoryDate instead of CreatedAt
        // Start of week is Monday (Turkish standard)
        var dayOfWeek = (int)now.DayOfWeek;
        var daysFromMonday = (dayOfWeek == 0 ? 6 : dayOfWeek - 1); // Sunday=6, Monday=0, Tuesday=1, etc.
        var startOfWeek = now.AddDays(-daysFromMonday).Date;
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var query = _context.Memories.Where(m => m.UserId == userId);

        // Total counts
        var totalMemories = await query.CountAsync();
        var weekMemories = await query.CountAsync(m => m.MemoryDate != null && m.MemoryDate >= startOfWeek);
        var monthMemories = await query.CountAsync(m => m.MemoryDate != null && m.MemoryDate >= startOfMonth);

        // Format distribution (by type)
        var byTypeQuery = await query.GroupBy(m => m.Type).ToListAsync();
        
        var byType = new Dictionary<string, int>
        {
            ["photo"] = byTypeQuery.FirstOrDefault(g => g.Key == "photo")?.Count() ?? 0,
            ["video"] = byTypeQuery.FirstOrDefault(g => g.Key == "video")?.Count() ?? 0,
            ["audio"] = byTypeQuery.FirstOrDefault(g => g.Key == "audio")?.Count() ?? 0,
            ["text"] = byTypeQuery.FirstOrDefault(g => g.Key == "text")?.Count() ?? 0,
            ["music"] = byTypeQuery.FirstOrDefault(g => g.Key == "music")?.Count() ?? 0
        };

        return Ok(new
        {
            total = totalMemories,
            totalMemories = totalMemories, // Backward compatibility
            thisWeek = weekMemories,
            thisMonth = monthMemories,
            byType
        });
    }

    // GET: api/memories/stats/weekly
    [HttpGet("stats/weekly")]
    public async Task<ActionResult<object>> GetWeeklyStats()
    {
        var userId = GetUserId();
        var now = DateTime.UtcNow;
        
        // Start of week is Monday (Turkish standard)
        var dayOfWeek = (int)now.DayOfWeek;
        var daysFromMonday = (dayOfWeek == 0 ? 6 : dayOfWeek - 1);
        var startOfWeek = now.AddDays(-daysFromMonday).Date;

        var weeklyData = new List<object>();
        var dayNames = new[] { "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz" };

        for (int i = 0; i < 7; i++)
        {
            var dayStart = startOfWeek.AddDays(i);
            var dayEnd = dayStart.AddDays(1);
            
            var count = await _context.Memories
                .Where(m => m.UserId == userId && m.MemoryDate != null && m.MemoryDate >= dayStart && m.MemoryDate < dayEnd)
                .CountAsync();

            weeklyData.Add(new
            {
                day = dayNames[i],
                uploads = count
            });
        }

        return Ok(weeklyData);
    }

    // GET: api/memories/stats/monthly
    [HttpGet("stats/monthly")]
    public async Task<ActionResult<object>> GetMonthlyStats()
    {
        var userId = GetUserId();
        var now = DateTime.UtcNow;
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var monthlyData = new List<object>();

        for (int weekNum = 1; weekNum <= 4; weekNum++)
        {
            var weekStart = startOfMonth.AddDays((weekNum - 1) * 7);
            var weekEnd = weekStart.AddDays(7);
            
            var count = await _context.Memories
                .Where(m => m.UserId == userId && m.MemoryDate != null && m.MemoryDate >= weekStart && m.MemoryDate < weekEnd)
                .CountAsync();

            monthlyData.Add(new
            {
                week = $"{weekNum}. Hafta",
                uploads = count
            });
        }

        return Ok(monthlyData);
    }
}

public record CreateMemoryRequest(
    string Type,
    string? Title,
    string? Description,
    DateTime? Date,
    List<string>? Tags,
    string? FileUrl,
    string? ThumbnailUrl,
    string? MimeType,
    long? FileSize,
    int? DurationSeconds,
    string? TranscriptionText,
    string? SpotifyTrackId,
    string? SongTitle,
    string? ArtistName,
    string? AlbumName,
    string? AlbumArtUrl
);

public record UpdateMemoryRequest(
    string? Title,
    string? Description,
    List<string>? Tags
);
