-- Seed data for I'll Do It

-- Note: In a real Supabase environment, users must be created via Auth first.
-- This script assumes you want to test with some dummy data.

-- 1. Create some sample services (requires user_id)
-- We'll use the handle_new_user trigger logic or manually insert if we have IDs.

-- For local development/testing, you can run this to see data:

-- Sample Services
INSERT INTO public.services (id, user_id, title, description, category, price, delivery_time, rating, total_orders)
VALUES 
(gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'Professional Logo Design', 'I will design a modern and professional logo for your brand or business.', 'Graphic Design', 500.00, 3, 4.8, 12),
(gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'Mathematics Tutoring (Grade 10-12)', 'Experienced tutor helping you master calculus, algebra and more.', 'Tutoring', 200.00, 1, 5.0, 8),
(gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'Custom WordPress Website', 'Get a fully responsive business website built with WordPress.', 'Web Development', 2500.00, 7, 4.5, 5),
(gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'Social Media Management', 'I will manage your Instagram and Facebook pages for a month.', 'Social Media Help', 1500.00, 30, 4.9, 3);

-- Sample Jobs
INSERT INTO public.jobs (id, client_id, title, description, category, budget, deadline, status)
VALUES 
(gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'Need a Wedding Photographer', 'Looking for an affordable photographer for a small wedding in Tzaneen.', 'Photography', 3000.00, NOW() + INTERVAL '30 days', 'open'),
(gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'App Bug Fixing', 'Need help fixing some UI bugs in my Flutter application.', 'Tech Support', 800.00, NOW() + INTERVAL '7 days', 'open'),
(gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'CV & Cover Letter Writing', 'Need someone to polish my CV for a teaching job application.', 'CV Writing', 350.00, NOW() + INTERVAL '2 days', 'open');

-- Note: The '00000000-0000-0000-0000-000000000000' is a placeholder. 
-- You should replace it with a real user ID from your auth.users table.
