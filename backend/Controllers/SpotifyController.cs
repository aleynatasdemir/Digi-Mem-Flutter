using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DigiMem.Data;
using DigiMem.Services;
using DigiMem.Services.Spotify;
using System.Security.Claims;

namespace DigiMem.Controllers;

[ApiController]
[Route("api/spotify")]
[Authorize]
public class SpotifyController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IEncryptionService _encryption;
    private readonly ISpotifyOAuthService _spotifyOAuth;
    private readonly ISpotifySyncService _spotifySync;
    private readonly ISpotifyApiService _spotifyApi;
    private readonly ILogger<SpotifyController> _logger;

    public SpotifyController(
        AppDbContext context,
        IEncryptionService encryption,
        ISpotifyOAuthService spotifyOAuth,
        ISpotifySyncService spotifySync,
        ISpotifyApiService spotifyApi,
        ILogger<SpotifyController> logger)
    {
        _context = context;
        _encryption = encryption;
        _spotifyOAuth = spotifyOAuth;
        _spotifySync = spotifySync;
        _spotifyApi = spotifyApi;
        _logger = logger;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier) 
        ?? throw new UnauthorizedAccessException();

    // GET: api/spotify/status
    [HttpGet("status")]
    public async Task<ActionResult> GetStatus()
    {
        try
        {
            var userId = GetUserId();
            var integration = await _context.UserIntegrations
                .FirstOrDefaultAsync(ui => ui.UserId == userId && ui.Provider == "Spotify");

            return Ok(new
            {
                connected = integration?.IsActive ?? false,
                lastSyncedAt = integration?.LastSyncedAt,
                scopes = integration?.Scopes
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get Spotify status");
            return StatusCode(500, new { error = "Failed to get Spotify status" });
        }
    }

    // POST: api/spotify/sync
    [HttpPost("sync")]
    public async Task<ActionResult> Sync()
    {
        try
        {
            var userId = GetUserId();
            
            _logger.LogInformation("spotify_sync_started for user {UserId}", userId);

            var integration = await _context.UserIntegrations
                .FirstOrDefaultAsync(ui => ui.UserId == userId && ui.Provider == "Spotify" && ui.IsActive);

            if (integration == null || string.IsNullOrEmpty(integration.EncryptedRefreshToken))
            {
                return BadRequest(new { error = "Spotify not connected" });
            }

            // Get access token (refresh if needed)
            var refreshToken = _encryption.Decrypt(integration.EncryptedRefreshToken);
            var accessToken = await _spotifyOAuth.RefreshAccessTokenAsync(refreshToken);

            if (string.IsNullOrEmpty(accessToken))
            {
                _logger.LogError("spotify_sync_failed: token refresh failed for user {UserId}", userId);
                return StatusCode(500, new { error = "Failed to refresh Spotify token. Please reconnect." });
            }

            // Sync recently played tracks
            var result = await _spotifySync.SyncRecentlyPlayedAsync(userId, accessToken);

            if (!result.Success)
            {
                _logger.LogError("spotify_sync_failed for user {UserId}: {Message}", userId, result.Message);
                return StatusCode(500, new { error = result.Message });
            }

            _logger.LogInformation("spotify_sync_succeeded for user {UserId}. Added {Count} tracks", 
                userId, result.TracksAdded);

            return Ok(new
            {
                success = true,
                tracksAdded = result.TracksAdded,
                message = result.Message,
                lastSyncedAt = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "spotify_sync_failed for user {UserId}", GetUserId());
            return StatusCode(500, new { error = "Sync failed. Please try again later." });
        }
    }

    // GET: api/spotify/top-tracks
    [HttpGet("top-tracks")]
    public async Task<ActionResult> GetTopTracks([FromQuery] int limit = 20)
    {
        try
        {
            var userId = GetUserId();
            var tracks = await _spotifySync.GetUserTopTracksAsync(userId, limit);

            return Ok(new
            {
                tracks = tracks.Select(t => new
                {
                    id = t.Id,
                    spotifyTrackId = t.SpotifyTrackId,
                    trackName = t.TrackName,
                    artistName = t.ArtistName,
                    albumName = t.AlbumName,
                    albumArtUrl = t.AlbumArtUrl,
                    spotifyUri = t.SpotifyUri,
                    playedAt = t.PlayedAt
                })
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get top tracks");
            return StatusCode(500, new { error = "Failed to get top tracks" });
        }
    }

    // GET: api/spotify/summary
    [HttpGet("summary")]
    public async Task<ActionResult> GetSummary()
    {
        try
        {
            var userId = GetUserId();
            
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);

            var thisMonthTracks = await _context.SpotifyTracks
                .Where(st => st.UserId == userId && st.PlayedAt >= startOfMonth)
                .ToListAsync();

            var topArtists = thisMonthTracks
                .GroupBy(st => st.ArtistName)
                .OrderByDescending(g => g.Count())
                .Take(5)
                .Select(g => new
                {
                    artist = g.Key,
                    playCount = g.Count()
                })
                .ToList();

            var topTracks = thisMonthTracks
                .GroupBy(st => new { st.SpotifyTrackId, st.TrackName, st.ArtistName, st.AlbumArtUrl })
                .OrderByDescending(g => g.Count())
                .Take(10)
                .Select(g => new
                {
                    trackId = g.Key.SpotifyTrackId,
                    trackName = g.Key.TrackName,
                    artistName = g.Key.ArtistName,
                    albumArtUrl = g.Key.AlbumArtUrl,
                    playCount = g.Count()
                })
                .ToList();

            return Ok(new
            {
                period = "Bu Ay",
                totalPlays = thisMonthTracks.Count,
                topArtists,
                topTracks
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get Spotify summary");
            return StatusCode(500, new { error = "Failed to get summary" });
        }
    }
}
