# 🗄️ Database Setup Guide for Corgi AI Edu

## 🔧 Step-by-Step Setup Instructions

### 1. **Access Supabase Dashboard**
- Go to [https://app.supabase.com](https://app.supabase.com)
- Navigate to your project: `gkvxoczdmuxrdseahgbv`
- Click on **SQL Editor** in the left sidebar

### 2. **Run the Database Script**
- Open the file: `supabase_setup_fixed.sql`
- Copy the entire content
- Paste it into the SQL Editor
- Click **Run** button

### 3. **Verify Setup**
After running the script, verify everything is working:

```sql
-- Check if users table exists
SELECT table_name FROM information_schema.tables WHERE table_name = 'users';

-- Check table structure  
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Check storage bucket
SELECT * FROM storage.buckets WHERE name = 'avatars';
```

### 4. **Expected Results**
✅ **Users table created** with columns:
- `id` (UUID, Primary Key)
- `name` (TEXT, NOT NULL)
- `email` (TEXT, UNIQUE, NOT NULL)
- `role` (TEXT, DEFAULT 'student')
- `avatar_url` (TEXT, NULLABLE)
- `city` (TEXT, NULLABLE)
- `birth_date` (DATE, NULLABLE)
- `points` (INTEGER, DEFAULT 0)
- `created_at` (TIMESTAMP)
- `last_login_at` (TIMESTAMP)
- `is_student` (BOOLEAN, DEFAULT true)

✅ **RLS Policies** enabled for security
✅ **Storage bucket** 'avatars' created
✅ **Trigger** for automatic profile creation
✅ **Permissions** granted to authenticated users

## 🚨 Common Issues & Solutions

### Issue 1: "relation does not exist"
**Problem**: Running the app before setting up the database
**Solution**: Run the SQL script first, then test the app

### Issue 2: "permission denied for table users"
**Problem**: RLS policies not properly set
**Solution**: Re-run the script, check permissions

### Issue 3: "bucket does not exist"
**Problem**: Storage bucket not created
**Solution**: Check if storage is enabled in your Supabase project

### Issue 4: "function does not exist"
**Problem**: Trigger function not created
**Solution**: Ensure the entire script runs without errors

## 📋 Manual Verification Steps

1. **Check Authentication**:
   ```sql
   SELECT * FROM auth.users LIMIT 1;
   ```

2. **Test User Creation**:
   ```sql
   SELECT * FROM public.users LIMIT 1;
   ```

3. **Check Storage**:
   ```sql
   SELECT * FROM storage.buckets WHERE name = 'avatars';
   ```

4. **Verify Trigger**:
   ```sql
   SELECT trigger_name FROM information_schema.triggers 
   WHERE trigger_name = 'on_auth_user_created';
   ```

## 🔄 If You Need to Reset

```sql
-- WARNING: This will delete all data!
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP TABLE IF EXISTS public.users CASCADE;
DELETE FROM storage.buckets WHERE name = 'avatars';
```

Then re-run the setup script.

## ✅ Testing the Setup

1. **Run the Flutter app**: `flutter run`
2. **Try registration** with all fields
3. **Check Supabase dashboard** → Authentication → Users
4. **Verify user data** in the Users table
5. **Test avatar upload** and check Storage

## 🎯 What This Setup Enables

- ✅ **User registration** with extended profile data
- ✅ **Avatar upload** to Supabase Storage  
- ✅ **City and birth date** collection
- ✅ **Role-based access** (student by default)
- ✅ **Points system** for gamification
- ✅ **Analytics data** for user segmentation
- ✅ **Secure data access** with RLS policies

---

**Need help?** Check the verification queries in the SQL script to diagnose any issues.