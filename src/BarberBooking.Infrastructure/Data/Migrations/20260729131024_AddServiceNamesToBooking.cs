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
            migrationBuilder.AddColumn<string>(
                name: "ServiceNames",
                table: "Bookings",
                type: "text",
                nullable: true);
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
