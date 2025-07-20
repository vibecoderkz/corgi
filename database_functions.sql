-- =============================================
-- Additional Database Functions
-- =============================================

-- Function to get leaderboard for a specific time period
CREATE OR REPLACE FUNCTION get_leaderboard_for_period(
    start_date TIMESTAMP WITH TIME ZONE,
    limit_count INTEGER DEFAULT 100
)
RETURNS TABLE (
    id UUID,
    full_name VARCHAR(255),
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
    FROM users u
    LEFT JOIN points_transactions pt ON u.id = pt.user_id 
        AND pt.created_at >= start_date
    GROUP BY u.id, u.full_name, u.avatar_url
    ORDER BY period_points DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to a course
CREATE OR REPLACE FUNCTION user_has_course_access(
    user_uuid UUID,
    course_uuid UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM purchases 
        WHERE user_id = user_uuid 
        AND course_id = course_uuid 
        AND purchase_type = 'course'
        AND payment_status = 'completed'
    );
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to a module
CREATE OR REPLACE FUNCTION user_has_module_access(
    user_uuid UUID,
    module_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    course_uuid UUID;
BEGIN
    -- Check direct module purchase
    IF EXISTS (
        SELECT 1 FROM purchases 
        WHERE user_id = user_uuid 
        AND module_id = module_uuid 
        AND purchase_type = 'module'
        AND payment_status = 'completed'
    ) THEN
        RETURN TRUE;
    END IF;
    
    -- Check course purchase
    SELECT course_id INTO course_uuid 
    FROM modules 
    WHERE id = module_uuid;
    
    RETURN user_has_course_access(user_uuid, course_uuid);
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to a lesson
CREATE OR REPLACE FUNCTION user_has_lesson_access(
    user_uuid UUID,
    lesson_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    module_uuid UUID;
BEGIN
    -- Check direct lesson purchase
    IF EXISTS (
        SELECT 1 FROM purchases 
        WHERE user_id = user_uuid 
        AND lesson_id = lesson_uuid 
        AND purchase_type = 'lesson'
        AND payment_status = 'completed'
    ) THEN
        RETURN TRUE;
    END IF;
    
    -- Check module access
    SELECT module_id INTO module_uuid 
    FROM lessons 
    WHERE id = lesson_uuid;
    
    RETURN user_has_module_access(user_uuid, module_uuid);
END;
$$ LANGUAGE plpgsql;

-- Function to get user's accessible discussion groups
CREATE OR REPLACE FUNCTION get_user_accessible_discussion_groups(
    user_uuid UUID
)
RETURNS TABLE (
    group_id UUID,
    group_name VARCHAR(255),
    group_description TEXT,
    access_level TEXT,
    parent_id UUID,
    parent_title VARCHAR(255)
) AS $$
BEGIN
    -- Course-level groups
    RETURN QUERY
    SELECT 
        dg.id as group_id,
        dg.name as group_name,
        dg.description as group_description,
        'course' as access_level,
        c.id as parent_id,
        c.title as parent_title
    FROM discussion_groups dg
    JOIN courses c ON dg.course_id = c.id
    WHERE dg.course_id IN (
        SELECT course_id FROM purchases 
        WHERE user_id = user_uuid 
        AND purchase_type = 'course' 
        AND payment_status = 'completed'
    )
    AND dg.is_active = true;
    
    -- Module-level groups (from course purchases)
    RETURN QUERY
    SELECT 
        dg.id as group_id,
        dg.name as group_name,
        dg.description as group_description,
        'module' as access_level,
        m.id as parent_id,
        m.title as parent_title
    FROM discussion_groups dg
    JOIN modules m ON dg.module_id = m.id
    WHERE m.course_id IN (
        SELECT course_id FROM purchases 
        WHERE user_id = user_uuid 
        AND purchase_type = 'course' 
        AND payment_status = 'completed'
    )
    AND dg.is_active = true;
    
    -- Module-level groups (from module purchases)
    RETURN QUERY
    SELECT 
        dg.id as group_id,
        dg.name as group_name,
        dg.description as group_description,
        'module' as access_level,
        m.id as parent_id,
        m.title as parent_title
    FROM discussion_groups dg
    JOIN modules m ON dg.module_id = m.id
    WHERE dg.module_id IN (
        SELECT module_id FROM purchases 
        WHERE user_id = user_uuid 
        AND purchase_type = 'module' 
        AND payment_status = 'completed'
    )
    AND dg.is_active = true;
    
    -- Lesson-level groups (from course purchases)
    RETURN QUERY
    SELECT 
        dg.id as group_id,
        dg.name as group_name,
        dg.description as group_description,
        'lesson' as access_level,
        l.id as parent_id,
        l.title as parent_title
    FROM discussion_groups dg
    JOIN lessons l ON dg.lesson_id = l.id
    JOIN modules m ON l.module_id = m.id
    WHERE m.course_id IN (
        SELECT course_id FROM purchases 
        WHERE user_id = user_uuid 
        AND purchase_type = 'course' 
        AND payment_status = 'completed'
    )
    AND dg.is_active = true;
    
    -- Lesson-level groups (from module purchases)
    RETURN QUERY
    SELECT 
        dg.id as group_id,
        dg.name as group_name,
        dg.description as group_description,
        'lesson' as access_level,
        l.id as parent_id,
        l.title as parent_title
    FROM discussion_groups dg
    JOIN lessons l ON dg.lesson_id = l.id
    WHERE l.module_id IN (
        SELECT module_id FROM purchases 
        WHERE user_id = user_uuid 
        AND purchase_type = 'module' 
        AND payment_status = 'completed'
    )
    AND dg.is_active = true;
    
    -- Lesson-level groups (from lesson purchases)
    RETURN QUERY
    SELECT 
        dg.id as group_id,
        dg.name as group_name,
        dg.description as group_description,
        'lesson' as access_level,
        l.id as parent_id,
        l.title as parent_title
    FROM discussion_groups dg
    JOIN lessons l ON dg.lesson_id = l.id
    WHERE dg.lesson_id IN (
        SELECT lesson_id FROM purchases 
        WHERE user_id = user_uuid 
        AND purchase_type = 'lesson' 
        AND payment_status = 'completed'
    )
    AND dg.is_active = true;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's progress summary
CREATE OR REPLACE FUNCTION get_user_progress_summary(
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
        (SELECT COUNT(*)::INTEGER FROM purchases WHERE user_id = user_uuid AND purchase_type = 'course' AND payment_status = 'completed') as total_courses_purchased,
        (SELECT COUNT(*)::INTEGER FROM purchases WHERE user_id = user_uuid AND purchase_type = 'module' AND payment_status = 'completed') as total_modules_purchased,
        (SELECT COUNT(*)::INTEGER FROM purchases WHERE user_id = user_uuid AND purchase_type = 'lesson' AND payment_status = 'completed') as total_lessons_purchased,
        (SELECT COUNT(*)::INTEGER FROM user_progress WHERE user_id = user_uuid AND progress_type = 'lesson_completed') as total_lessons_completed,
        (SELECT COUNT(*)::INTEGER FROM user_progress WHERE user_id = user_uuid AND progress_type = 'homework_submitted') as total_homework_completed,
        (SELECT COUNT(*)::INTEGER FROM user_progress WHERE user_id = user_uuid AND progress_type = 'final_project_submitted') as total_final_projects_completed,
        (SELECT total_points FROM users WHERE id = user_uuid) as total_points,
        (SELECT COUNT(*)::INTEGER FROM discussion_posts dp JOIN post_votes pv ON dp.id = pv.post_id WHERE dp.user_id = user_uuid AND pv.is_useful = true) as total_useful_posts;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate course completion percentage
CREATE OR REPLACE FUNCTION get_course_completion_percentage(
    user_uuid UUID,
    course_uuid UUID
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_lessons INTEGER;
    completed_lessons INTEGER;
BEGIN
    -- Get total lessons in the course
    SELECT COUNT(*) INTO total_lessons
    FROM lessons l
    JOIN modules m ON l.module_id = m.id
    WHERE m.course_id = course_uuid AND l.is_active = true;
    
    -- Get completed lessons
    SELECT COUNT(*) INTO completed_lessons
    FROM user_progress up
    JOIN lessons l ON up.lesson_id = l.id
    JOIN modules m ON l.module_id = m.id
    WHERE up.user_id = user_uuid 
    AND m.course_id = course_uuid 
    AND up.progress_type = 'lesson_completed';
    
    -- Calculate percentage
    IF total_lessons = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN (completed_lessons::DECIMAL / total_lessons::DECIMAL) * 100;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate module completion percentage
CREATE OR REPLACE FUNCTION get_module_completion_percentage(
    user_uuid UUID,
    module_uuid UUID
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_lessons INTEGER;
    completed_lessons INTEGER;
BEGIN
    -- Get total lessons in the module
    SELECT COUNT(*) INTO total_lessons
    FROM lessons
    WHERE module_id = module_uuid AND is_active = true;
    
    -- Get completed lessons
    SELECT COUNT(*) INTO completed_lessons
    FROM user_progress up
    JOIN lessons l ON up.lesson_id = l.id
    WHERE up.user_id = user_uuid 
    AND l.module_id = module_uuid 
    AND up.progress_type = 'lesson_completed';
    
    -- Calculate percentage
    IF total_lessons = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN (completed_lessons::DECIMAL / total_lessons::DECIMAL) * 100;
END;
$$ LANGUAGE plpgsql;

-- Function to get trending discussions (most active)
CREATE OR REPLACE FUNCTION get_trending_discussions(
    user_uuid UUID,
    days_back INTEGER DEFAULT 7,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    discussion_group_id UUID,
    group_name VARCHAR(255),
    posts_count BIGINT,
    recent_activity TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dg.id as discussion_group_id,
        dg.name as group_name,
        COUNT(dp.id) as posts_count,
        MAX(dp.created_at) as recent_activity
    FROM discussion_groups dg
    JOIN discussion_posts dp ON dg.id = dp.discussion_group_id
    WHERE dg.id IN (
        SELECT group_id FROM get_user_accessible_discussion_groups(user_uuid)
    )
    AND dp.created_at >= (NOW() - INTERVAL '%s days' % days_back)
    GROUP BY dg.id, dg.name
    HAVING COUNT(dp.id) > 0
    ORDER BY posts_count DESC, recent_activity DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to award achievement
CREATE OR REPLACE FUNCTION award_achievement(
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
        SELECT 1 FROM user_achievements 
        WHERE user_id = user_uuid 
        AND achievement_type = achievement_type_param
        AND achievement_name = achievement_name_param
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Award the achievement
    INSERT INTO user_achievements (
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
        INSERT INTO points_transactions (
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
CREATE OR REPLACE FUNCTION check_and_award_achievements(
    user_uuid UUID
)
RETURNS VOID AS $$
DECLARE
    user_stats RECORD;
BEGIN
    -- Get user statistics
    SELECT * INTO user_stats FROM get_user_progress_summary(user_uuid);
    
    -- First Course Achievement
    IF user_stats.total_courses_purchased >= 1 THEN
        PERFORM award_achievement(
            user_uuid,
            'course_purchase',
            'First Course',
            'Purchased your first course',
            25
        );
    END IF;
    
    -- Course Collector Achievement
    IF user_stats.total_courses_purchased >= 5 THEN
        PERFORM award_achievement(
            user_uuid,
            'course_purchase',
            'Course Collector',
            'Purchased 5 courses',
            100
        );
    END IF;
    
    -- Helpful Student Achievement
    IF user_stats.total_useful_posts >= 10 THEN
        PERFORM award_achievement(
            user_uuid,
            'community',
            'Helpful Student',
            'Received 10 useful votes on posts',
            50
        );
    END IF;
    
    -- Homework Hero Achievement
    IF user_stats.total_homework_completed >= 20 THEN
        PERFORM award_achievement(
            user_uuid,
            'progress',
            'Homework Hero',
            'Completed 20 homework assignments',
            75
        );
    END IF;
    
    -- Project Master Achievement
    IF user_stats.total_final_projects_completed >= 5 THEN
        PERFORM award_achievement(
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
CREATE OR REPLACE FUNCTION trigger_check_achievements()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM check_and_award_achievements(NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_achievement_check
    AFTER INSERT ON points_transactions
    FOR EACH ROW
    EXECUTE FUNCTION trigger_check_achievements();