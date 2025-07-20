-- =============================================
-- AI Education Platform Database Schema
-- =============================================

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    total_points INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Courses table
CREATE TABLE courses (
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
CREATE TABLE modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
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
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
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
CREATE TABLE final_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
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
CREATE TABLE homework (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    points_reward INTEGER NOT NULL DEFAULT 0,
    requirements TEXT[],
    submission_format VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Purchase types enum
CREATE TYPE purchase_type AS ENUM ('course', 'module', 'lesson');

-- Purchases table
CREATE TABLE purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purchase_type purchase_type NOT NULL,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
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
CREATE TABLE user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    progress_type VARCHAR(50) NOT NULL CHECK (progress_type IN ('lesson_completed', 'homework_submitted', 'module_completed', 'course_completed', 'final_project_submitted')),
    progress_percentage DECIMAL(5,2) DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Discussion groups table
CREATE TABLE discussion_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
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
CREATE TABLE discussion_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discussion_group_id UUID NOT NULL REFERENCES discussion_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_post_id UUID REFERENCES discussion_posts(id) ON DELETE CASCADE,
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
CREATE TABLE post_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES discussion_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_useful BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Points transactions table
CREATE TABLE points_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('homework_completed', 'final_project_completed', 'useful_post', 'course_completed', 'achievement')),
    reference_id UUID, -- Can reference homework, final_project, post, etc.
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievements table
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(255) NOT NULL,
    description TEXT,
    points_awarded INTEGER DEFAULT 0,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- INDEXES for performance
-- =============================================

-- Purchases indexes
CREATE INDEX idx_purchases_user_id ON purchases(user_id);
CREATE INDEX idx_purchases_course_id ON purchases(course_id);
CREATE INDEX idx_purchases_module_id ON purchases(module_id);
CREATE INDEX idx_purchases_lesson_id ON purchases(lesson_id);
CREATE INDEX idx_purchases_status ON purchases(payment_status);

-- Progress indexes
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_lesson_id ON user_progress(lesson_id);
CREATE INDEX idx_user_progress_module_id ON user_progress(module_id);
CREATE INDEX idx_user_progress_course_id ON user_progress(course_id);

-- Discussion indexes
CREATE INDEX idx_discussion_posts_group_id ON discussion_posts(discussion_group_id);
CREATE INDEX idx_discussion_posts_user_id ON discussion_posts(user_id);
CREATE INDEX idx_discussion_posts_parent_id ON discussion_posts(parent_post_id);
CREATE INDEX idx_discussion_posts_created_at ON discussion_posts(created_at);

-- Votes indexes
CREATE INDEX idx_post_votes_post_id ON post_votes(post_id);
CREATE INDEX idx_post_votes_user_id ON post_votes(user_id);

-- Points indexes
CREATE INDEX idx_points_transactions_user_id ON points_transactions(user_id);
CREATE INDEX idx_points_transactions_type ON points_transactions(transaction_type);
CREATE INDEX idx_points_transactions_created_at ON points_transactions(created_at);

-- =============================================
-- FUNCTIONS AND TRIGGERS
-- =============================================

-- Function to update user total points
CREATE OR REPLACE FUNCTION update_user_total_points()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE users 
        SET total_points = total_points + NEW.points
        WHERE id = NEW.user_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE users 
        SET total_points = total_points - OLD.points
        WHERE id = OLD.user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update user points
CREATE TRIGGER trigger_update_user_points
    AFTER INSERT OR DELETE ON points_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_total_points();

-- Function to update post useful votes count
CREATE OR REPLACE FUNCTION update_post_useful_votes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE discussion_posts 
        SET useful_votes = useful_votes + (CASE WHEN NEW.is_useful THEN 1 ELSE 0 END)
        WHERE id = NEW.post_id;
        
        -- Award points to post author if marked as useful
        IF NEW.is_useful THEN
            INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, 5, 'useful_post', NEW.post_id, 'Post marked as useful'
            FROM discussion_posts dp
            WHERE dp.id = NEW.post_id;
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE discussion_posts 
        SET useful_votes = useful_votes + (CASE WHEN NEW.is_useful THEN 1 ELSE 0 END) - (CASE WHEN OLD.is_useful THEN 1 ELSE 0 END)
        WHERE id = NEW.post_id;
        
        -- Handle points for useful post changes
        IF NEW.is_useful AND NOT OLD.is_useful THEN
            INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, 5, 'useful_post', NEW.post_id, 'Post marked as useful'
            FROM discussion_posts dp
            WHERE dp.id = NEW.post_id;
        ELSIF NOT NEW.is_useful AND OLD.is_useful THEN
            INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, -5, 'useful_post', NEW.post_id, 'Useful marking removed'
            FROM discussion_posts dp
            WHERE dp.id = NEW.post_id;
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE discussion_posts 
        SET useful_votes = useful_votes - (CASE WHEN OLD.is_useful THEN 1 ELSE 0 END)
        WHERE id = OLD.post_id;
        
        -- Remove points if useful vote is deleted
        IF OLD.is_useful THEN
            INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
            SELECT dp.user_id, -5, 'useful_post', OLD.post_id, 'Useful vote removed'
            FROM discussion_posts dp
            WHERE dp.id = OLD.post_id;
        END IF;
        
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update post votes
CREATE TRIGGER trigger_update_post_votes
    AFTER INSERT OR UPDATE OR DELETE ON post_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_useful_votes();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update updated_at timestamps
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON modules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_final_projects_updated_at BEFORE UPDATE ON final_projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_homework_updated_at BEFORE UPDATE ON homework FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE ON user_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_discussion_groups_updated_at BEFORE UPDATE ON discussion_groups FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_discussion_posts_updated_at BEFORE UPDATE ON discussion_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SECURITY POLICIES (Row Level Security)
-- =============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE final_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Users can only see and update their own profile
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Courses, modules, lessons are publicly readable
CREATE POLICY "Courses are publicly readable" ON courses FOR SELECT USING (is_active = true);
CREATE POLICY "Modules are publicly readable" ON modules FOR SELECT USING (is_active = true);
CREATE POLICY "Lessons are publicly readable" ON lessons FOR SELECT USING (is_active = true);
CREATE POLICY "Final projects are publicly readable" ON final_projects FOR SELECT USING (is_active = true);
CREATE POLICY "Homework is publicly readable" ON homework FOR SELECT USING (is_active = true);

-- Users can only see their own purchases
CREATE POLICY "Users can view own purchases" ON purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own purchases" ON purchases FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only see their own progress
CREATE POLICY "Users can view own progress" ON user_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own progress" ON user_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON user_progress FOR UPDATE USING (auth.uid() = user_id);

-- Discussion groups are publicly readable
CREATE POLICY "Discussion groups are publicly readable" ON discussion_groups FOR SELECT USING (is_active = true);

-- Discussion posts are publicly readable
CREATE POLICY "Discussion posts are publicly readable" ON discussion_posts FOR SELECT USING (true);
CREATE POLICY "Users can create posts" ON discussion_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON discussion_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON discussion_posts FOR DELETE USING (auth.uid() = user_id);

-- Post votes
CREATE POLICY "Users can view all votes" ON post_votes FOR SELECT USING (true);
CREATE POLICY "Users can create own votes" ON post_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own votes" ON post_votes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own votes" ON post_votes FOR DELETE USING (auth.uid() = user_id);

-- Points transactions
CREATE POLICY "Users can view own points transactions" ON points_transactions FOR SELECT USING (auth.uid() = user_id);

-- User achievements
CREATE POLICY "Users can view own achievements" ON user_achievements FOR SELECT USING (auth.uid() = user_id);