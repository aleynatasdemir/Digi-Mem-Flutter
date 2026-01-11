using SpotifyAPI.Web;
using Polly;
using Polly.Retry;

namespace DigiMem.Services.Spotify;

public interface ISpotifyApiService
{
    Task<List<RecentlyPlayedTrack>?> GetRecentlyPlayedAsync(string accessToken, int limit = 50);
    Task<List<FullTrack>?> GetTopTracksAsync(string accessToken, string timeRange = "short_term", int limit = 20);
    Task<FullTrack?> GetCurrentlyPlayingAsync(string accessToken);
}

public class SpotifyApiService : ISpotifyApiService
{
    private readonly ILogger<SpotifyApiService> _logger;
    private readonly AsyncRetryPolicy _retryPolicy;

    public SpotifyApiService(ILogger<SpotifyApiService> logger)
    {
        _logger = logger;
        
        // Retry policy for 429 and transient errors
        _retryPolicy = Policy
            .Handle<APIException>(ex => ex.Response?.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: (retryAttempt, exception, context) =>
                {
                    if (exception is APIException apiEx && 
                        apiEx.Response?.Headers != null)
                    {
                        if (apiEx.Response.Headers.ContainsKey("Retry-After"))
                        {
                            var retryAfterValue = apiEx.Response.Headers["Retry-After"];
                            if (int.TryParse(retryAfterValue, out var retryAfter))
                            {
                                return TimeSpan.FromSeconds(retryAfter);
                            }
                        }
                    }
                    return TimeSpan.FromSeconds(Math.Pow(2, retryAttempt));
                },
                onRetryAsync: (exception, timespan, retryCount, context) =>
                {
                    logger.LogWarning("Retrying Spotify API call. Attempt {RetryCount}. Waiting {Timespan}s", 
                        retryCount, timespan.TotalSeconds);
                    return Task.CompletedTask;
                }
            );
    }

    public async Task<List<RecentlyPlayedTrack>?> GetRecentlyPlayedAsync(string accessToken, int limit = 50)
    {
        try
        {
            return await _retryPolicy.ExecuteAsync(async () =>
            {
                var spotify = new SpotifyClient(accessToken);
                var response = await spotify.Player.GetRecentlyPlayed(new PlayerRecentlyPlayedRequest
                {
                    Limit = limit
                });

                _logger.LogInformation("Retrieved {Count} recently played tracks from Spotify", response.Items?.Count ?? 0);
                return response.Items?.Select(x => new RecentlyPlayedTrack
                {
                    Track = x.Track,
                    PlayedAt = x.PlayedAt
                }).ToList();
            });
        }
        catch (APIUnauthorizedException)
        {
            _logger.LogWarning("Spotify API returned 401 Unauthorized");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get recently played tracks");
            return null;
        }
    }

    public async Task<List<FullTrack>?> GetTopTracksAsync(string accessToken, string timeRange = "short_term", int limit = 20)
    {
        try
        {
            return await _retryPolicy.ExecuteAsync(async () =>
            {
                var spotify = new SpotifyClient(accessToken);
                var response = await spotify.Personalization.GetTopTracks(new PersonalizationTopRequest
                {
                    TimeRangeParam = timeRange switch
                    {
                        "short_term" => PersonalizationTopRequest.TimeRange.ShortTerm,
                        "medium_term" => PersonalizationTopRequest.TimeRange.MediumTerm,
                        "long_term" => PersonalizationTopRequest.TimeRange.LongTerm,
                        _ => PersonalizationTopRequest.TimeRange.ShortTerm
                    },
                    Limit = limit
                });

                _logger.LogInformation("Retrieved {Count} top tracks from Spotify", response.Items?.Count ?? 0);
                return response.Items?.ToList();
            });
        }
        catch (APIUnauthorizedException)
        {
            _logger.LogWarning("Spotify API returned 401 Unauthorized");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get top tracks");
            return null;
        }
    }

    public async Task<FullTrack?> GetCurrentlyPlayingAsync(string accessToken)
    {
        try
        {
            var spotify = new SpotifyClient(accessToken);
            var response = await spotify.Player.GetCurrentlyPlaying(new PlayerCurrentlyPlayingRequest());
            
            return response?.Item as FullTrack;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get currently playing track");
            return null;
        }
    }
}

public class RecentlyPlayedTrack
{
    public FullTrack Track { get; set; } = null!;
    public DateTime PlayedAt { get; set; }
}
