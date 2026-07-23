namespace BarberBooking.Application.Interfaces;

public interface IFileStorageService
{
    Task<string> SaveImageAsync(string imageBase64, string folder = "images");
    Task<bool> DeleteImageAsync(string imageUrl);
    string GetImageUrl(string fileName, string folder = "images");
}

public class LocalFileStorageService : IFileStorageService
{
    private readonly string _basePath;
    private readonly string _baseUrl;

    public LocalFileStorageService(string basePath, string baseUrl)
    {
        _basePath = basePath;
        _baseUrl = baseUrl;

        if (!Directory.Exists(_basePath))
            Directory.CreateDirectory(_basePath);
    }

    public async Task<string> SaveImageAsync(string imageBase64, string folder = "images")
    {
        // Remove data:image/xxx;base64, prefix if present
        if (imageBase64.Contains(','))
            imageBase64 = imageBase64.Substring(imageBase64.IndexOf(',') + 1);

        var bytes = Convert.FromBase64String(imageBase64);
        var fileName = $"{Guid.NewGuid()}.jpg";
        var folderPath = Path.Combine(_basePath, folder);

        if (!Directory.Exists(folderPath))
            Directory.CreateDirectory(folderPath);

        var filePath = Path.Combine(folderPath, fileName);
        await File.WriteAllBytesAsync(filePath, bytes);

        return $"{_baseUrl}/{folder}/{fileName}";
    }

    public Task<bool> DeleteImageAsync(string imageUrl)
    {
        try
        {
            var uri = new Uri(imageUrl);
            var relativePath = uri.AbsolutePath.TrimStart('/');
            var filePath = Path.Combine(_basePath, relativePath);

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
                return Task.FromResult(true);
            }

            return Task.FromResult(false);
        }
        catch
        {
            return Task.FromResult(false);
        }
    }

    public string GetImageUrl(string fileName, string folder = "images")
    {
        return $"{_baseUrl}/{folder}/{fileName}";
    }
}
