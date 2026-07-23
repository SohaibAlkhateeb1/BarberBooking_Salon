using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class BarberProfileConfiguration : IEntityTypeConfiguration<BarberProfile>
{
    public void Configure(EntityTypeBuilder<BarberProfile> builder)
    {
        builder.ToTable("BarberProfiles");
        builder.HasKey(bp => bp.Id);
        builder.Property(bp => bp.Id).ValueGeneratedOnAdd();
        builder.Property(bp => bp.ShopName).IsRequired().HasMaxLength(200);
        builder.Property(bp => bp.ShopDescription).HasMaxLength(1000);
        builder.Property(bp => bp.ShopLogoUrl).HasColumnType("text");
        builder.Property(bp => bp.CoverImageUrl).HasColumnType("text");
        builder.Property(bp => bp.City).IsRequired().HasMaxLength(100);
        builder.Property(bp => bp.Address).IsRequired().HasMaxLength(500);
        builder.Property(bp => bp.WhatsAppNumber).HasMaxLength(20);
        builder.Property(bp => bp.InstagramHandle).HasMaxLength(100);
        builder.Property(bp => bp.TikTokHandle).HasMaxLength(100);
        builder.Property(bp => bp.SubscriptionPlan).IsRequired().HasMaxLength(20).HasDefaultValue("basic");
        builder.Property(bp => bp.IsYearly).IsRequired().HasDefaultValue(false);
        builder.Property(bp => bp.FcmToken).HasMaxLength(500);
        builder.Property(bp => bp.CreatedAt).IsRequired();
        builder.Property(bp => bp.UpdatedAt).IsRequired(false);

        builder.HasIndex(bp => bp.UserId).IsUnique();
        builder.HasOne(bp => bp.User)
            .WithOne(u => u.BarberProfile)
            .HasForeignKey<BarberProfile>(bp => bp.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
