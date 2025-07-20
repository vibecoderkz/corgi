# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Corgi AI Edu is a Flutter-based AI education platform with Supabase backend that provides:
- Course management system with hierarchical content (Courses → Modules → Lessons)
- Role-based access control (student, admin, teacher)
- Points-based gamification system
- Discussion forums and user progress tracking
- Comprehensive admin dashboard for content management

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run linting
flutter analyze

# Clean build artifacts
flutter clean

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### Database Management
```bash
# Initialize database (run SQL files in Supabase dashboard)
# 1. database_schema.sql - Core tables and relationships
# 2. admin_policies.sql - RLS policies for admin operations
# 3. sample_data.sql - Test data for development
```

## Architecture Overview

### Core Service Pattern
The app uses a centralized service architecture with strict separation of concerns:

- **SupabaseService**: Base service providing authenticated database operations
- **AuthService**: Handles authentication, session management, and user state
- **AdminService**: Admin-only operations with role validation
- **CourseService**: Content retrieval and progress tracking
- **UserService**: Profile management and user statistics

All services use the `SupabaseService.requireAuth()` pattern for authenticated operations and `SupabaseService.safeExecute()` for error handling.

### Database Schema Hierarchy
```
Users (auth.users extended)
└── Points/Achievements/Progress

Courses
├── Modules (ordered by order_index)
│   ├── Lessons (ordered by order_index)
│   │   └── Homework
│   └── Final Projects
└── Final Projects

Purchases (course/module/lesson level)
Discussion Groups (course/module/lesson level)
└── Posts → Votes → Points
```

### Role-Based Architecture
- **Students**: Course access, progress tracking, discussions
- **Teachers**: Content viewing, student progress monitoring
- **Admins**: Full CRUD operations, analytics, user management

Role validation occurs at both service level (`AdminService.isAdmin()`) and database level (RLS policies).

### Screen Organization
```
lib/
├── main.dart                    # App entry point with routing
├── main_navigation.dart         # Bottom tab navigation
├── services/                    # Business logic layer
├── screens/
│   ├── admin/                   # Admin-only screens
│   ├── course_details_screen.dart
│   ├── profile_screen.dart      # User dashboard with quick admin actions
│   └── [other screens]
└── models/                      # Data models
```

### Authentication Flow
1. **SplashScreen** → checks existing session
2. **OnboardingScreen** → first-time user experience
3. **LoginScreen/RegistrationScreen** → authentication
4. **MainNavigation** → authenticated user interface

### Content Management Flow
- **Admin Dashboard**: Central admin panel with statistics and quick actions
- **Profile Screen**: Quick content creation (courses, modules, lessons) for admins
- **Manage Modules & Lessons Screen**: Three-panel hierarchical content browser

### Database Configuration Requirements
- Set up Supabase project with provided SQL files
- Configure environment variables in `.env`
- Enable Row Level Security (RLS) on all tables
- Create storage bucket named 'avatars' for profile pictures

### Key Integration Points
- **Supabase Auth**: Integrated with custom user profiles and role system
- **Supabase Database**: PostgreSQL with comprehensive schema including triggers
- **Supabase Storage**: Avatar uploads with proper security policies
- **Flutter Localization**: Russian/English support configured

### Error Handling Pattern
Services use consistent error handling:
```dart
return await SupabaseService.safeExecute(() async {
  // Database operation
}) ?? defaultValue;
```

UI components check for mounted state before setState operations to prevent memory leaks.

### Admin Operations
Admin functions require both:
1. Role verification: `await AdminService.isAdmin()`
2. RLS policy enforcement at database level

Content creation automatically calculates order_index and validates relationships.

### Development Database Setup
Follow DATABASE_SETUP_GUIDE.md for complete setup. Key files to run in order:
1. `database_schema.sql` - Core structure
2. `admin_policies.sql` - Security policies  
3. `sample_data.sql` - Test content

Always run lint and typecheck commands before committing changes to maintain code quality.