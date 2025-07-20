-- =============================================
-- CORGI AI EDU - Complete Database Migration
-- =============================================
-- This migration extends the existing users table and adds
-- the complete purchasing, points, and discussion system
-- Run this script in your Supabase SQL Editor

BEGIN;

-- =============================================
-- Step 1: Extend existing users table
-- =============================================

-- Add missing columns to existing users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS total_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Update full_name from name if it doesn't exist
UPDATE public.users SET full_name = name WHERE full_name IS NULL;

-- Make full_name NOT NULL after populating it
ALTER TABLE public.users ALTER COLUMN full_name SET NOT NULL;

-- =============================================
-- Step 2: Create course structure tables
-- =============================================

-- Courses table
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    difficulty VARCHAR(50) NOT NULL CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
    estimated_time VARCHAR(100) NOT NULL,
    image_url TEXT,
    video_preview_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Modules table
CREATE TABLE IF NOT EXISTS public.modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    order_index INTEGER NOT NULL,
    image_url TEXT,
    video_preview_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(course_id, order_index)
);

-- Lessons table
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    order_index INTEGER NOT NULL,
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('video', 'text', 'interactive')),
    content_url TEXT,
    duration_minutes INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(module_id, order_index)
);

-- Final Projects table (both course and module level)
CREATE TABLE IF NOT EXISTS public.final_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    points_reward INTEGER NOT NULL DEFAULT 0,
    requirements TEXT[],
    submission_format VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (
        (course_id IS NOT NULL AND module_id IS NULL) OR 
        (course_id IS NULL AND module_id IS NOT NULL)
    )
);

-- Homework table (for lessons)
CREATE TABLE IF NOT EXISTS public.homework (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    points_reward INTEGER NOT NULL DEFAULT 0,
    requirements TEXT[],
    submission_format VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- Step 3: Create purchase system tables
-- =============================================

-- Purchase types enum
DO $$ BEGIN
    CREATE TYPE purchase_type AS ENUM ('course', 'module', 'lesson');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Purchases table
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    purchase_type purchase_type NOT NULL,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    transaction_id VARCHAR(255),
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    CHECK (
        (purchase_type = 'course' AND course_id IS NOT NULL AND module_id IS NULL AND lesson_id IS NULL) OR
        (purchase_type = 'module' AND course_id IS NULL AND module_id IS NOT NULL AND lesson_id IS NULL) OR
        (purchase_type = 'lesson' AND course_id IS NULL AND module_id IS NULL AND lesson_id IS NOT NULL)
    )
);

-- User progress tracking
CREATE TABLE IF NOT EXISTS public.user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    progress_type VARCHAR(50) NOT NULL CHECK (progress_type IN ('lesson_completed', 'homework_submitted', 'module_completed', 'course_completed', 'final_project_submitted')),
    progress_percentage DECIMAL(5,2) DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- Step 4: Create discussion system tables
-- =============================================

-- Discussion groups table
CREATE TABLE IF NOT EXISTS public.discussion_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (
        (course_id IS NOT NULL AND module_id IS NULL AND lesson_id IS NULL) OR
        (course_id IS NULL AND module_id IS NOT NULL AND lesson_id IS NULL) OR
        (course_id IS NULL AND module_id IS NULL AND lesson_id IS NOT NULL)
    )
);

-- Discussion posts table
CREATE TABLE IF NOT EXISTS public.discussion_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discussion_group_id UUID NOT NULL REFERENCES public.discussion_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    parent_post_id UUID REFERENCES public.discussion_posts(id) ON DELETE CASCADE,
    title VARCHAR(255),
    content TEXT NOT NULL,
    is_question BOOLEAN DEFAULT false,
    is_answer BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    useful_votes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Post votes table (for useful marking)
CREATE TABLE IF NOT EXISTS public.post_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.discussion_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_useful BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- =============================================
-- Step 5: Create points and achievements tables
-- =============================================

-- Points transactions table
CREATE TABLE IF NOT EXISTS public.points_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('homework_completed', 'final_project_completed', 'useful_post', 'course_completed', 'module_completed', 'achievement')),
    reference_id UUID, -- Can reference homework, final_project, post, etc.
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievements table
CREATE TABLE IF NOT EXISTS public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(255) NOT NULL,
    description TEXT,
    points_awarded INTEGER DEFAULT 0,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- Step 6: Create indexes for performance
-- =============================================

-- Purchases indexes
CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON public.purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_course_id ON public.purchases(course_id);
CREATE INDEX IF NOT EXISTS idx_purchases_module_id ON public.purchases(module_id);
CREATE INDEX IF NOT EXISTS idx_purchases_lesson_id ON public.purchases(lesson_id);
CREATE INDEX IF NOT EXISTS idx_purchases_status ON public.purchases(payment_status);

-- Progress indexes
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON public.user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_lesson_id ON public.user_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_module_id ON public.user_progress(module_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_course_id ON public.user_progress(course_id);

-- Discussion indexes
CREATE INDEX IF NOT EXISTS idx_discussion_posts_group_id ON public.discussion_posts(discussion_group_id);
CREATE INDEX IF NOT EXISTS idx_discussion_posts_user_id ON public.discussion_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_posts_parent_id ON public.discussion_posts(parent_post_id);
CREATE INDEX IF NOT EXISTS idx_discussion_posts_created_at ON public.discussion_posts(created_at);

-- Votes indexes
CREATE INDEX IF NOT EXISTS idx_post_votes_post_id ON public.post_votes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_votes_user_id ON public.post_votes(user_id);

-- Points indexes
CREATE INDEX IF NOT EXISTS idx_points_transactions_user_id ON public.points_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_points_transactions_type ON public.points_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_points_transactions_created_at ON public.points_transactions(created_at);

-- =============================================
-- Step 7: Create functions and triggers
-- =============================================

-- Function to update user total points
CREATE OR REPLACE FUNCTION public.update_user_total_points()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.users 
        SET total_points = total_points + NEW.points
        WHERE id = NEW.user_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.users 
        SET total_points = total_points - OLD.points
        WHERE id = OLD.user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update user points
DROP TRIGGER IF EXISTS trigger_update_user_points ON public.points_transactions;
CREATE TRIGGER trigger_update_user_points
    AFTER INSERT OR DELETE ON public.points_transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_total_points();

-- Function to update post useful votes count
CREATE OR REPLACE FUNCTION public.update_post_useful_votes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.discussion_posts 
        SET useful_votes = useful_votes + (CASE WHEN NEW.is_useful THEN 1 ELSE 0 END)
        WHERE id = NEW.post_id;
        
        -- Award points to post author if marked as useful
        IF NEW.is_useful THEN
            INSERT INTO public.points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, 5, 'useful_post', NEW.post_id, 'Post marked as useful'
            FROM public.discussion_posts dp
            WHERE dp.id = NEW.post_id;
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.discussion_posts 
        SET useful_votes = useful_votes + (CASE WHEN NEW.is_useful THEN 1 ELSE 0 END) - (CASE WHEN OLD.is_useful THEN 1 ELSE 0 END)
        WHERE id = NEW.post_id;
        
        -- Handle points for useful post changes
        IF NEW.is_useful AND NOT OLD.is_useful THEN
            INSERT INTO public.points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, 5, 'useful_post', NEW.post_id, 'Post marked as useful'
            FROM public.discussion_posts dp
            WHERE dp.id = NEW.post_id;
        ELSIF NOT NEW.is_useful AND OLD.is_useful THEN
            INSERT INTO public.points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, -5, 'useful_post', NEW.post_id, 'Useful marking removed'
            FROM public.discussion_posts dp
            WHERE dp.id = NEW.post_id;
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.discussion_posts 
        SET useful_votes = useful_votes - (CASE WHEN OLD.is_useful THEN 1 ELSE 0 END)
        WHERE id = OLD.post_id;
        
        -- Remove points if useful vote is deleted
        IF OLD.is_useful THEN
            INSERT INTO public.points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, -5, 'useful_post', OLD.post_id, 'Useful vote removed'
            FROM public.discussion_posts dp
            WHERE dp.id = OLD.post_id;
        END IF;
        
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update post votes
DROP TRIGGER IF EXISTS trigger_update_post_votes ON public.post_votes;
CREATE TRIGGER trigger_update_post_votes
    AFTER INSERT OR UPDATE OR DELETE ON public.post_votes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_post_useful_votes();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update updated_at timestamps
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_courses_updated_at ON public.courses;
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON public.courses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_modules_updated_at ON public.modules;
CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON public.modules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_lessons_updated_at ON public.lessons;
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON public.lessons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_final_projects_updated_at ON public.final_projects;
CREATE TRIGGER update_final_projects_updated_at BEFORE UPDATE ON public.final_projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_homework_updated_at ON public.homework;
CREATE TRIGGER update_homework_updated_at BEFORE UPDATE ON public.homework FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_progress_updated_at ON public.user_progress;
CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE ON public.user_progress FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_discussion_groups_updated_at ON public.discussion_groups;
CREATE TRIGGER update_discussion_groups_updated_at BEFORE UPDATE ON public.discussion_groups FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_discussion_posts_updated_at ON public.discussion_posts;
CREATE TRIGGER update_discussion_posts_updated_at BEFORE UPDATE ON public.discussion_posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- Step 8: Advanced database functions
-- =============================================

-- Function to get leaderboard for a specific time period
CREATE OR REPLACE FUNCTION public.get_leaderboard_for_period(
    start_date TIMESTAMP WITH TIME ZONE,
    limit_count INTEGER DEFAULT 100
)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    avatar_url TEXT,
    period_points BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.full_name,
        u.avatar_url,
        COALESCE(SUM(pt.points), 0) as period_points
    FROM public.users u
    LEFT JOIN public.points_transactions pt ON u.id = pt.user_id 
        AND pt.created_at >= start_date
    GROUP BY u.id, u.full_name, u.avatar_url
    ORDER BY period_points DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to a course
CREATE OR REPLACE FUNCTION public.user_has_course_access(
    user_uuid UUID,
    course_uuid UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.purchases 
        WHERE user_id = user_uuid 
        AND course_id = course_uuid 
        AND purchase_type = 'course'
        AND payment_status = 'completed'
    );
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to a module
CREATE OR REPLACE FUNCTION public.user_has_module_access(
    user_uuid UUID,
    module_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    course_uuid UUID;
BEGIN
    -- Check direct module purchase
    IF EXISTS (
        SELECT 1 FROM public.purchases 
        WHERE user_id = user_uuid 
        AND module_id = module_uuid 
        AND purchase_type = 'module'
        AND payment_status = 'completed'
    ) THEN
        RETURN TRUE;
    END IF;
    
    -- Check course purchase
    SELECT course_id INTO course_uuid 
    FROM public.modules 
    WHERE id = module_uuid;
    
    RETURN public.user_has_course_access(user_uuid, course_uuid);
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to a lesson
CREATE OR REPLACE FUNCTION public.user_has_lesson_access(
    user_uuid UUID,
    lesson_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    module_uuid UUID;
BEGIN
    -- Check direct lesson purchase
    IF EXISTS (
        SELECT 1 FROM public.purchases 
        WHERE user_id = user_uuid 
        AND lesson_id = lesson_uuid 
        AND purchase_type = 'lesson'
        AND payment_status = 'completed'
    ) THEN
        RETURN TRUE;
    END IF;
    
    -- Check module access
    SELECT module_id INTO module_uuid 
    FROM public.lessons 
    WHERE id = lesson_uuid;
    
    RETURN public.user_has_module_access(user_uuid, module_uuid);
END;
$$ LANGUAGE plpgsql;

-- Function to get user's progress summary
CREATE OR REPLACE FUNCTION public.get_user_progress_summary(
    user_uuid UUID
)
RETURNS TABLE (
    total_courses_purchased INTEGER,
    total_modules_purchased INTEGER,
    total_lessons_purchased INTEGER,
    total_lessons_completed INTEGER,
    total_homework_completed INTEGER,
    total_final_projects_completed INTEGER,
    total_points INTEGER,
    total_useful_posts INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM public.purchases WHERE user_id = user_uuid AND purchase_type = 'course' AND payment_status = 'completed') as total_courses_purchased,
        (SELECT COUNT(*)::INTEGER FROM public.purchases WHERE user_id = user_uuid AND purchase_type = 'module' AND payment_status = 'completed') as total_modules_purchased,
        (SELECT COUNT(*)::INTEGER FROM public.purchases WHERE user_id = user_uuid AND purchase_type = 'lesson' AND payment_status = 'completed') as total_lessons_purchased,
        (SELECT COUNT(*)::INTEGER FROM public.user_progress WHERE user_id = user_uuid AND progress_type = 'lesson_completed') as total_lessons_completed,
        (SELECT COUNT(*)::INTEGER FROM public.user_progress WHERE user_id = user_uuid AND progress_type = 'homework_submitted') as total_homework_completed,
        (SELECT COUNT(*)::INTEGER FROM public.user_progress WHERE user_id = user_uuid AND progress_type = 'final_project_submitted') as total_final_projects_completed,
        (SELECT total_points FROM public.users WHERE id = user_uuid) as total_points,
        (SELECT COUNT(*)::INTEGER FROM public.discussion_posts dp JOIN public.post_votes pv ON dp.id = pv.post_id WHERE dp.user_id = user_uuid AND pv.is_useful = true) as total_useful_posts;
END;
$$ LANGUAGE plpgsql;

-- Function to award achievement
CREATE OR REPLACE FUNCTION public.award_achievement(
    user_uuid UUID,
    achievement_type_param VARCHAR(50),
    achievement_name_param VARCHAR(255),
    description_param TEXT,
    points_param INTEGER DEFAULT 0
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user already has this achievement
    IF EXISTS (
        SELECT 1 FROM public.user_achievements 
        WHERE user_id = user_uuid 
        AND achievement_type = achievement_type_param
        AND achievement_name = achievement_name_param
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Award the achievement
    INSERT INTO public.user_achievements (
        user_id, 
        achievement_type, 
        achievement_name, 
        description, 
        points_awarded
    ) VALUES (
        user_uuid, 
        achievement_type_param, 
        achievement_name_param, 
        description_param, 
        points_param
    );
    
    -- Award points if any
    IF points_param > 0 THEN
        INSERT INTO public.points_transactions (
            user_id, 
            points, 
            transaction_type, 
            reference_id, 
            description
        ) VALUES (
            user_uuid, 
            points_param, 
            'achievement', 
            NULL, 
            'Achievement: ' || achievement_name_param
        );
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to check and award automatic achievements
CREATE OR REPLACE FUNCTION public.check_and_award_achievements(
    user_uuid UUID
)
RETURNS VOID AS $$
DECLARE
    user_stats RECORD;
BEGIN
    -- Get user statistics
    SELECT * INTO user_stats FROM public.get_user_progress_summary(user_uuid);
    
    -- First Course Achievement
    IF user_stats.total_courses_purchased >= 1 THEN
        PERFORM public.award_achievement(
            user_uuid,
            'course_purchase',
            'First Course',
            'Purchased your first course',
            25
        );
    END IF;
    
    -- Course Collector Achievement
    IF user_stats.total_courses_purchased >= 5 THEN
        PERFORM public.award_achievement(
            user_uuid,
            'course_purchase',
            'Course Collector',
            'Purchased 5 courses',
            100
        );
    END IF;
    
    -- Helpful Student Achievement
    IF user_stats.total_useful_posts >= 10 THEN
        PERFORM public.award_achievement(
            user_uuid,
            'community',
            'Helpful Student',
            'Received 10 useful votes on posts',
            50
        );
    END IF;
    
    -- Homework Hero Achievement
    IF user_stats.total_homework_completed >= 20 THEN
        PERFORM public.award_achievement(
            user_uuid,
            'progress',
            'Homework Hero',
            'Completed 20 homework assignments',
            75
        );
    END IF;
    
    -- Project Master Achievement
    IF user_stats.total_final_projects_completed >= 5 THEN
        PERFORM public.award_achievement(
            user_uuid,
            'progress',
            'Project Master',
            'Completed 5 final projects',
            150
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check achievements after points transaction
CREATE OR REPLACE FUNCTION public.trigger_check_achievements()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.check_and_award_achievements(NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_achievement_check ON public.points_transactions;
CREATE TRIGGER trigger_achievement_check
    AFTER INSERT ON public.points_transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_check_achievements();

-- =============================================
-- Step 9: Enable Row Level Security (RLS)
-- =============================================

-- Enable RLS on all new tables
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.final_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discussion_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discussion_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- =============================================
-- Step 10: Create RLS policies
-- =============================================

-- Courses, modules, lessons are publicly readable
CREATE POLICY "Courses are publicly readable" ON public.courses FOR SELECT USING (is_active = true);
CREATE POLICY "Modules are publicly readable" ON public.modules FOR SELECT USING (is_active = true);
CREATE POLICY "Lessons are publicly readable" ON public.lessons FOR SELECT USING (is_active = true);
CREATE POLICY "Final projects are publicly readable" ON public.final_projects FOR SELECT USING (is_active = true);
CREATE POLICY "Homework is publicly readable" ON public.homework FOR SELECT USING (is_active = true);

-- Users can only see their own purchases
CREATE POLICY "Users can view own purchases" ON public.purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own purchases" ON public.purchases FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only see their own progress
CREATE POLICY "Users can view own progress" ON public.user_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own progress" ON public.user_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON public.user_progress FOR UPDATE USING (auth.uid() = user_id);

-- Discussion groups are publicly readable
CREATE POLICY "Discussion groups are publicly readable" ON public.discussion_groups FOR SELECT USING (is_active = true);

-- Discussion posts are publicly readable
CREATE POLICY "Discussion posts are publicly readable" ON public.discussion_posts FOR SELECT USING (true);
CREATE POLICY "Users can create posts" ON public.discussion_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON public.discussion_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON public.discussion_posts FOR DELETE USING (auth.uid() = user_id);

-- Post votes
CREATE POLICY "Users can view all votes" ON public.post_votes FOR SELECT USING (true);
CREATE POLICY "Users can create own votes" ON public.post_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own votes" ON public.post_votes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own votes" ON public.post_votes FOR DELETE USING (auth.uid() = user_id);

-- Points transactions
CREATE POLICY "Users can view own points transactions" ON public.points_transactions FOR SELECT USING (auth.uid() = user_id);

-- User achievements
CREATE POLICY "Users can view own achievements" ON public.user_achievements FOR SELECT USING (auth.uid() = user_id);

-- =============================================
-- Step 11: Grant permissions
-- =============================================

-- Grant permissions for all new tables
GRANT ALL ON public.courses TO authenticated;
GRANT ALL ON public.modules TO authenticated;
GRANT ALL ON public.lessons TO authenticated;
GRANT ALL ON public.final_projects TO authenticated;
GRANT ALL ON public.homework TO authenticated;
GRANT ALL ON public.purchases TO authenticated;
GRANT ALL ON public.user_progress TO authenticated;
GRANT ALL ON public.discussion_groups TO authenticated;
GRANT ALL ON public.discussion_posts TO authenticated;
GRANT ALL ON public.post_votes TO authenticated;
GRANT ALL ON public.points_transactions TO authenticated;
GRANT ALL ON public.user_achievements TO authenticated;

GRANT ALL ON public.courses TO service_role;
GRANT ALL ON public.modules TO service_role;
GRANT ALL ON public.lessons TO service_role;
GRANT ALL ON public.final_projects TO service_role;
GRANT ALL ON public.homework TO service_role;
GRANT ALL ON public.purchases TO service_role;
GRANT ALL ON public.user_progress TO service_role;
GRANT ALL ON public.discussion_groups TO service_role;
GRANT ALL ON public.discussion_posts TO service_role;
GRANT ALL ON public.post_votes TO service_role;
GRANT ALL ON public.points_transactions TO service_role;
GRANT ALL ON public.user_achievements TO service_role;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.get_leaderboard_for_period TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_has_course_access TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_has_module_access TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_has_lesson_access TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_progress_summary TO authenticated;
GRANT EXECUTE ON FUNCTION public.award_achievement TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_and_award_achievements TO authenticated;

COMMIT;

-- =============================================
-- VERIFICATION QUERIES
-- =============================================
-- Run these to verify everything is working:

-- 1. Check if all tables exist
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- 2. Check user table structure
-- SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position;

-- 3. Check RLS policies
-- SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename;

-- 4. Check functions
-- SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';

-- 5. Check triggers
-- SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public';

-- =============================================
-- SAMPLE DATA INSERTION (Optional)
-- =============================================
-- Uncomment and run the following to insert sample data:

/*
-- Insert sample course
INSERT INTO public.courses (title, description, price, difficulty, estimated_time) VALUES 
('Introduction to AI', 'Learn the fundamentals of artificial intelligence', 29.99, 'Beginner', '4 weeks');

-- Insert sample module (you'll need the course_id from above)
-- INSERT INTO public.modules (course_id, title, description, price, order_index) VALUES 
-- ('[COURSE_ID]', 'What is AI?', 'Understanding AI basics', 4.99, 1);

-- Insert sample lesson (you'll need the module_id from above)
-- INSERT INTO public.lessons (module_id, title, description, price, order_index, content_type) VALUES 
-- ('[MODULE_ID]', 'Introduction to AI', 'Basic AI concepts', 0.99, 1, 'video');
*/