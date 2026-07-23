using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class BarberServiceConfiguration : IEntityTypeConfiguration<BarberService>
{
    public void Configure(EntityTypeBuilder<BarberService> builder)
    {
        builder.ToTable("BarberServices");
        builder.HasKey(bs => bs.Id);
        builder.Property(bs => bs.Id).ValueGeneratedOnAdd();
        builder.Property(bs => bs.Name).IsRequired().HasMaxLength(200);
        builder.Property(bs => bs.Price).IsRequired().HasColumnType("decimal(18,2)");
        builder.Property(bs => bs.DurationInMinutes).IsRequired();
        builder.Property(bs => bs.CreatedAt).IsRequired();
        builder.Property(bs => bs.UpdatedAt).IsRequired(false);

        builder.HasOne(bs => bs.BarberProfile)
            .WithMany(bp => bp.Services)
            .HasForeignKey(bs => bs.BarberProfileId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
