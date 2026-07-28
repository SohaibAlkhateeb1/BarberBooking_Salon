-- Clear test data (customers + barbers) but keep admin
-- Run this in Supabase SQL Editor

-- 1. Delete child tables with RESTRICT FKs first
DELETE FROM "TicketReplies" WHERE "SenderId" IN (SELECT "Id" FROM "Users" WHERE "Role" IN ('Customer', 'Barber'));
DELETE FROM "Reviews" WHERE "CustomerId" IN (SELECT "Id" FROM "Users" WHERE "Role" = 'Customer');
DELETE FROM "Bookings" WHERE "CustomerId" IN (SELECT "Id" FROM "Users" WHERE "Role" = 'Customer');

-- 2. Delete OTP codes for non-admin users
DELETE FROM "OtpCodes" WHERE "PhoneNumber" IN (SELECT "PhoneNumber" FROM "Users" WHERE "Role" IN ('Customer', 'Barber'));

-- 3. Delete SupportTickets for non-admin users
DELETE FROM "SupportTickets" WHERE "UserId" IN (SELECT "Id" FROM "Users" WHERE "Role" IN ('Customer', 'Barber'));

-- 4. Nullify SystemAlerts target user
UPDATE "SystemAlerts" SET "TargetUserId" = NULL WHERE "TargetUserId" IN (SELECT "Id" FROM "Users" WHERE "Role" IN ('Customer', 'Barber'));

-- 5. Delete all BarberProfiles (cascades to: BarberServices, WorkingHours, Employees, Schedules, EmployeeServices, Subscriptions, PaymentRequests, PortfolioImages, PromoCodes, Favorites via BarberProfileId)
DELETE FROM "BarberProfiles" WHERE "Id" IN (SELECT "Id" FROM "BarberProfiles");

-- 6. Now safe to delete users (CASCADE handles: UserDevices, RefreshTokens, Notifications, Favorites via UserId)
DELETE FROM "Users" WHERE "Role" IN ('Customer', 'Barber');

-- 7. Clean up orphaned data
DELETE FROM "OtpCodes" WHERE NOT EXISTS (SELECT 1 FROM "Users" WHERE "Users"."PhoneNumber" = "OtpCodes"."PhoneNumber");

-- Verify
SELECT 'Users remaining:' as info, COUNT(*) as count FROM "Users"
UNION ALL
SELECT 'BarberProfiles:', COUNT(*) FROM "BarberProfiles"
UNION ALL
SELECT 'Bookings:', COUNT(*) FROM "Bookings"
UNION ALL
SELECT 'Reviews:', COUNT(*) FROM "Reviews"
UNION ALL
SELECT 'Subscriptions:', COUNT(*) FROM "BarberSubscriptions";
