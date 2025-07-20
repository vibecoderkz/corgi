# Database Setup Order for Points System

## 🚀 Quick Setup (Recommended)

Run this single file that includes everything:
```sql
\i points_system_complete.sql
```

## 📋 Manual Setup (If you prefer step-by-step)

Run these files in order:

### 1. Base Points Configuration
```sql
\i points_configuration.sql
```

### 2. Database Fixes and User Table Updates
```sql
\i database_fixes.sql
```

### 3. Admin Policies
```sql
\i points_admin_policies.sql
```

## 🔧 What Gets Created

### Tables:
- `currency_config` - Currency settings per country
- `points_config` - Points earning configuration
- `points_spending_config` - Points spending limits
- `points_spending` - Points spending transactions
- `user_preferences` - User currency preferences

### Functions:
- `award_activity_points()` - Award points for activities
- `can_spend_points()` - Check if user has enough points
- `spend_user_points()` - Spend user points
- `get_points_leaderboard()` - Get points leaderboard
- `get_user_points_history()` - Get user's points history
- `get_points_analytics()` - Get analytics for admin

### Triggers:
- Automatic points awarding for homework/projects
- Automatic points deduction when spending
- User total points updates

### Views:
- `user_points_summary` - Comprehensive points overview

### User Table Updates:
- Added `role` field (student, teacher, admin)
- Added `city` field
- Added `birth_date` field  
- Added `name` field (for display)

## 🧪 Testing

After running the setup:

1. **Check tables exist:**
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name LIKE '%points%' OR table_name LIKE '%currency%';
   ```

2. **Check functions exist:**
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_schema = 'public' 
   AND routine_name LIKE '%points%';
   ```

3. **Check sample data:**
   ```sql
   SELECT * FROM points_config;
   SELECT * FROM currency_config;
   SELECT * FROM points_spending_config;
   ```

## 🔑 Create Admin User

After setup, create an admin user:
```sql
UPDATE users SET role = 'admin' WHERE email = 'your-admin-email@example.com';
```

## 📱 Flutter App

The Flutter app is already updated to work with this system. Just run:
```bash
flutter pub get
flutter run
```

## 🛠️ Admin Access

1. Login with admin account
2. Go to Profile → Admin Dashboard
3. Click "Points Settings" to configure the system

## 🌍 Currency Configuration

Default setup includes:
- **KZT (Kazakhstan)**: 1 KZT = 0.1 points
- **RUB (Russia)**: 1 RUB = 1 point
- **USD (Other countries)**: 1 USD = 100 points

You can modify these in the Admin → Points Settings → Currency tab.

## 🎯 Points Earning

Default configuration:
- Homework: 10 points + variable from homework table
- Final Project: 50 points + variable from project table  
- Module Completion: 50 points bonus
- Course Completion: 100 points bonus
- Useful Post: 5 points
- Daily Login: 2 points
- Achievement: 20 points
- Referral: 100 points

## 💸 Points Spending

Default discount limits:
- Course purchases: 10% max discount
- Module purchases: 15% max discount
- Lesson purchases: 20% max discount
- Overall maximum: 50% discount

## 🔒 Security

- Row Level Security (RLS) enabled on all tables
- Users can only spend their own points
- Admins can manage all configurations
- Secure transaction logging and audit trails

## 📊 Analytics

Admins can view:
- Total points awarded/spent
- Points spending by currency
- User engagement metrics
- Recent transaction history

## 🆘 Troubleshooting

If you encounter issues:

1. **Check if tables exist**: Run the testing queries above
2. **Check user permissions**: Ensure RLS policies are correct
3. **Verify admin role**: Make sure admin user has `role = 'admin'`
4. **Check Flutter imports**: Ensure all service imports are correct

## 🔄 Updates

If you need to modify the system later:
- Update configuration through Admin → Points Settings
- Modify database functions if needed
- Run additional migrations for new features

The system is now fully functional and ready for production use!