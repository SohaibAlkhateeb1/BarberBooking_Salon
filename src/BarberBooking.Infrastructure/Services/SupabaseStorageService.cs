using System.Net.Http.Headers;
using System.Text;
using BarberBooking.Application.Interfaces;

namespace BarberBooking.Infrastructure.Services;

public class SupabaseStorageService : IFileStorageService
{
    private readonly string _supabaseUrl;
    private readonly string _supabaseKey;
    private readonly HttpClient _httpClient;
    private const string BucketName = "barber-uploads";

    public SupabaseStorageService(string supabaseUrl, string supabaseKey)
    {
        _supabaseUrl = supabaseUrl.TrimEnd('/');
        _supabaseKey = supabaseKey;
        _httpClient = new HttpClient();
    }

    public async Task<string> SaveImageAsync(string imageBase64, string folder = "images")
    {
        if (imageBase64.Contains(','))
            imageBase64 = imageBase64.Substring(imageBase64.IndexOf(',') + 1);

        var bytes = Convert.FromBase64String(imageBase64);
        var fileName = $"{Guid.NewGuid()}.jpg";
        var path = $"{folder}/{fileName}";

        var url = $"{_supabaseUrl}/storage/v1/object/{BucketName}/{path}";

        var request = new HttpRequestMessage(HttpMethod.Post, url);
        request.Headers.Add("apikey", _supabaseKey);
        request.Headers.Add("Authorization", $"Bearer {_supabaseKey}");

        var content = new ByteArrayContent(bytes);
        content.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        request.Content = content;

        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();

        return $"{_supabaseUrl}/storage/v1/object/public/{BucketName}/{path}";
    }

    public async Task<bool> DeleteImageAsync(string imageUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(imageUrl)) return false;

            var marker = $"/object/public/{BucketName}/";
            var idx = imageUrl.IndexOf(marker);
            if (idx < 0) return false;

            var path = imageUrl.Substring(idx + marker.Length);

            var url = $"{_supabaseUrl}/storage/v1/object/{BucketName}/{path}";

            var request = new HttpRequestMessage(HttpMethod.Delete, url);
            request.Headers.Add("apikey", _supabaseKey);
            request.Headers.Add("Authorization", $"Bearer {_supabaseKey}");

            var response = await _httpClient.SendAsync(request);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    public string GetImageUrl(string fileName, string folder = "images")
    {
        return $"{_supabaseUrl}/storage/v1/object/public/{BucketName}/{folder}/{fileName}";
    }
}
