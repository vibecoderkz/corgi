# Discussion System Setup Guide

## 🛠️ Database Setup Required

The discussion system requires additional database tables that need to be created in your Supabase project.

### Step 1: Run Database Schema

1. Open your Supabase dashboard
2. Go to the SQL Editor
3. Copy and paste the content from `discussion_system_schema.sql`
4. Run the SQL script

This will create:
- `discussion_groups` table
- `discussion_posts` table  
- `post_votes` table
- `notifications` table
- All necessary indexes
- Database functions for points and statistics
- Triggers for automatic updates
- Row Level Security (RLS) policies

### Step 2: Add Sample Data (Optional)

1. In the Supabase SQL Editor
2. Copy and paste the content from `sample_discussion_data.sql`
3. Run the SQL script

This will add some sample discussion groups and posts for testing.

### Step 3: Verify Tables

Check that these tables were created in your Supabase database:
- ✅ `discussion_groups`
- ✅ `discussion_posts`
- ✅ `post_votes`
- ✅ `notifications`

### Step 4: Test the App

After running the SQL scripts:
1. Restart your Flutter app
2. Navigate to the Community screen
3. You should now be able to:
   - View discussions
   - Create new discussions
   - Post messages and replies
   - Vote on helpful posts
   - Earn points for helpful votes

## 🔧 Required Database Functions

The schema includes these essential functions that the app depends on:
- `user_has_course_access(user_id, course_id)` 
- `user_has_module_access(user_id, module_id)`
- `user_has_lesson_access(user_id, lesson_id)`
- `get_trending_discussions(limit)`
- `get_discussion_stats(group_id)`

These should already exist from your main database schema, but if not, you'll need to create them.

## 🚨 Troubleshooting

### Error: "Table doesn't exist"
- Make sure you ran `discussion_system_schema.sql` completely
- Check the Supabase logs for any SQL errors
- Verify all tables are visible in the Table Editor

### Error: "Function doesn't exist"
- Ensure you have the user access functions from your main schema
- Check if RLS policies are properly applied

### Error: "Permission denied"
- Verify RLS policies are set up correctly
- Make sure users are authenticated
- Check that users have access to the courses/modules/lessons

## 📋 Features Included

After setup, your discussion system will have:

✅ **Hierarchical Discussions**
- Course-level discussions
- Module-level discussions  
- Lesson-level discussions

✅ **Post Management**
- Create posts and replies
- Edit your own posts
- Pin important posts (admins)

✅ **Voting System**
- "ПОЛЕЗНО" (helpful) voting
- Automatic point awards (+5 points per helpful vote)
- Vote restrictions (can't vote on own posts)

✅ **Access Control**
- Only users with access to content can participate
- RLS policies enforce permissions
- Admin moderation capabilities

✅ **Real-time Features**
- Automatic notifications for new posts
- Live vote counting
- Recent activity tracking

✅ **Analytics**
- Trending discussions
- Discussion statistics
- User engagement metrics

## 🔄 Next Steps

1. Run the database scripts
2. Test the discussion features
3. Customize the UI/UX as needed
4. Add more discussion categories if desired
5. Configure notification preferences

The discussion system is now fully integrated with your existing points and purchase systems!