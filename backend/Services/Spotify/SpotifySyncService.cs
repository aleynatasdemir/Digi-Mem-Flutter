using Microsoft.EntityFrameworkCore;
using DigiMem.Data;
using DigiMem.Models;
using SpotifyAPI.Web;

namespace DigiMem.Services.Spotify;

public interface ISpotifySyncService
{
    Task<SyncResult> SyncRecentlyPlayedAsync(string userId, string accessToken);
    Task<List<SpotifyTrack>> GetUserTopTracksAsync(string userId, int limit = 20);
}

public class SpotifySyncService : ISpotifySyncService
{
    private readonly AppDbContext _context;
    private readonly ISpotifyApiService _spotifyApi;
    private readonly ILogger<SpotifySyncService> _logger;

    public SpotifySyncService(
        AppDbContext context,
        ISpotifyApiService spotifyApi,
        ILogger<SpotifySyncService> logger)
    {
        _context = context;
        _spotifyApi = spotifyApi;
        _logger = logger;
    }

    public async Task<SyncResult> SyncRecentlyPlayedAsync(string userId, string accessToken)
    {
        try
        {
            _logger.LogInformation("Starting Spotify sync for user {UserId}", userId);

            var recentTracks = await _spotifyApi.GetRecentlyPlayedAsync(accessToken);
            if (recentTracks == null || !recentTracks.Any())
            {
                _logger.LogWarning("No tracks retrieved from Spotify for user {UserId}", userId);
                return new SyncResult { Success = false, Message = "No tracks found" };
            }

            var newTracksCount = 0;
            var existingTrackIds = await _context.SpotifyTracks
                .Where(st => st.UserId == userId)
                .Select(st => st.SpotifyTrackId)
                .ToListAsync();

            foreach (var item in recentTracks)
            {
                var trackId = item.Track.Id;
                
                // Skip if already exists with same played_at time
                var exists = await _context.SpotifyTracks
                    .AnyAsync(st => st.UserId == userId && 
                                   st.SpotifyTrackId == trackId && 
                                   st.PlayedAt == item.PlayedAt);

                if (exists)
                    continue;

                var spotifyTrack = new SpotifyTrack
                {
                    UserId = userId,
                    SpotifyTrackId = trackId,
                    TrackName = item.Track.Name,
                    ArtistName = string.Join(", ", item.Track.Artists.Select(a => a.Name)),
                    AlbumName = item.Track.Album?.Name,
                    AlbumArtUrl = item.Track.Album?.Images?.FirstOrDefault()?.Url,
                    SpotifyUri = item.Track.Uri,
                    PlayedAt = item.PlayedAt,
                    CreatedAt = DateTime.UtcNow
                };

                _context.SpotifyTracks.Add(spotifyTrack);
                newTracksCount++;
            }

            if (newTracksCount > 0)
            {
                await _context.SaveChangesAsync();
            }

            // Update last synced time
            var integration = await _context.UserIntegrations
                .FirstOrDefaultAsync(ui => ui.UserId == userId && ui.Provider == "Spotify");

            if (integration != null)
            {
                integration.LastSyncedAt = DateTime.UtcNow;
                integration.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            _logger.LogInformation("Spotify sync completed for user {UserId}. Added {Count} new tracks", 
                userId, newTracksCount);

            return new SyncResult
            {
                Success = true,
                TracksAdded = newTracksCount,
                Message = $"Synced {newTracksCount} new tracks"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to sync Spotify data for user {UserId}", userId);
            return new SyncResult
            {
                Success = false,
                Message = $"Sync failed: {ex.Message}"
            };
        }
    }

    public async Task<List<SpotifyTrack>> GetUserTopTracksAsync(string userId, int limit = 20)
    {
        return await _context.SpotifyTracks
            .Where(st => st.UserId == userId)
            .OrderByDescending(st => st.PlayedAt)
            .Take(limit)
            .ToListAsync();
    }
}

public class SyncResult
{
    public bool Success { get; set; }
    public int TracksAdded { get; set; }
    public string? Message { get; set; }
}
