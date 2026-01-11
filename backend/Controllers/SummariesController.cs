using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DigiMem.Services;
using System.Security.Claims;

namespace DigiMem.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SummariesController : ControllerBase
{
    private readonly ICollageService _collageService;
    private readonly IGeminiService _geminiService;
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<SummariesController> _logger;

    public SummariesController(
        ICollageService collageService,
        IGeminiService geminiService,
        IWebHostEnvironment env,
        ILogger<SummariesController> logger)
    {
        _collageService = collageService;
        _geminiService = geminiService;
        _env = env;
        _logger = logger;
    }

    private string GetUserId()
    {
        return User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new UnauthorizedAccessException();
    }

    // GET: api/summaries/weeks?year=2025&month=12
    [HttpGet("weeks")]
    public async Task<ActionResult<List<WeekInfo>>> GetAvailableWeeks(
        [FromQuery] int year,
        [FromQuery] int month)
    {
        try
        {
            var userId = GetUserId();
            var weeks = await _collageService.GetAvailableWeeksAsync(userId, year, month);
            return Ok(weeks);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting available weeks");
            return StatusCode(500, new { error = "Failed to get available weeks" });
        }
    }

    // POST: api/summaries/collage/weekly
    [HttpPost("collage/weekly")]
    public async Task<ActionResult<object>> GenerateWeeklyCollage([FromBody] WeeklyCollageRequest request)
    {
        try
        {
            var userId = GetUserId();
            var weekEnd = request.WeekStart.AddDays(7);
            var filename = await _geminiService.GenerateSummaryImageAsync(userId, request.WeekStart, weekEnd, "weekly");
            
            return Ok(new
            {
                filename,
                url = $"/summaries/{filename}",
                downloadUrl = $"/api/summaries/download/{filename}"
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating weekly summary");
            return StatusCode(500, new { error = "Failed to generate summary" });
        }
    }

    // POST: api/summaries/collage/monthly
    [HttpPost("collage/monthly")]
    public async Task<ActionResult<object>> GenerateMonthlyCollage([FromBody] MonthlyCollageRequest request)
    {
        try
        {
            var userId = GetUserId();
            var monthStart = new DateTime(request.Year, request.Month, 1);
            var monthEnd = monthStart.AddMonths(1);
            var filename = await _geminiService.GenerateSummaryImageAsync(userId, monthStart, monthEnd, "monthly");
            
            return Ok(new
            {
                filename,
                url = $"/summaries/{filename}",
                downloadUrl = $"/api/summaries/download/{filename}"
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating monthly summary");
            return StatusCode(500, new { error = "Failed to generate summary" });
        }
    }

    // POST: api/summaries/collage/yearly
    [HttpPost("collage/yearly")]
    public async Task<ActionResult<object>> GenerateYearlyCollage([FromBody] YearlyCollageRequest request)
    {
        try
        {
            var userId = GetUserId();
            var filename = await _collageService.GenerateYearlyCollageAsync(userId, request.Year);
            
            return Ok(new
            {
                filename,
                url = $"/collages/{filename}",
                downloadUrl = $"/api/summaries/download/{filename}"
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating yearly collage");
            return StatusCode(500, new { error = "Failed to generate collage" });
        }
    }

    // GET: api/summaries/download/{filename}
    [HttpGet("download/{filename}")]
    public IActionResult DownloadCollage(string filename)
    {
        try
        {
            // Try summaries folder first, then collages folder for backward compatibility
            var summariesPath = Path.Combine(_env.WebRootPath, "summaries", filename);
            var collagesPath = Path.Combine(_env.WebRootPath, "collages", filename);
            
            string filepath;
            if (System.IO.File.Exists(summariesPath))
            {
                filepath = summariesPath;
            }
            else if (System.IO.File.Exists(collagesPath))
            {
                filepath = collagesPath;
            }
            else
            {
                return NotFound(new { error = "Summary not found" });
            }

            var bytes = System.IO.File.ReadAllBytes(filepath);
            return File(bytes, "image/jpeg", filename);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error downloading summary");
            return StatusCode(500, new { error = "Failed to download summary" });
        }
    }
}

public record WeeklyCollageRequest(DateTime WeekStart);
public record MonthlyCollageRequest(int Year, int Month);
public record YearlyCollageRequest(int Year);
