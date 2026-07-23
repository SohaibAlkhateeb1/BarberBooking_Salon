using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class AuditLogConfiguration : IEntityTypeConfiguration<AuditLog>
{
    public void Configure(EntityTypeBuilder<AuditLog> builder)
    {
        builder.ToTable("AuditLogs");
        builder.HasKey(l => l.Id);
        builder.Property(l => l.Id).ValueGeneratedOnAdd();
        builder.Property(l => l.Action).IsRequired().HasMaxLength(100);
        builder.Property(l => l.EntityType).IsRequired().HasMaxLength(50);
        builder.Property(l => l.AdminId).IsRequired().HasMaxLength(100);
        builder.Property(l => l.AdminName).IsRequired().HasMaxLength(200);
        builder.Property(l => l.Details).HasMaxLength(2000);
        builder.Property(l => l.OldValue).HasMaxLength(500);
        builder.Property(l => l.NewValue).HasMaxLength(500);
        builder.Property(l => l.CreatedAt).IsRequired();

        builder.HasIndex(l => l.EntityType);
        builder.HasIndex(l => l.AdminId);
        builder.HasIndex(l => l.CreatedAt);
    }
}
