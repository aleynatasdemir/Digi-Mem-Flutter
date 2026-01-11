using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace DigiMem.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UploadController : ControllerBase
{
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<UploadController> _logger;
    private const long MaxFileSize = 100 * 1024 * 1024; // 100MB

    public UploadController(IWebHostEnvironment environment, ILogger<UploadController> logger)
    {
        _environment = environment;
        _logger = logger;
    }

    private string GetUserId()
    {
        return User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new UnauthorizedAccessException();
    }

    // POST: api/upload
    [HttpPost]
    [RequestSizeLimit(MaxFileSize)]
    public async Task<ActionResult<object>> UploadFile(IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { error = "No file uploaded" });
            }

            if (file.Length > MaxFileSize)
            {
                return BadRequest(new { error = $"File size exceeds maximum limit of {MaxFileSize / 1024 / 1024}MB" });
            }

            var userId = GetUserId();
            var uploadPath = Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads", userId);
            
            if (!Directory.Exists(uploadPath))
            {
                Directory.CreateDirectory(uploadPath);
            }

            // Generate unique filename
            var fileExtension = Path.GetExtension(file.FileName);
            var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
            var filePath = Path.Combine(uploadPath, uniqueFileName);

            // Save file
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Generate URLs
            var fileUrl = $"/uploads/{userId}/{uniqueFileName}";
            var thumbnailUrl = fileUrl; // TODO: Generate thumbnail for images/videos

            _logger.LogInformation("File uploaded: {FileName} by user {UserId}", uniqueFileName, userId);

            return Ok(new
            {
                fileUrl,
                thumbnailUrl,
                fileName = file.FileName,
                mimeType = file.ContentType,
                fileSize = file.Length
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "File upload failed");
            return StatusCode(500, new { error = "File upload failed" });
        }
    }

    // DELETE: api/upload
    [HttpDelete]
    public async Task<IActionResult> DeleteFile([FromQuery] string fileUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(fileUrl))
            {
                return BadRequest(new { error = "File URL is required" });
            }

            var userId = GetUserId();
            
            // Extract filename from URL
            var fileName = Path.GetFileName(fileUrl);
            var filePath = Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads", userId, fileName);

            if (!System.IO.File.Exists(filePath))
            {
                return NotFound(new { error = "File not found" });
            }

            // Verify file belongs to user
            var fileDirectory = Path.GetDirectoryName(filePath);
            var userDirectory = Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads", userId);
            
            if (!fileDirectory?.StartsWith(userDirectory) ?? true)
            {
                return Forbid();
            }

            System.IO.File.Delete(filePath);
            _logger.LogInformation("File deleted: {FileName} by user {UserId}", fileName, userId);

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "File deletion failed");
            return StatusCode(500, new { error = "File deletion failed" });
        }
    }
}
