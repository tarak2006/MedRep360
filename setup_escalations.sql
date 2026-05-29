-- Run this SQL in your Supabase SQL Editor to create the escalations table and insert some raw data.

CREATE TABLE IF NOT EXISTS public.escalations (
    id SERIAL PRIMARY KEY,
    doctor_name TEXT NOT NULL,
    query TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Pending',
    assigned_to TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert some dummy data so you can see how it looks in the app
INSERT INTO public.escalations (doctor_name, query, status, assigned_to, created_at) VALUES
('Dr. Alice Smith', 'Requested samples of Paracetamol 500mg but only received 250mg.', 'Pending', NULL, NOW() - INTERVAL '2 days'),
('Dr. Bob Jones', 'The login credentials for the portal are not working.', 'In Progress', 'Tech Alex', NOW() - INTERVAL '1 day'),
('Dr. Charlie Brown', 'Need detailed literature on the new cardiovascular drug efficacy.', 'Pending', NULL, NOW() - INTERVAL '4 hours'),
('Dr. Diana Prince', 'Delivery of last week''s order is delayed by 3 days.', 'Resolved', 'Tech Sarah', NOW() - INTERVAL '5 days');
