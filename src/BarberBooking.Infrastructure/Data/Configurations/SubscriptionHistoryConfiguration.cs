using BarberBooking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace BarberBooking.Infrastructure.Data.Configurations;

public class SubscriptionHistoryConfiguration : IEntityTypeConfiguration<SubscriptionHistory>
{
    public void Configure(EntityTypeBuilder<SubscriptionHistory> builder)
    {
        builder.ToTable("SubscriptionHistories");
        builder.HasKey(sh => sh.Id);
        builder.Property(sh => sh.Id).ValueGeneratedOnAdd();
        builder.Property(sh => sh.Action).IsRequired().HasMaxLength(50);
        builder.Property(sh => sh.AmountPaid).HasColumnType("numeric");
        builder.Property(sh => sh.PaymentMethod).IsRequired().HasMaxLength(50);
        builder.Property(sh => sh.PaymentConfirmedBy).HasMaxLength(100);
        builder.Property(sh => sh.Notes).HasColumnType("text");
        builder.Property(sh => sh.CreatedAt).IsRequired();
        builder.Property(sh => sh.UpdatedAt).IsRequired(false);

        builder.HasIndex(sh => sh.BarberSubscriptionId);
        builder.HasIndex(sh => sh.BarberProfileId);

        builder.HasOne(sh => sh.BarberSubscription)
            .WithMany()
            .HasForeignKey(sh => sh.BarberSubscriptionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(sh => sh.BarberProfile)
            .WithMany()
            .HasForeignKey(sh => sh.BarberProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(sh => sh.PreviousPlan)
            .WithMany()
            .HasForeignKey(sh => sh.PreviousPlanId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(sh => sh.NewPlan)
            .WithMany()
            .HasForeignKey(sh => sh.NewPlanId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
