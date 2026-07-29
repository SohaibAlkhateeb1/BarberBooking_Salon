using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BarberBooking.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddServiceNamesToBooking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns 
                        WHERE table_name = 'Bookings' AND column_name = 'ServiceNames'
                    ) THEN
                        ALTER TABLE ""Bookings"" ADD COLUMN ""ServiceNames"" text;
                    END IF;
                END $$;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ServiceNames",
                table: "Bookings");
        }
    }
}
