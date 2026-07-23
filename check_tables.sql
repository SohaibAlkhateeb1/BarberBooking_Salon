SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('SubscriptionPlans', 'BarberSubscriptions', 'SubscriptionHistories', 'BarberEmployees')
ORDER BY table_name;
