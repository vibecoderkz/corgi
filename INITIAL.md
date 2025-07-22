# Project Requirements Plan (PRP) - Corgi AI Edu

## Executive Summary

**Project Name:** Corgi AI Edu  
**Type:** Mobile/Web Educational Platform  
**Technology Stack:** Flutter (Frontend), Supabase (Backend), PostgreSQL (Database)  
**Primary Purpose:** AI Education platform with gamified learning experience

### Vision Statement
Create a comprehensive AI education platform that combines structured learning paths, gamification elements, and community engagement to deliver an effective and engaging learning experience for students interested in artificial intelligence.

## Core Features & Requirements

### 1. User Management System

#### 1.1 Authentication & Authorization
- **Multi-role support:** Student, Teacher, Admin
- **Supabase Auth integration** with email/password authentication
- **Session management** with automatic token refresh
- **Role-based access control (RBAC)** at service and database levels

#### 1.2 User Profiles
- **Profile information:** Full name, email, avatar, city, birth date
- **Points tracking:** Total points with automatic calculation
- **Achievement system:** Unlockable achievements based on progress
- **Progress tracking:** Course/module/lesson completion statistics

### 2. Course Management System

#### 2.1 Hierarchical Content Structure
```
Courses
├── Modules (ordered)
│   ├── Lessons (ordered)
│   │   └── Homework (optional)
│   └── Final Projects
└── Final Projects (course-level)
```

#### 2.2 Content Features
- **Rich content types:** Video, text, interactive
- **Pricing tiers:** Course, module, or lesson-level purchases
- **Access control:** Hierarchical access (course purchase grants module/lesson access)
- **Progress tracking:** Automatic completion detection
- **Difficulty levels:** Beginner, Intermediate, Advanced

### 3. Gamification System

#### 3.1 Points System
- **Configurable points** via database (points_config table)
- **Activity rewards:**
  - Lesson completion: 5 points
  - Module completion: 50 points
  - Course completion: 100 points
  - Homework submission: 10 points
  - Final project: 50 points
  - Helpful discussion post: 5 points
- **Automatic point calculation** via database triggers
- **Points spending:** Use points for purchase discounts

#### 3.2 Achievements
- **Achievement types:** Course completion, milestones, community engagement
- **Automatic awarding** based on user actions
- **Visual badges** in user profile

#### 3.3 Leaderboard
- **Time-based filtering:** All-time, monthly, weekly, daily
- **Global rankings** based on total points
- **Profile integration** with avatar display

### 4. Discussion System

#### 4.1 Discussion Structure
- **Hierarchical discussions:** Tied to courses, modules, or lessons
- **Post types:** Questions, answers, general discussions
- **Threaded replies:** Parent-child comment structure
- **Helpful voting:** Community-driven quality signals

#### 4.2 Moderation Features
- **Admin controls:** Edit, delete, pin/unpin posts
- **User permissions:** Edit own posts, vote on others
- **Activity notifications:** New replies, helpful votes

### 5. Purchase System

#### 5.1 Flexible Purchasing
- **Purchase levels:** Course, module, or individual lesson
- **Payment methods:** Demo mode, card payments (future)
- **Points discount system:**
  - Course: 10% discount
  - Module: 15% discount  
  - Lesson: 20% discount
  - Maximum 50% discount cap

#### 5.2 Access Management
- **Hierarchical access:** Course purchase grants all child content
- **Database functions:** Efficient access checking
- **Purchase history:** Complete transaction records

### 6. Admin Dashboard

#### 6.1 Content Management
- **CRUD operations** for courses, modules, lessons
- **Drag-and-drop ordering** (via order_index)
- **Bulk operations** support
- **Real-time preview** of changes

#### 6.2 User Management
- **User statistics** and activity monitoring
- **Points management** and manual adjustments
- **Role assignment** capabilities

#### 6.3 Analytics
- **Platform statistics:** User count, course enrollments
- **Revenue tracking** (when payment integration added)
- **Engagement metrics:** Discussion activity, completion rates

## Technical Architecture

### Backend Architecture

#### Database Schema
- **26 tables** with comprehensive relationships
- **Row Level Security (RLS)** on all tables
- **Database triggers** for automatic calculations
- **Optimized functions** for complex queries

#### Key Database Components
1. **Users table:** Extended auth.users with profile data
2. **Courses/Modules/Lessons:** Hierarchical content structure
3. **Points system:** Transactions, config, spending
4. **Discussion system:** Groups, posts, votes, notifications
5. **Purchase system:** Flexible purchase tracking

### Frontend Architecture

#### Service Layer Pattern
```dart
// Singleton services with consistent patterns
- SupabaseService (base service)
- AuthService (authentication)
- CourseService (content management)
- UserService (profile/stats)
- PointsService (gamification)
- DiscussionService (community)
- PurchaseService (commerce)
- AdminService (admin operations)
```

#### State Management
- **Stateful widgets** for reactive UI
- **Service-based state** with singleton pattern
- **Optimistic updates** for better UX

#### UI/UX Design Principles
- **Material Design 3** compliance
- **Responsive layouts** for multiple screen sizes
- **Accessibility** considerations
- **Consistent color scheme** and theming

## Security & Performance

### Security Measures
1. **Two-tier security:** Service + database level
2. **RLS policies** enforcing access control
3. **Input validation** at all levels
4. **Secure credential storage** via .env files

### Performance Optimizations
1. **Database indexes** on frequently queried columns
2. **Efficient queries** with proper joins
3. **Lazy loading** for content lists
4. **Image optimization** and caching

## Integration Points

### Current Integrations
1. **Supabase:** Authentication, database, storage
2. **S3-compatible storage:** Via Supabase Storage API

### Planned Integrations
1. **OneSignal:** Push notifications (environment ready)
2. **Payment gateway:** Stripe/PayPal integration
3. **Analytics:** Google Analytics or Mixpanel
4. **Email service:** SendGrid for transactional emails

## Development Workflow

### Environment Setup
```bash
# Required environment variables
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
ONESIGNAL_APP_ID (ready for integration)
ONESIGNAL_REST_API_KEY
ONESIGNAL_USER_AUTH_KEY
```

### Database Setup Order
1. database_schema.sql
2. admin_policies.sql
3. discussion_system_schema.sql
4. points configuration
5. sample_data.sql (development only)

### Code Quality Standards
- **Flutter analyze:** Must pass before commits
- **Consistent naming:** followDartConventions()
- **Error handling:** Use safeExecute() pattern
- **Documentation:** Inline comments for complex logic

## Success Metrics

### User Engagement
- **Daily Active Users (DAU)**
- **Course completion rates**
- **Average session duration**
- **Discussion participation rate**

### Platform Growth
- **New user registrations**
- **Course enrollment numbers**
- **Revenue growth** (when monetized)
- **User retention rates**

### Learning Outcomes
- **Knowledge assessment scores**
- **Project completion quality**
- **Community helpfulness ratings**
- **Skill progression tracking**

## Future Enhancements

### Phase 2 Features
1. **AI-powered recommendations** for personalized learning paths
2. **Live sessions** with instructors
3. **Collaborative projects** between students
4. **Certificate generation** upon course completion

### Phase 3 Features
1. **Mobile offline mode** with content sync
2. **API for third-party integrations**
3. **White-label options** for organizations
4. **Advanced analytics dashboard**

## Risk Management

### Technical Risks
- **Scalability:** Supabase limits on free tier
- **Data security:** Regular security audits needed
- **Platform dependencies:** Flutter/Supabase updates

### Mitigation Strategies
- **Regular backups** of database
- **Load testing** before major releases
- **Gradual rollout** of new features
- **Monitoring and alerting** setup

## Conclusion

Corgi AI Edu is architected as a scalable, secure, and engaging educational platform. The combination of structured learning paths, gamification elements, and community features creates a comprehensive learning environment. The modular architecture allows for easy expansion and maintenance while maintaining high code quality and user experience standards.

The project is well-positioned for growth with clear integration points for future enhancements and a solid technical foundation built on modern technologies.