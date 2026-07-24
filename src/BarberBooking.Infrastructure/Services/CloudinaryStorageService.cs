using BarberBooking.Application.Interfaces;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace BarberBooking.Infrastructure.Services;

public class CloudinaryStorageService : IFileStorageService
{
    private readonly Cloudinary _cloudinary;
    private const string FolderPrefix = "barber-booking";

    public CloudinaryStorageService(string cloudName, string apiKey, string apiSecret)
    {
        var account = new Account(cloudName, apiKey, apiSecret);
        _cloudinary = new Cloudinary(account);
        _cloudinary.Api.Secure = true;
    }

    public async Task<string> SaveImageAsync(string imageBase64, string folder = "images")
    {
        if (string.IsNullOrEmpty(imageBase64))
            throw new ArgumentException("Image data is required");

        if (imageBase64.Contains(','))
            imageBase64 = imageBase64.Substring(imageBase64.IndexOf(',') + 1);

        var bytes = Convert.FromBase64String(imageBase64);
        using var stream = new MemoryStream(bytes);

        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription($"{folder}/{Guid.NewGuid()}.jpg", stream),
            Folder = $"{FolderPrefix}/{folder}",
            Format = "jpg",
            Transformation = new Transformation().Quality("auto").FetchFormat("auto")
        };

        var result = await _cloudinary.UploadAsync(uploadParams);

        if (result.StatusCode != System.Net.HttpStatusCode.OK)
            throw new Exception($"Cloudinary upload failed: {result.Error?.Message}");

        return result.SecureUrl.AbsoluteUri;
    }

    public async Task<bool> DeleteImageAsync(string imageUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(imageUrl)) return false;

            if (!imageUrl.Contains("cloudinary.com")) return false;

            var publicId = ExtractPublicId(imageUrl);
            if (string.IsNullOrEmpty(publicId)) return false;

            var deleteParams = new DeletionParams(publicId);
            var result = await _cloudinary.DestroyAsync(deleteParams);

            return result.Result == "ok";
        }
        catch
        {
            return false;
        }
    }

    public string GetImageUrl(string fileName, string folder = "images")
    {
        return _cloudinary.Api.UrlImgUp
            .Transform(new Transformation().Width(512).Height(512).Crop("fill").Quality("auto"))
            .BuildUrl($"{FolderPrefix}/{folder}/{fileName}");
    }

    private static string ExtractPublicId(string imageUrl)
    {
        try
        {
            var uri = new Uri(imageUrl);
            var path = uri.AbsolutePath;

            var uploadIdx = path.IndexOf("/upload/");
            if (uploadIdx < 0) return string.Empty;

            var publicId = path.Substring(uploadIdx + "/upload/".Length);

            if (publicId.Contains('.'))
                publicId = publicId.Substring(0, publicId.LastIndexOf('.'));

            return publicId;
        }
        catch
        {
            return string.Empty;
        }
    }
}
