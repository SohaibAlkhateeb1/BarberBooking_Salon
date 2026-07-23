using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class BarberPortfolioImageConfiguration : IEntityTypeConfiguration<BarberPortfolioImage>
{
    public void Configure(EntityTypeBuilder<BarberPortfolioImage> builder)
    {
        builder.ToTable("PortfolioImages");
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).ValueGeneratedOnAdd();
        builder.Property(p => p.ImageUrl).IsRequired().HasColumnType("text");
        builder.Property(p => p.Caption).HasMaxLength(500);
        builder.Property(p => p.SortOrder).IsRequired().HasDefaultValue(0);
        builder.Property(p => p.CreatedAt).IsRequired();
        builder.Property(p => p.UpdatedAt).IsRequired(false);

        builder.HasIndex(p => p.BarberProfileId);
        builder.HasOne(p => p.BarberProfile)
            .WithMany(bp => bp.PortfolioImages)
            .HasForeignKey(p => p.BarberProfileId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
