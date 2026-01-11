using SpotifyAPI.Web;
using System.Security.Cryptography;
using System.Text;

namespace DigiMem.Services.Spotify;

public interface ISpotifyOAuthService
{
    string GenerateAuthorizeUrl(string state, string codeVerifier);
    Task<(string AccessToken, string RefreshToken, int ExpiresIn)?> ExchangeCodeForTokenAsync(string code, string codeVerifier);
    Task<string?> RefreshAccessTokenAsync(string refreshToken);
    string GenerateCodeVerifier();
    string GenerateCodeChallenge(string codeVerifier);
}

public class SpotifyOAuthService : ISpotifyOAuthService
{
    private readonly IConfiguration _configuration;
    private readonly string _clientId;
    private readonly string _clientSecret;
    private readonly string _redirectUri;
    private readonly ILogger<SpotifyOAuthService> _logger;

    public SpotifyOAuthService(IConfiguration configuration, ILogger<SpotifyOAuthService> logger)
    {
        _configuration = configuration;
        _logger = logger;
        _clientId = configuration["Spotify:ClientId"] ?? throw new InvalidOperationException("Spotify ClientId not configured");
        _clientSecret = configuration["Spotify:ClientSecret"] ?? throw new InvalidOperationException("Spotify ClientSecret not configured");
        _redirectUri = configuration["Spotify:RedirectUri"] ?? throw new InvalidOperationException("Spotify RedirectUri not configured");
    }

    public string GenerateAuthorizeUrl(string state, string codeVerifier)
    {
        var codeChallenge = GenerateCodeChallenge(codeVerifier);
        
        var scopes = new[]
        {
            "user-read-recently-played",
            "user-top-read",
            "user-read-currently-playing"
        };

        var loginRequest = new LoginRequest(
            new Uri(_redirectUri),
            _clientId,
            LoginRequest.ResponseType.Code
        )
        {
            Scope = scopes,
            State = state,
            CodeChallengeMethod = "S256",
            CodeChallenge = codeChallenge
        };

        return loginRequest.ToUri().ToString();
    }

    public async Task<(string AccessToken, string RefreshToken, int ExpiresIn)?> ExchangeCodeForTokenAsync(string code, string codeVerifier)
    {
        try
        {
            var request = new PKCETokenRequest(_clientId, code, new Uri(_redirectUri), codeVerifier);
            var response = await new OAuthClient().RequestToken(request);

            _logger.LogInformation("Spotify token exchange successful");
            
            return (response.AccessToken, response.RefreshToken, response.ExpiresIn);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to exchange code for token");
            return null;
        }
    }

    public async Task<string?> RefreshAccessTokenAsync(string refreshToken)
    {
        try
        {
            var request = new PKCETokenRefreshRequest(_clientId, refreshToken);
            var response = await new OAuthClient().RequestToken(request);

            _logger.LogInformation("Spotify token refreshed successfully");
            
            return response.AccessToken;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to refresh access token");
            return null;
        }
    }

    public string GenerateCodeVerifier()
    {
        var bytes = new byte[32];
        RandomNumberGenerator.Fill(bytes);
        return Convert.ToBase64String(bytes)
            .Replace("+", "-")
            .Replace("/", "_")
            .Replace("=", "");
    }

    public string GenerateCodeChallenge(string codeVerifier)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(codeVerifier));
        return Convert.ToBase64String(bytes)
            .Replace("+", "-")
            .Replace("/", "_")
            .Replace("=", "");
    }
}
