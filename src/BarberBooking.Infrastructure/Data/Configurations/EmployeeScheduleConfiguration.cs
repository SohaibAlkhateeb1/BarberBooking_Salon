using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class EmployeeScheduleConfiguration : IEntityTypeConfiguration<EmployeeSchedule>
{
    public void Configure(EntityTypeBuilder<EmployeeSchedule> builder)
    {
        builder.ToTable("EmployeeSchedules");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.DayName)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(e => e.IsOpen)
            .IsRequired();

        builder.Property(e => e.OpenTime)
            .IsRequired();

        builder.Property(e => e.CloseTime)
            .IsRequired();

        builder.HasOne(e => e.Employee)
            .WithMany(emp => emp.Schedules)
            .HasForeignKey(e => e.EmployeeId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(e => new { e.EmployeeId, e.DayName })
            .IsUnique();
    }
}
