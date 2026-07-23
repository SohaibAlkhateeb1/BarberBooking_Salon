using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class UserDeviceConfiguration : IEntityTypeConfiguration<UserDevice>
{
    public void Configure(EntityTypeBuilder<UserDevice> builder)
    {
        builder.HasKey(ud => ud.Id);

        builder.Property(ud => ud.FcmToken)
            .IsRequired()
            .HasMaxLength(500);

        builder.Property(ud => ud.Platform)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(ud => ud.DeviceName)
            .HasMaxLength(200);

        builder.HasIndex(ud => ud.FcmToken);
        builder.HasIndex(ud => ud.UserId);
        builder.HasIndex(ud => new { ud.UserId, ud.FcmToken }).IsUnique();

        builder.HasOne(ud => ud.User)
            .WithMany()
            .HasForeignKey(ud => ud.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
