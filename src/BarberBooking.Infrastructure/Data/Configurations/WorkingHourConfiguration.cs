using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class WorkingHourConfiguration : IEntityTypeConfiguration<WorkingHour>
{
    public void Configure(EntityTypeBuilder<WorkingHour> builder)
    {
        builder.ToTable("WorkingHours");
        builder.HasKey(wh => wh.Id);
        builder.Property(wh => wh.Id).ValueGeneratedOnAdd();
        builder.Property(wh => wh.DayName).IsRequired().HasMaxLength(20);
        builder.Property(wh => wh.IsOpen).IsRequired();
        builder.Property(wh => wh.OpenTime).IsRequired();
        builder.Property(wh => wh.CloseTime).IsRequired();
        builder.Property(wh => wh.CreatedAt).IsRequired();
        builder.Property(wh => wh.UpdatedAt).IsRequired(false);

        builder.HasOne(wh => wh.BarberProfile)
            .WithMany(bp => bp.WorkingHours)
            .HasForeignKey(wh => wh.BarberProfileId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
