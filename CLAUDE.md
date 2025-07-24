# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Corgi AI Edu is a Flutter-based AI education platform with Supabase backend that provides:
> **Note**: The README.md currently contains merge conflicts that should be resolved.
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

# Run the app in development
flutter run

# Run specific tests
flutter test test/widget_test.dart
flutter test --name "specific test name"

# Run all tests
flutter test

# Run linting/static analysis
flutter analyze

# Check for dependency issues
flutter pub deps

# Clean build artifacts
flutter clean

# Generate launcher icons
flutter packages pub run flutter_launcher_icons:main

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

### Database Management
```bash
# Complete setup (recommended):
# Run points_system_complete.sql - Includes all core functionality

# OR manual setup (run SQL files in Supabase SQL Editor in this order):
# 1. database_schema.sql - Core tables and relationships
# 2. database_functions.sql - Database functions and procedures
# 3. admin_policies.sql - RLS policies for admin operations
# 4. points_configuration.sql - Points system configuration
# 5. points_admin_policies.sql - Points system RLS policies
# 6. discussion_system_schema.sql - Discussion system tables and triggers (if implementing discussions)
# 7. sample_data.sql - Test data for development
# 8. sample_discussion_data.sql - Sample discussion content (if implementing discussions)

# Database verification:
# Check setup with queries in DATABASE_SETUP_GUIDE.md
```

### Environment Setup
```bash
# Create .env file with required credentials:
# Supabase Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# OneSignal Push Notifications
ONESIGNAL_APP_ID=your_onesignal_app_id_here
ONESIGNAL_REST_API_KEY=your_onesignal_rest_api_key_here
ONESIGNAL_USER_AUTH_KEY=your_onesignal_user_auth_key_here
ONESIGNAL_WEB_PUSH_ID=your_web_push_id_here

# Install iOS dependencies (macOS only)
cd ios && pod install && cd ..
```

### OneSignal Setup Instructions
1. **Create OneSignal Account**: Go to https://onesignal.com/ and create an account
2. **Create New App**: Click "Add App" and configure for your platforms (iOS, Android, Web)
3. **Get Credentials**: 
   - **App ID**: Found in Settings > Keys & IDs
   - **REST API Key**: Found in Settings > Keys & IDs  
   - **User Auth Key**: Found in Account Settings > API Keys
   - **Web Push ID**: Found in Settings > Web Configuration (if using web platform)
4. **Update .env**: Replace placeholder values with your actual OneSignal credentials
5. **Platform Configuration**:
   - **Android**: Follow OneSignal's Firebase setup guide
   - **iOS**: Configure Apple Push Notification certificates
   - **Web**: Add OneSignal SDK to your web build

## Architecture Overview

### Core Service Pattern
The app uses a centralized service architecture with strict separation of concerns:

**Base Layer:**
- **SupabaseService**: Foundation service providing `safeExecute()` and `requireAuth()` patterns
- **AuthService**: Authentication, session management, and Supabase client initialization

**Business Logic Services:**
- **AdminService**: Admin-only operations with role validation and content CRUD
- **CourseService**: Hierarchical content retrieval and progress tracking  
- **UserService**: Profile management, statistics, and achievement tracking (includes basic points functionality)
- **PurchaseService**: Commerce operations with points integration and access control
- **OnboardingService**: First-time user experience management
- **DiscussionService**: Community features with access-based discussion management (**NOT YET IMPLEMENTED**)
- **PointsService**: Gamification system with transactions and leaderboards (**NOT YET IMPLEMENTED**)

**Service Architecture Patterns:**
- **Singleton Pattern**: All services follow consistent singleton implementation
- **Two-Tier Security**: Service-level auth checks + database RLS policies
- **Graceful Degradation**: Services return defaults rather than throwing exceptions
- **Error Handling**: `safeExecute()` for optional operations, `requireAuth()` for authenticated actions

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
│   ├── discussion_service.dart  # Complete discussion management (NOT YET IMPLEMENTED)
│   └── onboarding_service.dart  # First-time user experience
├── screens/
│   ├── admin/                   # Admin-only screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── manage_discussions_screen.dart   # Discussion moderation (NOT YET IMPLEMENTED)
│   │   └── [other admin screens - see admin/ directory]
│   ├── course_details_screen.dart
│   ├── dashboard_screen.dart    # Main user dashboard
│   ├── profile_screen.dart      # User profile with quick admin actions
│   ├── community_screen.dart    # Discussion hub with tabs (NOT YET IMPLEMENTED)
│   ├── discussion_details_screen.dart  # Full discussion interface (NOT YET IMPLEMENTED)
│   ├── create_discussion_screen.dart   # Discussion creation form (NOT YET IMPLEMENTED)
│   ├── search_discussions_screen.dart  # Advanced search (NOT YET IMPLEMENTED)
│   └── [other screens - see screens/ directory]
└── models/
    ├── discussion_models.dart   # Discussion-related data structures (NOT YET IMPLEMENTED)
    └── [other models - see models/ directory]
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
Follow DATABASE_SETUP_GUIDE.md for complete setup. Use either:
- **Quick Setup**: `points_system_complete.sql` (recommended - contains everything)
- **Manual Setup**: See Database Management section above for step-by-step order

### Implementation Status
**✅ Fully Implemented:**
- Core course/module/lesson system
- User authentication and profiles  
- Purchase system with points integration
- Admin dashboard and content management
- Basic points functionality in UserService

**⚠️ Partially Implemented:**
- Points system (database schema complete, dedicated service pending)

**❌ Not Yet Implemented:**
- Discussion system (database schema exists, UI and services missing)
- DiscussionService and related screens
- PointsService (functionality exists in UserService/PurchaseService)

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

### Purchase System Architecture

#### Purchase Flow Pattern
```dart
// 1. UI Layer: Check access status
await _checkAccess(); // Sets hasAccess boolean

// 2. Service Layer: Process purchase with points discount
final result = await PurchaseService.purchaseCourse(
  courseId, price, 'points_demo', pointsToUse: pointsToUse
);

// 3. Database Layer: Create purchase record + points transaction
// 4. UI Layer: Update access status and refresh content
```

#### Access Control Integration
- **Hierarchical Access**: Course purchase grants module/lesson access
- **Database Functions**: `user_has_course_access()`, `user_has_module_access()`, `user_has_lesson_access()`
- **Purchase Verification**: Access checks performed before content display and after purchases
- **UI State Management**: Dynamic button states based on purchase status

#### Points as Currency System
- **Currency Configuration**: Multi-country support with configurable points-per-currency ratios
- **Discount Rules**: Type-based discount percentages (course: 10%, module: 15%, lesson: 20%)
- **Maximum Limits**: 50% discount cap with real-time validation
- **Transaction Tracking**: Separate `points_spending` table with currency value conversion

### Key Development Patterns

#### Service Extension Guidelines
1. **Follow Singleton Pattern**: Use established `_instance` and `_internal()` structure
2. **Use Base Service Methods**: Leverage `SupabaseService.safeExecute()` and `requireAuth()`
3. **Implement Role Checks**: Use `AdminService.isAdmin()` for administrative operations
4. **Maintain Error Consistency**: Return appropriate defaults (empty arrays, null, false)
5. **Database Integration**: Use RPC functions for complex access control logic

#### UI Purchase Pattern
```dart
// Standard purchase button implementation
Widget _buildPurchaseSection() {
  if (isCheckingAccess) return CircularProgressIndicator();
  
  if (hasAccess) {
    return _buildAccessGrantedUI(); // Green checkmark, access message
  } else {
    return _buildPurchaseUI(); // Orange lock, purchase button with price
  }
}
```

#### Error Handling Philosophy
- **Service Layer**: Return null/defaults rather than throwing exceptions
- **UI Layer**: Check mounted state before setState to prevent memory leaks
- **Purchase Flow**: Two-step confirmation with detailed error messages
- **Access Verification**: Multiple validation layers (service + database + UI)

### Code Quality and Testing
Always run these commands before committing:
```bash
flutter analyze          # Static analysis and linting
flutter test             # Run all tests  
flutter pub deps         # Check dependency issues
```

The project uses `package:flutter_lints/flutter.yaml` rules as configured in `analysis_options.yaml`.