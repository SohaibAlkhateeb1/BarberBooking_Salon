using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class BookingConfiguration : IEntityTypeConfiguration<Booking>
{
    public void Configure(EntityTypeBuilder<Booking> builder)
    {
        builder.ToTable("Bookings");
        builder.HasKey(b => b.Id);
        builder.Property(b => b.Id).ValueGeneratedOnAdd();
        builder.Property(b => b.BookingDate).IsRequired();
        builder.Property(b => b.BookingTime).IsRequired();
        builder.Property(b => b.TotalPrice).IsRequired().HasColumnType("decimal(18,2)");
        builder.Property(b => b.Status).IsRequired().HasMaxLength(20).HasDefaultValue("Upcoming");
        builder.Property(b => b.CancellationReason).HasMaxLength(500);
        builder.Property(b => b.Notes).HasMaxLength(1000);
        builder.Property(b => b.PromoCode).HasMaxLength(50);
        builder.Property(b => b.CreatedAt).IsRequired();
        builder.Property(b => b.UpdatedAt).IsRequired(false);

        builder.HasOne(b => b.Customer)
            .WithMany()
            .HasForeignKey(b => b.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(b => b.BarberProfile)
            .WithMany(bp => bp.Bookings)
            .HasForeignKey(b => b.BarberProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(b => b.BarberService)
            .WithMany()
            .HasForeignKey(b => b.BarberServiceId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(b => b.Employee)
            .WithMany()
            .HasForeignKey(b => b.EmployeeId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(b => b.CustomerId);
        builder.HasIndex(b => b.BarberProfileId);
        builder.HasIndex(b => b.Status);
    }
}
