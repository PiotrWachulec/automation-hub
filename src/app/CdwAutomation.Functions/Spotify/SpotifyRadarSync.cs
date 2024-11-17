using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace CdwAutomation.Functions
{
    public class SpotifyRadarSync
    {
        private readonly ILogger _logger;
        private readonly string _clientId;
        private readonly string _clientSecret;
        private readonly string _radarPlaylistId;
        private readonly string _bachata2024PlaylistId;
        private readonly HttpClient _httpClient;

        public SpotifyRadarSync(ILoggerFactory loggerFactory, IConfiguration configuration)
        {
            _logger = loggerFactory.CreateLogger<SpotifyRadarSync>();
            _clientId = configuration["SPOTIFY_CLIENT_ID"];
            _clientSecret = configuration["SPOTIFY_CLIENT_SECRET"];
            _radarPlaylistId = configuration["SPOTIFY_RADAR_PLAYLIST_ID"];
            _bachata2024PlaylistId = configuration["SPOTIFY_BACHATA2024_PLAYLIST_ID"];
            _httpClient = new HttpClient();
        }

        [Function("SpotifyRadarSync")]
        public async Task Run([TimerTrigger("0 0 3  * * 5")] TimerInfo myTimer)
        {
            try
            {
                var token = await GetSpotifyToken();
                _logger.LogInformation("Successfully obtained Spotify access token");
                await GetPlaylist(token, _radarPlaylistId);
                await GetPlaylist(token, _bachata2024PlaylistId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SpotifyRadarSync");
            }
        }

        private async Task<string> GetSpotifyToken()
        {
            var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));

            var request = new HttpRequestMessage(HttpMethod.Post, "https://accounts.spotify.com/api/token")
            {
                Content = new FormUrlEncodedContent(new Dictionary<string, string>
                {
                    { "grant_type", "client_credentials" }
                })
            };

            request.Headers.Add("Authorization", $"Basic {auth}");

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"Failed to get Spotify token: {content}");
            }

            var tokenResponse = JsonSerializer.Deserialize<SpotifyTokenResponse>(content);
            return tokenResponse.AccessToken;
        }

        private async Task GetUserProfile(string accessToken, string userId)
        {
            var request = new HttpRequestMessage(HttpMethod.Get, $"https://api.spotify.com/v1/users/{userId}");
            request.Headers.Add("Authorization", $"Bearer {accessToken}");

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"Failed to get user profile: {content}");
            }

            var profile = JsonSerializer.Deserialize<SpotifyUserProfile>(content);
            _logger.LogInformation($"Retrieved profile for user: {profile.DisplayName}");

            _logger.LogInformation($"Retrieved profile for user: {profile.Id}");
        }

        private async Task GetPlaylist(string accessToken, string playlistId)
        {
            var request = new HttpRequestMessage(HttpMethod.Get, $"https://api.spotify.com/v1/playlists/{playlistId}");
            request.Headers.Add("Authorization", $"Bearer {accessToken}");

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"Failed to get playlist: {content}");
            }

            var playlist = JsonSerializer.Deserialize<SpotifyPlaylist>(content);
            _logger.LogInformation($"Retrieved playlist: {playlist.Name} with {playlist.Tracks.Total} tracks");
        }

        private class SpotifyPlaylist
        {
            [JsonPropertyName("name")]
            public string Name { get; set; }

            [JsonPropertyName("id")]
            public string Id { get; set; }

            [JsonPropertyName("description")]
            public string Description { get; set; }

            [JsonPropertyName("tracks")]
            public PlaylistTracks Tracks { get; set; }
        }

        private class PlaylistTracks
        {
            [JsonPropertyName("total")]
            public int Total { get; set; }

            [JsonPropertyName("items")]
            public PlaylistTrackItem[] Items { get; set; }
        }

        private class PlaylistTrackItem
        {
            [JsonPropertyName("track")]
            public SpotifyTrack Track { get; set; }

            [JsonPropertyName("added_at")]
            public string AddedAt { get; set; }
        }

        private class SpotifyTrack
        {
            [JsonPropertyName("id")]
            public string Id { get; set; }

            [JsonPropertyName("name")]
            public string Name { get; set; }

            [JsonPropertyName("uri")]
            public string Uri { get; set; }
        }


        private class SpotifyUserProfile
        {
            [JsonPropertyName("display_name")]
            public string DisplayName { get; set; }

            [JsonPropertyName("id")]
            public string Id { get; set; }

            [JsonPropertyName("email")]
            public string Email { get; set; }

            [JsonPropertyName("country")]
            public string Country { get; set; }

            [JsonPropertyName("product")]
            public string Product { get; set; }
        }

        private class SpotifyTokenResponse
        {
            [JsonPropertyName("access_token")]
            public string AccessToken { get; set; }

            [JsonPropertyName("token_type")]
            public string TokenType { get; set; }

            [JsonPropertyName("expires_in")]
            public int ExpiresIn { get; set; }
        }
    }
}
