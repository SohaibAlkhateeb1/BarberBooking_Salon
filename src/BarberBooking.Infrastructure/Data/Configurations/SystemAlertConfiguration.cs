using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class SystemAlertConfiguration : IEntityTypeConfiguration<SystemAlert>
{
    public void Configure(EntityTypeBuilder<SystemAlert> builder)
    {
        builder.ToTable("SystemAlerts");
        builder.HasKey(a => a.Id);
        builder.Property(a => a.Id).ValueGeneratedOnAdd();
        builder.Property(a => a.Title).IsRequired().HasMaxLength(200);
        builder.Property(a => a.Message).IsRequired().HasMaxLength(2000);
        builder.Property(a => a.Severity).IsRequired().HasMaxLength(20).HasDefaultValue("Info");
        builder.Property(a => a.Category).IsRequired().HasMaxLength(50).HasDefaultValue("Custom");
        builder.Property(a => a.Status).IsRequired().HasMaxLength(20).HasDefaultValue("New");
        builder.Property(a => a.Priority).IsRequired().HasMaxLength(20).HasDefaultValue("Medium");
        builder.Property(a => a.Source).IsRequired().HasMaxLength(50).HasDefaultValue("System");
        builder.Property(a => a.CreatedBy).HasMaxLength(100);
        builder.Property(a => a.RelatedEntityType).HasMaxLength(50);
        builder.Property(a => a.TargetUserType).HasMaxLength(20);
        builder.Property(a => a.CreatedAt).IsRequired();
        builder.Property(a => a.UpdatedAt).IsRequired(false);

        builder.HasOne(a => a.TargetUser)
            .WithMany()
            .HasForeignKey(a => a.TargetUserId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(a => a.Status);
        builder.HasIndex(a => a.Severity);
        builder.HasIndex(a => a.Category);
        builder.HasIndex(a => a.Priority);
        builder.HasIndex(a => a.TargetUserId);
        builder.HasIndex(a => a.CreatedAt);
    }
}
