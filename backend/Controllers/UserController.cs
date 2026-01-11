using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using DigiMem.Data;
using System.Security.Claims;

namespace DigiMem.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UserController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ILogger<UserController> _logger;
    private readonly IWebHostEnvironment _env;

    public UserController(UserManager<ApplicationUser> userManager, ILogger<UserController> logger, IWebHostEnvironment env)
    {
        _userManager = userManager;
        _logger = logger;
        _env = env;
    }

    private string GetUserId()
    {
        return User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new UnauthorizedAccessException();
    }

    // GET: api/user/profile
    [HttpGet("profile")]
    public async Task<ActionResult<object>> GetProfile()
    {
        try
        {
            var userId = GetUserId();
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
            {
                return NotFound(new { error = "User not found" });
            }

            _logger.LogInformation("GetProfile for user {UserId}, ProfilePhotoUrl: {PhotoUrl}", userId, user.ProfilePhotoUrl ?? "null");

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                userName = user.UserName,
                profilePhotoUrl = user.ProfilePhotoUrl,
                emailConfirmed = user.EmailConfirmed,
                memberSince = user.CreatedAt
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get user profile");
            return StatusCode(500, new { error = "Failed to get user profile" });
        }
    }

    // POST: api/user/profile-photo
    [HttpPost("profile-photo")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<object>> UploadProfilePhoto(IFormFile file)
    {
        try
        {
            var userId = GetUserId();
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
            {
                return NotFound(new { error = "User not found" });
            }

            if (file == null || file.Length == 0)
            {
                return BadRequest(new { error = "Dosya seçilmedi." });
            }

            // Validate file type
            var allowedTypes = new[] { "image/jpeg", "image/png", "image/gif", "image/webp" };
            if (!allowedTypes.Contains(file.ContentType.ToLower()))
            {
                return BadRequest(new { error = "Sadece resim dosyaları yüklenebilir." });
            }

            // Validate file size (max 5MB)
            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest(new { error = "Dosya boyutu 5MB'dan küçük olmalıdır." });
            }

            // Create upload directory
            var uploadPath = Path.Combine(_env.WebRootPath, "uploads", "profiles", userId);
            Directory.CreateDirectory(uploadPath);

            // Delete old profile photo if exists
            if (!string.IsNullOrEmpty(user.ProfilePhotoUrl))
            {
                var oldPhotoPath = Path.Combine(_env.WebRootPath, user.ProfilePhotoUrl.TrimStart('/'));
                if (System.IO.File.Exists(oldPhotoPath))
                {
                    System.IO.File.Delete(oldPhotoPath);
                }
            }

            // Save new photo
            var fileName = $"profile_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Update user profile photo URL
            user.ProfilePhotoUrl = $"/uploads/profiles/{userId}/{fileName}";
            var updateResult = await _userManager.UpdateAsync(user);

            _logger.LogInformation("Profile photo uploaded for user {UserId}, PhotoUrl: {PhotoUrl}, UpdateSuccess: {Success}", 
                userId, user.ProfilePhotoUrl, updateResult.Succeeded);

            return Ok(new
            {
                profilePhotoUrl = user.ProfilePhotoUrl,
                message = "Profil fotoğrafı güncellendi."
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to upload profile photo");
            return StatusCode(500, new { error = "Failed to upload profile photo" });
        }
    }

    // DELETE: api/user/profile-photo
    [HttpDelete("profile-photo")]
    public async Task<IActionResult> DeleteProfilePhoto()
    {
        try
        {
            var userId = GetUserId();
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
            {
                return NotFound(new { error = "User not found" });
            }

            if (string.IsNullOrEmpty(user.ProfilePhotoUrl))
            {
                return BadRequest(new { error = "Profil fotoğrafı bulunamadı." });
            }

            // Delete photo file
            var photoPath = Path.Combine(_env.WebRootPath, user.ProfilePhotoUrl.TrimStart('/'));
            if (System.IO.File.Exists(photoPath))
            {
                System.IO.File.Delete(photoPath);
            }

            // Update user
            user.ProfilePhotoUrl = null;
            await _userManager.UpdateAsync(user);

            _logger.LogInformation("Profile photo deleted for user {UserId}", userId);

            return Ok(new { message = "Profil fotoğrafı silindi." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete profile photo");
            return StatusCode(500, new { error = "Failed to delete profile photo" });
        }
    }

    // PUT: api/user/profile
    [HttpPut("profile")]
    public async Task<ActionResult<object>> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        try
        {
            var userId = GetUserId();
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
            {
                return NotFound(new { error = "User not found" });
            }

            // Update username if provided and different
            if (!string.IsNullOrWhiteSpace(request.UserName) && request.UserName != user.UserName)
            {
                var setUsernameResult = await _userManager.SetUserNameAsync(user, request.UserName);
                if (!setUsernameResult.Succeeded)
                {
                    return BadRequest(new { errors = setUsernameResult.Errors.Select(e => e.Description) });
                }
            }

            // Update email if provided and different
            if (!string.IsNullOrWhiteSpace(request.Email) && request.Email != user.Email)
            {
                var setEmailResult = await _userManager.SetEmailAsync(user, request.Email);
                if (!setEmailResult.Succeeded)
                {
                    return BadRequest(new { errors = setEmailResult.Errors.Select(e => e.Description) });
                }
            }

            _logger.LogInformation("Profile updated for user {UserId}", userId);

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                userName = user.UserName,
                emailConfirmed = user.EmailConfirmed,
                memberSince = user.CreatedAt
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update user profile");
            return StatusCode(500, new { error = "Failed to update user profile" });
        }
    }

    // PUT: api/user/password
    [HttpPut("password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        try
        {
            var userId = GetUserId();
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
            {
                return NotFound(new { error = "User not found" });
            }

            var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);

            if (!result.Succeeded)
            {
                return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
            }

            _logger.LogInformation("Password changed for user {UserId}", userId);

            return Ok(new { message = "Password changed successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to change password");
            return StatusCode(500, new { error = "Failed to change password" });
        }
    }
}

public record UpdateProfileRequest(
    string? UserName,
    string? Email
);

public record ChangePasswordRequest(
    string CurrentPassword,
    string NewPassword
);
