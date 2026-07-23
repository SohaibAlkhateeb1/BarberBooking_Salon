namespace BarberBooking.Domain.Entities;

public class RevokedToken : BaseEntity
{
    public string Jti { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
}
