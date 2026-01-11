using DigiMem.Data;

namespace DigiMem.Models;

public class Memory
{
    public int Id { get; set; }
    public required string Type { get; set; } // "photo", "video", "voice", "text", "song"
    public string? Title { get; set; }
    public string? Description { get; set; }
    public DateTime? MemoryDate { get; set; } // User-selected date for the memory
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public List<string>? Tags { get; set; }
    
    // Media files
    public string? FileUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string? MimeType { get; set; }
    public long? FileSize { get; set; }
    
    // Voice recording specific
    public int? DurationSeconds { get; set; }
    public string? TranscriptionText { get; set; }
    
    // Song specific (Spotify)
    public string? SpotifyTrackId { get; set; }
    public string? SongTitle { get; set; }
    public string? ArtistName { get; set; }
    public string? AlbumName { get; set; }
    public string? AlbumArtUrl { get; set; }
    
    // Foreign key
    public required string UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;
}
