-- =============================================
-- Complete Points System Setup
-- =============================================

-- First, run the main points configuration
\i points_configuration.sql

-- Then run these additional fixes
\i database_fixes.sql

-- Add sample data for testing
INSERT INTO points_config (activity_type, base_points, is_active) VALUES
('homework_completed', 10, true),
('final_project_completed', 50, true),
('module_completed', 50, true),
('course_completed', 100, true),
('useful_post', 5, true),
('daily_login', 2, true),
('achievement_earned', 20, true),
('referral_bonus', 100, true)
ON CONFLICT (activity_type) DO UPDATE SET
    base_points = EXCLUDED.base_points,
    is_active = EXCLUDED.is_active;

-- Add sample currency configurations
INSERT INTO currency_config (country_code, currency_code, currency_symbol, points_per_currency, is_active) VALUES
('KZ', 'KZT', '₸', 0.1, true),
('RU', 'RUB', '₽', 1.0, true),
('US', 'USD', '$', 100.0, true),
('DEFAULT', 'USD', '$', 100.0, true)
ON CONFLICT (country_code) DO UPDATE SET
    currency_code = EXCLUDED.currency_code,
    currency_symbol = EXCLUDED.currency_symbol,
    points_per_currency = EXCLUDED.points_per_currency,
    is_active = EXCLUDED.is_active;

-- Add sample spending configuration
INSERT INTO points_spending_config (spending_type, value, is_active) VALUES
('course_discount', 10.0, true),
('module_discount', 15.0, true),
('lesson_discount', 20.0, true),
('max_discount_percentage', 50.0, true)
ON CONFLICT (spending_type) DO UPDATE SET
    value = EXCLUDED.value,
    is_active = EXCLUDED.is_active;

-- Create a comprehensive function for awarding points
CREATE OR REPLACE FUNCTION award_activity_points(
    p_user_id UUID,
    p_activity_type VARCHAR(50),
    p_reference_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    points_to_award INTEGER;
    config_record RECORD;
BEGIN
    -- Get points configuration for this activity
    SELECT base_points, multiplier INTO config_record
    FROM points_config
    WHERE activity_type = p_activity_type
    AND is_active = true;
    
    -- Calculate points with multiplier
    points_to_award := COALESCE(config_record.base_points, 0) * COALESCE(config_record.multiplier, 1.0);
    
    -- Insert points transaction
    INSERT INTO points_transactions (
        user_id,
        points,
        transaction_type,
        reference_id,
        description
    ) VALUES (
        p_user_id,
        points_to_award,
        p_activity_type,
        p_reference_id,
        COALESCE(p_description, 'Points awarded for ' || p_activity_type)
    );
    
    RETURN points_to_award;
END;
$$ LANGUAGE plpgsql;

-- Create function to check if user has enough points for spending
CREATE OR REPLACE FUNCTION can_spend_points(
    p_user_id UUID,
    p_points_to_spend INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    user_points INTEGER;
BEGIN
    SELECT total_points INTO user_points
    FROM users
    WHERE id = p_user_id;
    
    RETURN COALESCE(user_points, 0) >= p_points_to_spend;
END;
$$ LANGUAGE plpgsql;

-- Create function to spend points
CREATE OR REPLACE FUNCTION spend_user_points(
    p_user_id UUID,
    p_points_to_spend INTEGER,
    p_purchase_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    user_points INTEGER;
    currency_config RECORD;
    currency_value DECIMAL(10,2);
BEGIN
    -- Check if user has enough points
    IF NOT can_spend_points(p_user_id, p_points_to_spend) THEN
        RETURN FALSE;
    END IF;
    
    -- Get user's currency configuration
    SELECT cc.currency_code, cc.points_per_currency INTO currency_config
    FROM currency_config cc
    LEFT JOIN user_preferences up ON up.country_code = cc.country_code AND up.user_id = p_user_id
    WHERE cc.is_active = true
    ORDER BY (up.user_id IS NOT NULL) DESC, cc.country_code = 'DEFAULT' DESC
    LIMIT 1;
    
    -- Calculate currency value
    currency_value := p_points_to_spend / COALESCE(currency_config.points_per_currency, 100.0);
    
    -- Insert spending record
    INSERT INTO points_spending (
        user_id,
        points_spent,
        spending_type,
        purchase_id,
        currency_code,
        currency_value,
        description
    ) VALUES (
        p_user_id,
        p_points_to_spend,
        'purchase_discount',
        p_purchase_id,
        COALESCE(currency_config.currency_code, 'USD'),
        currency_value,
        COALESCE(p_description, 'Points spent on purchase')
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create comprehensive leaderboard function
CREATE OR REPLACE FUNCTION get_points_leaderboard(
    p_limit INTEGER DEFAULT 10,
    p_period VARCHAR(20) DEFAULT 'all_time'
) RETURNS TABLE (
    user_id UUID,
    full_name VARCHAR(255),
    email VARCHAR(255),
    total_points INTEGER,
    rank INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.full_name,
        u.email,
        u.total_points,
        ROW_NUMBER() OVER (ORDER BY u.total_points DESC)::INTEGER as rank
    FROM users u
    WHERE u.role != 'admin'
    ORDER BY u.total_points DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Create function to get user's points history
CREATE OR REPLACE FUNCTION get_user_points_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20
) RETURNS TABLE (
    transaction_date TIMESTAMP WITH TIME ZONE,
    transaction_type VARCHAR(50),
    points INTEGER,
    description TEXT,
    reference_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.created_at,
        pt.transaction_type,
        pt.points,
        pt.description,
        pt.reference_id
    FROM points_transactions pt
    WHERE pt.user_id = p_user_id
    ORDER BY pt.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Create function to get points analytics for admin
CREATE OR REPLACE FUNCTION get_points_analytics()
RETURNS TABLE (
    metric VARCHAR(50),
    value BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'total_points_awarded'::VARCHAR(50), SUM(points)::BIGINT
    FROM points_transactions
    WHERE points > 0
    
    UNION ALL
    
    SELECT 'total_points_spent'::VARCHAR(50), SUM(points_spent)::BIGINT
    FROM points_spending
    
    UNION ALL
    
    SELECT 'active_users_with_points'::VARCHAR(50), COUNT(DISTINCT id)::BIGINT
    FROM users
    WHERE total_points > 0
    
    UNION ALL
    
    SELECT 'total_transactions'::VARCHAR(50), COUNT(*)::BIGINT
    FROM points_transactions;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION award_activity_points(UUID, VARCHAR(50), UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION can_spend_points(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION spend_user_points(UUID, INTEGER, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_points_leaderboard(INTEGER, VARCHAR(20)) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_points_history(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_points_analytics() TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_points_transactions_user_created ON points_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_points_transactions_type ON points_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_points_spending_user_created ON points_spending(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_country ON user_preferences(user_id, country_code);

-- Final verification queries
DO $$
BEGIN
    RAISE NOTICE 'Points system setup complete!';
    RAISE NOTICE 'Tables created: currency_config, points_config, points_spending_config, points_spending, user_preferences';
    RAISE NOTICE 'Functions created: award_activity_points, can_spend_points, spend_user_points, get_points_leaderboard, get_user_points_history, get_points_analytics';
    RAISE NOTICE 'Triggers created: automatic points awarding for homework/projects/completions';
    RAISE NOTICE 'Ready to use!';
END;
$$;