using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class BarberEmployeeConfiguration : IEntityTypeConfiguration<BarberEmployee>
{
    public void Configure(EntityTypeBuilder<BarberEmployee> builder)
    {
        builder.ToTable("BarberEmployees");
        builder.HasKey(be => be.Id);
        builder.Property(be => be.Id).ValueGeneratedOnAdd();
        builder.Property(be => be.Name).IsRequired().HasMaxLength(200);
        builder.Property(be => be.PhoneNumber).IsRequired().HasMaxLength(20);
        builder.Property(be => be.ProfileImageUrl).HasColumnType("text");
        builder.Property(be => be.IsActive).IsRequired().HasDefaultValue(true);
        builder.Property(be => be.CreatedAt).IsRequired();
        builder.Property(be => be.UpdatedAt).IsRequired(false);

        builder.HasIndex(be => be.BarberProfileId);

        builder.HasOne(be => be.BarberProfile)
            .WithMany(bp => bp.Employees)
            .HasForeignKey(be => be.BarberProfileId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
