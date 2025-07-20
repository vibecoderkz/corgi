-- ========================================
-- CORGI AI EDU - Database Setup Script
-- ========================================
-- Run this script in your Supabase SQL Editor

-- Step 1: Create users table for Corgi AI Edu
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'student',
    avatar_url TEXT,
    city TEXT,
    birth_date DATE,
    points INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_student BOOLEAN DEFAULT true
);

-- Step 2: Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 3: Create RLS policies for users table
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Step 4: Create storage bucket for avatars (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Create storage policies for avatars
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can update their own avatar" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'avatars' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'avatars' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Step 6: Create function to automatically create user profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (
        id, 
        name, 
        email, 
        role,
        avatar_url,
        city,
        birth_date
    )
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'name',
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'city',
        CASE 
            WHEN NEW.raw_user_meta_data->>'birth_date' IS NOT NULL 
            THEN (NEW.raw_user_meta_data->>'birth_date')::DATE
            ELSE NULL
        END
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Create trigger to automatically create user profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 8: Grant permissions
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO service_role;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================
-- Run these to verify everything is working:

-- 1. Check if table exists
-- SELECT table_name FROM information_schema.tables WHERE table_name = 'users';

-- 2. Check table structure
-- SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'users';

-- 3. Check RLS policies
-- SELECT * FROM pg_policies WHERE tablename = 'users';

-- 4. Check storage bucket
-- SELECT * FROM storage.buckets WHERE name = 'avatars';

-- 5. Check trigger exists
-- SELECT trigger_name FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created';