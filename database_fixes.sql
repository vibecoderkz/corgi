-- =============================================
-- Database Fixes for Points System
-- =============================================

-- Add missing role field to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'admin'));

-- Add missing fields that might be referenced in the code
ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255);

-- Update existing users to have the role field
UPDATE users SET role = 'student' WHERE role IS NULL;

-- Update the users table to use full_name for display if name is not set
UPDATE users SET name = full_name WHERE name IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_total_points ON users(total_points);

-- Create a function to get user's total points (for backward compatibility)
CREATE OR REPLACE FUNCTION get_user_total_points(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT total_points
        FROM users
        WHERE id = user_uuid
    );
END;
$$ LANGUAGE plpgsql;

-- Create a function to check if user is admin
CREATE OR REPLACE FUNCTION is_user_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        SELECT CASE 
            WHEN role = 'admin' THEN TRUE 
            ELSE FALSE 
        END
        FROM users
        WHERE id = user_uuid
    );
END;
$$ LANGUAGE plpgsql;

-- Update RLS policies to work with the new role field
-- First, create a policy for admins to view all users
CREATE POLICY "Admins can view all users" ON users FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy for admins to update any user
CREATE POLICY "Admins can update any user" ON users FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Ensure courses, modules, and lessons have proper structure for points
-- Add points_reward to homework if not exists
ALTER TABLE homework ADD COLUMN IF NOT EXISTS points_reward INTEGER DEFAULT 10;

-- Add points_reward to final_projects if not exists (already exists in schema)
-- This is already present in the schema, so no need to add

-- Update any NULL points_reward values
UPDATE homework SET points_reward = 10 WHERE points_reward IS NULL;
UPDATE final_projects SET points_reward = 50 WHERE points_reward IS NULL;

-- Create a trigger to award points when homework is completed
CREATE OR REPLACE FUNCTION award_homework_points()
RETURNS TRIGGER AS $$
BEGIN
    -- Award points when homework is marked as completed
    IF NEW.progress_type = 'homework_submitted' AND NEW.completed_at IS NOT NULL THEN
        -- Get points from homework table
        INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
        SELECT 
            NEW.user_id,
            COALESCE(h.points_reward, 10),
            'homework_completed',
            NEW.id,
            'Homework completed: ' || h.title
        FROM homework h
        WHERE h.lesson_id = NEW.lesson_id;
    END IF;
    
    -- Award points when final project is completed
    IF NEW.progress_type = 'final_project_submitted' AND NEW.completed_at IS NOT NULL THEN
        -- Get points from final_projects table
        INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
        SELECT 
            NEW.user_id,
            COALESCE(fp.points_reward, 50),
            'final_project_completed',
            NEW.id,
            'Final project completed: ' || fp.title
        FROM final_projects fp
        WHERE (fp.course_id = NEW.course_id OR fp.module_id = NEW.module_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic points awarding
DROP TRIGGER IF EXISTS trigger_award_points ON user_progress;
CREATE TRIGGER trigger_award_points
    AFTER INSERT OR UPDATE ON user_progress
    FOR EACH ROW
    EXECUTE FUNCTION award_homework_points();

-- Create a function to award module completion bonus
CREATE OR REPLACE FUNCTION award_module_completion_bonus()
RETURNS TRIGGER AS $$
BEGIN
    -- Award bonus points when module is completed
    IF NEW.progress_type = 'module_completed' AND NEW.completed_at IS NOT NULL THEN
        -- Get points configuration
        INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
        SELECT 
            NEW.user_id,
            COALESCE(pc.base_points, 50),
            'module_completed',
            NEW.id,
            'Module completion bonus'
        FROM points_config pc
        WHERE pc.activity_type = 'module_completed'
        AND pc.is_active = true;
    END IF;
    
    -- Award bonus points when course is completed
    IF NEW.progress_type = 'course_completed' AND NEW.completed_at IS NOT NULL THEN
        -- Get points configuration
        INSERT INTO points_transactions (user_id, points, transaction_type, reference_id, description)
        SELECT 
            NEW.user_id,
            COALESCE(pc.base_points, 100),
            'course_completed',
            NEW.id,
            'Course completion bonus'
        FROM points_config pc
        WHERE pc.activity_type = 'course_completed'
        AND pc.is_active = true;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for module/course completion bonuses
DROP TRIGGER IF EXISTS trigger_award_completion_bonus ON user_progress;
CREATE TRIGGER trigger_award_completion_bonus
    AFTER INSERT OR UPDATE ON user_progress
    FOR EACH ROW
    EXECUTE FUNCTION award_module_completion_bonus();

-- Create a view for easy points tracking
CREATE OR REPLACE VIEW user_points_summary AS
SELECT 
    u.id,
    u.full_name,
    u.email,
    u.total_points,
    u.role,
    COALESCE(SUM(CASE WHEN pt.transaction_type = 'homework_completed' THEN pt.points ELSE 0 END), 0) as homework_points,
    COALESCE(SUM(CASE WHEN pt.transaction_type = 'final_project_completed' THEN pt.points ELSE 0 END), 0) as project_points,
    COALESCE(SUM(CASE WHEN pt.transaction_type = 'module_completed' THEN pt.points ELSE 0 END), 0) as module_bonus_points,
    COALESCE(SUM(CASE WHEN pt.transaction_type = 'course_completed' THEN pt.points ELSE 0 END), 0) as course_bonus_points,
    COALESCE(SUM(CASE WHEN pt.transaction_type = 'useful_post' THEN pt.points ELSE 0 END), 0) as discussion_points,
    COALESCE(SUM(CASE WHEN pt.transaction_type = 'points_spent' THEN ABS(pt.points) ELSE 0 END), 0) as points_spent
FROM users u
LEFT JOIN points_transactions pt ON u.id = pt.user_id
GROUP BY u.id, u.full_name, u.email, u.total_points, u.role;

-- Grant permissions for the view
GRANT SELECT ON user_points_summary TO authenticated;

-- Create RLS policy for the view
CREATE POLICY "Users can view own points summary" ON user_points_summary FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all points summary" ON user_points_summary FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Enable RLS on the view
ALTER VIEW user_points_summary ENABLE ROW LEVEL SECURITY;