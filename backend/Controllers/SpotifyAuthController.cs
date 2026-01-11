using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DigiMem.Data;
using DigiMem.Models;
using DigiMem.Services;
using DigiMem.Services.Spotify;
using System.Security.Claims;

namespace DigiMem.Controllers;

[ApiController]
[Route("oauth/spotify")]
public class SpotifyAuthController : ControllerBase
{
    private readonly ISpotifyOAuthService _spotifyOAuth;
    private readonly AppDbContext _context;
    private readonly IEncryptionService _encryption;
    private readonly ILogger<SpotifyAuthController> _logger;
    private static readonly Dictionary<string, (string CodeVerifier, DateTime Expiry)> _stateStore = new();

    public SpotifyAuthController(
        ISpotifyOAuthService spotifyOAuth,
        AppDbContext context,
        IEncryptionService encryption,
        ILogger<SpotifyAuthController> logger)
    {
        _spotifyOAuth = spotifyOAuth;
        _context = context;
        _encryption = encryption;
        _logger = logger;
    }

    // GET: oauth/spotify/connect
    // Token can be passed via query parameter for popup-based OAuth flow
    [HttpGet("connect")]
    public async Task<IActionResult> Connect([FromQuery] string? returnUrl, [FromQuery] string? token)
    {
        try
        {
            string? userId = null;

            // First try to get userId from JWT in Authorization header
            if (User.Identity?.IsAuthenticated == true)
            {
                userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            }
            
            // If not authenticated via header, try token from query parameter
            if (string.IsNullOrEmpty(userId) && !string.IsNullOrEmpty(token))
            {
                // Validate the token and extract userId
                var tokenHandler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
                try
                {
                    var jwtSecret = HttpContext.RequestServices.GetRequiredService<IConfiguration>()["Jwt:Secret"] 
                        ?? "your-super-secret-key-min-32-characters-long!";
                    var key = System.Text.Encoding.ASCII.GetBytes(jwtSecret);
                    
                    var validationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
                    {
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(key),
                        ValidateIssuer = false,
                        ValidateAudience = false,
                        ClockSkew = TimeSpan.Zero
                    };

                    var principal = tokenHandler.ValidateToken(token, validationParameters, out _);
                    userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Invalid token provided for Spotify connect");
                }
            }

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { error = "Authentication required. Please log in first." });
            }

            var state = Guid.NewGuid().ToString();
            var codeVerifier = _spotifyOAuth.GenerateCodeVerifier();

            // Store state and code verifier temporarily (in production, use Redis/cache)
            _stateStore[state] = (codeVerifier, DateTime.UtcNow.AddMinutes(10));
            CleanupExpiredStates();

            // Store userId in state for callback
            HttpContext.Session.SetString($"spotify_state_{state}", userId);
            
            // Store return URL if provided
            if (!string.IsNullOrEmpty(returnUrl))
            {
                HttpContext.Session.SetString($"spotify_return_{state}", returnUrl);
            }

            var authorizeUrl = _spotifyOAuth.GenerateAuthorizeUrl(state, codeVerifier);

            _logger.LogInformation("spotify_connect_started for user {UserId}", userId);

            return Redirect(authorizeUrl);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "spotify_connect_failed");
            return BadRequest(new { error = "Failed to initiate Spotify connection" });
        }
    }

    // GET: oauth/spotify/callback
    [HttpGet("callback")]
    public async Task<IActionResult> Callback([FromQuery] string? code, [FromQuery] string? state, [FromQuery] string? error)
    {
        try
        {
            if (!string.IsNullOrEmpty(error))
            {
                _logger.LogWarning("Spotify authorization denied: {Error}", error);
                return Redirect($"{GetFrontendUrl()}/settings?spotify_error=access_denied");
            }

            if (string.IsNullOrEmpty(code) || string.IsNullOrEmpty(state))
            {
                return BadRequest(new { error = "Missing code or state parameter" });
            }

            // Retrieve userId from session
            var userId = HttpContext.Session.GetString($"spotify_state_{state}");
            if (string.IsNullOrEmpty(userId))
            {
                return BadRequest(new { error = "Invalid or expired state" });
            }

            // Retrieve code verifier
            if (!_stateStore.TryGetValue(state, out var stateData))
            {
                return BadRequest(new { error = "Invalid or expired state" });
            }

            var (codeVerifier, _) = stateData;
            _stateStore.Remove(state);
            HttpContext.Session.Remove($"spotify_state_{state}");

            // Exchange code for tokens
            var tokenResult = await _spotifyOAuth.ExchangeCodeForTokenAsync(code, codeVerifier);
            if (tokenResult == null)
            {
                _logger.LogError("spotify_connect_failed: token exchange failed");
                return Redirect($"{GetFrontendUrl()}/settings?spotify_error=token_exchange_failed");
            }

            var (accessToken, refreshToken, expiresIn) = tokenResult.Value;

            // Save or update integration
            var integration = await _context.UserIntegrations
                .FirstOrDefaultAsync(ui => ui.UserId == userId && ui.Provider == "Spotify");

            if (integration == null)
            {
                integration = new UserIntegration
                {
                    UserId = userId,
                    Provider = "Spotify",
                    EncryptedRefreshToken = _encryption.Encrypt(refreshToken),
                    Scopes = "user-read-recently-played,user-top-read,user-read-currently-playing",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.UserIntegrations.Add(integration);
            }
            else
            {
                integration.EncryptedRefreshToken = _encryption.Encrypt(refreshToken);
                integration.IsActive = true;
                integration.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("spotify_connect_succeeded for user {UserId}", userId);

            return Redirect($"{GetFrontendUrl()}/settings?spotify_connected=true");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "spotify_connect_failed in callback");
            return Redirect($"{GetFrontendUrl()}/settings?spotify_error=server_error");
        }
    }

    // POST: oauth/spotify/disconnect
    [HttpPost("disconnect")]
    [Authorize]
    public async Task<IActionResult> Disconnect()
    {
        try
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) 
                ?? throw new UnauthorizedAccessException();

            var integration = await _context.UserIntegrations
                .FirstOrDefaultAsync(ui => ui.UserId == userId && ui.Provider == "Spotify");

            if (integration != null)
            {
                _context.UserIntegrations.Remove(integration);
                await _context.SaveChangesAsync();
            }

            _logger.LogInformation("spotify_disconnect_clicked for user {UserId}", userId);

            return Ok(new { message = "Spotify disconnected successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to disconnect Spotify");
            return StatusCode(500, new { error = "Failed to disconnect Spotify" });
        }
    }

    private void CleanupExpiredStates()
    {
        var expiredKeys = _stateStore
            .Where(kvp => kvp.Value.Expiry < DateTime.UtcNow)
            .Select(kvp => kvp.Key)
            .ToList();

        foreach (var key in expiredKeys)
        {
            _stateStore.Remove(key);
        }
    }

    private string GetFrontendUrl()
    {
        return HttpContext.Request.Headers.Origin.FirstOrDefault() ?? "http://localhost:3000";
    }
}
