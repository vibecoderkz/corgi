-- =============================================
-- Points Configuration and Currency System
-- =============================================

-- Currency configuration table
CREATE TABLE currency_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code VARCHAR(10) NOT NULL UNIQUE, -- KZ, RU, US, DEFAULT, etc.
    currency_code VARCHAR(3) NOT NULL, -- KZT, RUB, USD
    currency_symbol VARCHAR(5) NOT NULL, -- ₸, ₽, $
    points_per_currency DECIMAL(10,4) NOT NULL DEFAULT 1.0, -- How many points equal 1 unit of currency
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Points configuration table for different activities
CREATE TABLE points_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_type VARCHAR(50) NOT NULL UNIQUE CHECK (activity_type IN (
        'homework_completed',
        'final_project_completed',
        'module_completed',
        'course_completed',
        'useful_post',
        'daily_login',
        'achievement_earned',
        'referral_bonus'
    )),
    base_points INTEGER NOT NULL DEFAULT 0,
    multiplier DECIMAL(5,2) DEFAULT 1.0, -- For special events or promotions
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Points spending configuration
CREATE TABLE points_spending_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    spending_type VARCHAR(50) NOT NULL UNIQUE CHECK (spending_type IN (
        'course_discount',
        'module_discount',
        'lesson_discount',
        'max_discount_percentage'
    )),
    value DECIMAL(10,2) NOT NULL, -- Percentage for discounts, absolute value for max
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Points spending transactions (separate from earning transactions)
CREATE TABLE points_spending (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points_spent INTEGER NOT NULL CHECK (points_spent > 0),
    spending_type VARCHAR(50) NOT NULL,
    purchase_id UUID REFERENCES purchases(id) ON DELETE SET NULL,
    currency_code VARCHAR(3) NOT NULL,
    currency_value DECIMAL(10,2) NOT NULL, -- How much money value was saved
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User currency preferences
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    preferred_currency VARCHAR(3) DEFAULT 'USD',
    country_code VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- Initial Data
-- =============================================

-- Insert default currency configurations
INSERT INTO currency_config (country_code, currency_code, currency_symbol, points_per_currency) VALUES
('KZ', 'KZT', '₸', 0.1), -- 1 KZT = 0.1 points (10 KZT = 1 point)
('RU', 'RUB', '₽', 1.0), -- 1 RUB = 1 point
('US', 'USD', '$', 100.0), -- 1 USD = 100 points
('DEFAULT', 'USD', '$', 100.0); -- Default for other countries

-- Insert default points configuration
INSERT INTO points_config (activity_type, base_points) VALUES
('homework_completed', 10), -- Default, actual value from homework table
('final_project_completed', 50), -- Default, actual value from final_projects table
('module_completed', 50),
('course_completed', 100),
('useful_post', 5),
('daily_login', 2),
('achievement_earned', 20),
('referral_bonus', 100);

-- Insert default spending configuration
INSERT INTO points_spending_config (spending_type, value) VALUES
('course_discount', 10.0), -- 10% discount on courses
('module_discount', 15.0), -- 15% discount on modules
('lesson_discount', 20.0), -- 20% discount on lessons
('max_discount_percentage', 50.0); -- Maximum 50% discount allowed

-- =============================================
-- Functions
-- =============================================

-- Function to get user's currency configuration
CREATE OR REPLACE FUNCTION get_user_currency_config(user_uuid UUID)
RETURNS TABLE (
    currency_code VARCHAR(3),
    currency_symbol VARCHAR(5),
    points_per_currency DECIMAL(10,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cc.currency_code,
        cc.currency_symbol,
        cc.points_per_currency
    FROM currency_config cc
    LEFT JOIN user_preferences up ON up.user_id = user_uuid
    WHERE cc.country_code = COALESCE(up.country_code, 'DEFAULT')
        AND cc.is_active = true
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate points value in user's currency
CREATE OR REPLACE FUNCTION calculate_points_value(
    points_amount INTEGER,
    user_uuid UUID
) RETURNS JSONB AS $$
DECLARE
    config RECORD;
    currency_value DECIMAL(10,2);
BEGIN
    -- Get user's currency configuration
    SELECT * INTO config FROM get_user_currency_config(user_uuid);
    
    -- Calculate currency value
    currency_value := points_amount / config.points_per_currency;
    
    RETURN jsonb_build_object(
        'points', points_amount,
        'currency_code', config.currency_code,
        'currency_symbol', config.currency_symbol,
        'currency_value', currency_value,
        'formatted_value', config.currency_symbol || ' ' || currency_value
    );
END;
$$ LANGUAGE plpgsql;

-- Function to calculate maximum discount for a purchase
CREATE OR REPLACE FUNCTION calculate_max_discount(
    purchase_type purchase_type,
    original_price DECIMAL(10,2),
    user_points INTEGER,
    user_uuid UUID
) RETURNS JSONB AS $$
DECLARE
    discount_config RECORD;
    max_discount_config RECORD;
    config RECORD;
    max_points_to_use INTEGER;
    discount_percentage DECIMAL(5,2);
    max_discount_amount DECIMAL(10,2);
    points_value DECIMAL(10,2);
    actual_discount DECIMAL(10,2);
BEGIN
    -- Get discount configuration
    SELECT * INTO discount_config 
    FROM points_spending_config 
    WHERE spending_type = purchase_type::text || '_discount'
        AND is_active = true;
    
    -- Get max discount configuration
    SELECT * INTO max_discount_config 
    FROM points_spending_config 
    WHERE spending_type = 'max_discount_percentage'
        AND is_active = true;
    
    -- Get user's currency configuration
    SELECT * INTO config FROM get_user_currency_config(user_uuid);
    
    -- Calculate maximum discount amount based on percentage limits
    discount_percentage := LEAST(
        COALESCE(discount_config.value, 0),
        COALESCE(max_discount_config.value, 50)
    );
    
    max_discount_amount := original_price * (discount_percentage / 100);
    
    -- Calculate how many points needed for max discount
    max_points_to_use := CEIL(max_discount_amount * config.points_per_currency);
    
    -- Limit by user's available points
    max_points_to_use := LEAST(max_points_to_use, user_points);
    
    -- Calculate actual discount amount
    actual_discount := max_points_to_use / config.points_per_currency;
    
    RETURN jsonb_build_object(
        'max_points_to_use', max_points_to_use,
        'discount_amount', actual_discount,
        'discount_percentage', ROUND((actual_discount / original_price) * 100, 2),
        'final_price', original_price - actual_discount,
        'currency_code', config.currency_code,
        'currency_symbol', config.currency_symbol
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Triggers
-- =============================================

-- Trigger to update user total points when spending
CREATE OR REPLACE FUNCTION update_user_points_on_spending()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Decrease user points
        UPDATE users 
        SET total_points = total_points - NEW.points_spent
        WHERE id = NEW.user_id;
        
        -- Also log in points_transactions as negative
        INSERT INTO points_transactions (
            user_id,
            points,
            transaction_type,
            reference_id,
            description
        ) VALUES (
            NEW.user_id,
            -NEW.points_spent,
            'points_spent',
            NEW.purchase_id,
            NEW.description
        );
        
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_points_on_spending
    AFTER INSERT ON points_spending
    FOR EACH ROW
    EXECUTE FUNCTION update_user_points_on_spending();

-- Update triggers for timestamps
CREATE TRIGGER update_currency_config_updated_at BEFORE UPDATE ON currency_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_points_config_updated_at BEFORE UPDATE ON points_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_points_spending_config_updated_at BEFORE UPDATE ON points_spending_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- Indexes
-- =============================================

CREATE INDEX idx_points_spending_user_id ON points_spending(user_id);
CREATE INDEX idx_points_spending_purchase_id ON points_spending(purchase_id);
CREATE INDEX idx_points_spending_created_at ON points_spending(created_at);
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

-- =============================================
-- Row Level Security
-- =============================================

ALTER TABLE currency_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_spending_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_spending ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Currency and points config are publicly readable
CREATE POLICY "Currency config is publicly readable" ON currency_config FOR SELECT USING (is_active = true);
CREATE POLICY "Points config is publicly readable" ON points_config FOR SELECT USING (is_active = true);
CREATE POLICY "Spending config is publicly readable" ON points_spending_config FOR SELECT USING (is_active = true);

-- Users can only see their own spending
CREATE POLICY "Users can view own points spending" ON points_spending FOR SELECT USING (auth.uid() = user_id);

-- Users can manage their own preferences
CREATE POLICY "Users can view own preferences" ON user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own preferences" ON user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON user_preferences FOR UPDATE USING (auth.uid() = user_id);