using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BarberBooking.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSubscriptionHistoryAndEmployees : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HasAnalytics",
                table: "SubscriptionPlans");

            migrationBuilder.AddColumn<string>(
                name: "AnalyticsLevel",
                table: "SubscriptionPlans",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "MaxBookingsPerMonth",
                table: "SubscriptionPlans",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MaxEmployees",
                table: "SubscriptionPlans",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "PaymentConfirmedAt",
                table: "BarberSubscriptions",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaymentConfirmedBy",
                table: "BarberSubscriptions",
                type: "text",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "WhatsAppNumber",
                table: "BarberProfiles",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "TikTokHandle",
                table: "BarberProfiles",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "InstagramHandle",
                table: "BarberProfiles",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FcmToken",
                table: "BarberProfiles",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "BarberEmployees",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BarberProfileId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    PhoneNumber = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ProfileImageUrl = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BarberEmployees", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BarberEmployees_BarberProfiles_BarberProfileId",
                        column: x => x.BarberProfileId,
                        principalTable: "BarberProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SubscriptionHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BarberSubscriptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    BarberProfileId = table.Column<Guid>(type: "uuid", nullable: false),
                    Action = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    PreviousPlanId = table.Column<Guid>(type: "uuid", nullable: true),
                    NewPlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    AmountPaid = table.Column<decimal>(type: "numeric", nullable: false),
                    PaymentMethod = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    PaymentConfirmedBy = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubscriptionHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SubscriptionHistories_BarberProfiles_BarberProfileId",
                        column: x => x.BarberProfileId,
                        principalTable: "BarberProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SubscriptionHistories_BarberSubscriptions_BarberSubscriptio~",
                        column: x => x.BarberSubscriptionId,
                        principalTable: "BarberSubscriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SubscriptionHistories_SubscriptionPlans_NewPlanId",
                        column: x => x.NewPlanId,
                        principalTable: "SubscriptionPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SubscriptionHistories_SubscriptionPlans_PreviousPlanId",
                        column: x => x.PreviousPlanId,
                        principalTable: "SubscriptionPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BarberEmployees_BarberProfileId",
                table: "BarberEmployees",
                column: "BarberProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionHistories_BarberProfileId",
                table: "SubscriptionHistories",
                column: "BarberProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionHistories_BarberSubscriptionId",
                table: "SubscriptionHistories",
                column: "BarberSubscriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionHistories_NewPlanId",
                table: "SubscriptionHistories",
                column: "NewPlanId");

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionHistories_PreviousPlanId",
                table: "SubscriptionHistories",
                column: "PreviousPlanId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BarberEmployees");

            migrationBuilder.DropTable(
                name: "SubscriptionHistories");

            migrationBuilder.DropColumn(
                name: "AnalyticsLevel",
                table: "SubscriptionPlans");

            migrationBuilder.DropColumn(
                name: "MaxBookingsPerMonth",
                table: "SubscriptionPlans");

            migrationBuilder.DropColumn(
                name: "MaxEmployees",
                table: "SubscriptionPlans");

            migrationBuilder.DropColumn(
                name: "PaymentConfirmedAt",
                table: "BarberSubscriptions");

            migrationBuilder.DropColumn(
                name: "PaymentConfirmedBy",
                table: "BarberSubscriptions");

            migrationBuilder.DropColumn(
                name: "FcmToken",
                table: "BarberProfiles");

            migrationBuilder.AddColumn<bool>(
                name: "HasAnalytics",
                table: "SubscriptionPlans",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<string>(
                name: "WhatsAppNumber",
                table: "BarberProfiles",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "TikTokHandle",
                table: "BarberProfiles",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "InstagramHandle",
                table: "BarberProfiles",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100,
                oldNullable: true);
        }
    }
}
