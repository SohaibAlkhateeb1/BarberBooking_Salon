UPDATE "SubscriptionPlans" 
SET "MonthlyPrice" = 80, 
    "YearlyPrice" = 800, 
    "MaxServices" = 5,
    "MaxPhotos" = 5,
    "MaxBookingsPerMonth" = 150, 
    "MaxEmployees" = 0, 
    "AnalyticsLevel" = 'none',
    "HasPromoCodes" = false,
    "HasPrioritySupport" = false
WHERE "Name" = 'basic';

UPDATE "SubscriptionPlans" 
SET "MonthlyPrice" = 100, 
    "YearlyPrice" = 1000, 
    "MaxServices" = 10,
    "MaxPhotos" = 15,
    "MaxBookingsPerMonth" = 250, 
    "MaxEmployees" = 3, 
    "AnalyticsLevel" = 'basic',
    "HasPromoCodes" = true,
    "HasPrioritySupport" = false
WHERE "Name" = 'pro';

UPDATE "SubscriptionPlans" 
SET "MonthlyPrice" = 150, 
    "YearlyPrice" = 1500, 
    "MaxServices" = 15,
    "MaxPhotos" = 30,
    "MaxBookingsPerMonth" = 350, 
    "MaxEmployees" = 10, 
    "AnalyticsLevel" = 'advanced',
    "HasPromoCodes" = true,
    "HasPrioritySupport" = true,
    "NameArabic" = 'VIP'
WHERE "Name" = 'premium';
