using DigiMem.Data;

namespace DigiMem.Models;

public class UserIntegration
{
    public int Id { get; set; }
    public required string UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;
    
    public required string Provider { get; set; } // "Spotify", "Apple Music", etc.
    public string? EncryptedRefreshToken { get; set; }
    public string? Scopes { get; set; }
    public DateTime? LastSyncedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
}

public class SpotifyTrack
{
    public int Id { get; set; }
    public required string UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;
    
    public required string SpotifyTrackId { get; set; }
    public required string TrackName { get; set; }
    public required string ArtistName { get; set; }
    public string? AlbumName { get; set; }
    public string? AlbumArtUrl { get; set; }
    public string? SpotifyUri { get; set; }
    public DateTime? PlayedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
