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
- **DiscussionService**: Complete discussion management with posts, votes, and notifications

All services use the `SupabaseService.requireAuth()` pattern for authenticated operations and `SupabaseService.safeExecute()` for error handling.

### Database Schema Hierarchy
```
Users (auth.users extended)
├── Points/Achievements/Progress
└── User Profiles

Courses
├── Modules (ordered by order_index)
│   ├── Lessons (ordered by order_index)
│   │   └── Homework
│   └── Final Projects
└── Final Projects

Purchases (course/module/lesson level)

Discussion System:
Discussion Groups (course/module/lesson level)
├── Posts (hierarchical with parent-child relationships)
│   ├── Post Votes (helpful voting with point awards)
│   └── Post Statistics
├── Notifications (real-time activity tracking)
└── Trending Analytics (popular discussions)
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
│   ├── discussion_service.dart  # Complete discussion management
│   └── [other services]
├── screens/
│   ├── admin/                   # Admin-only screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── manage_discussions_screen.dart   # Discussion moderation
│   │   └── [other admin screens]
│   ├── course_details_screen.dart
│   ├── profile_screen.dart      # User dashboard with quick admin actions
│   ├── community_screen.dart    # Discussion hub with tabs
│   ├── discussion_details_screen.dart  # Full discussion interface
│   ├── create_discussion_screen.dart   # Discussion creation form
│   ├── search_discussions_screen.dart  # Advanced search
│   └── [other screens]
└── models/
    ├── discussion_models.dart   # Discussion-related data structures
    └── [other models]
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
- **Discussion Management**: Admin moderation tools for discussions, posts, and users

### Discussion System Features
- **Community Screen**: Central discussion hub with trending discussions
- **Discussion Creation**: Form-based discussion group creation tied to content
- **Discussion Details**: Full interface with posts, replies, and helpful voting
- **Advanced Search**: Filter discussions by content type, questions only, etc.
- **Helpful Voting**: "ПОЛЕЗНО" system that awards points to post authors
- **Real-time Notifications**: Activity tracking for new posts and replies
- **Admin Moderation**: Edit, delete, pin/unpin discussions and posts

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

### Discussion System Implementation Details

#### Database Schema Additions
- **discussion_groups**: Content-tied discussion containers
- **discussion_posts**: Hierarchical posts with parent-child relationships
- **post_votes**: Helpful voting with unique constraints
- **notifications**: Real-time activity tracking
- **Database Triggers**: Automatic point calculation for helpful votes

#### Key Features Implemented
1. **Hierarchical Comments**: Parent-child post relationships with unlimited nesting
2. **Helpful Voting System**: "ПОЛЕЗНО" votes award points to authors automatically
3. **Vote Restrictions**: Users cannot vote on their own posts, one vote per user per post
4. **Content Integration**: Discussions tied to courses, modules, or lessons
5. **Real-time Updates**: Notifications for new posts and activity
6. **Admin Controls**: Full moderation capabilities for discussion management
7. **Search & Filtering**: Advanced search with content type and question filters
8. **Trending Analytics**: Popular discussion tracking based on activity

#### Service Methods (DiscussionService)
- `getAccessibleDiscussionGroups()`: User's available discussions
- `createDiscussionGroup()`: Create new discussion tied to content
- `getDiscussionPosts()`: Retrieve posts with optional reply nesting
- `createPost()`: Create new posts or replies
- `voteOnPost()`/`removeVote()`: Helpful voting with point awards
- `searchDiscussionsAdvanced()`: Advanced search with filters
- `getTrendingDiscussions()`: Popular discussions analytics
- `updateDiscussionGroup()`/`deleteDiscussionGroup()`: Admin management

#### Points Integration
Helpful votes automatically award points through database triggers:
- Post marked helpful: +5 points to author
- Vote removed: -5 points from author
- Prevents gaming through self-voting restrictions

Always run lint and typecheck commands before committing changes to maintain code quality.