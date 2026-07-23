using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class PaymentRequestConfiguration : IEntityTypeConfiguration<PaymentRequest>
{
    public void Configure(EntityTypeBuilder<PaymentRequest> builder)
    {
        builder.HasKey(pr => pr.Id);

        builder.Property(pr => pr.PaymentMethod)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(pr => pr.Amount)
            .HasColumnType("decimal(18,2)");

        builder.Property(pr => pr.PlanName)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(pr => pr.Status)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(pr => pr.AdminNotes)
            .HasMaxLength(500);

        builder.HasOne(pr => pr.BarberProfile)
            .WithMany()
            .HasForeignKey(pr => pr.BarberProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(pr => pr.BarberProfileId);
        builder.HasIndex(pr => pr.Status);
    }
}
