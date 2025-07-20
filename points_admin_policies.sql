-- =============================================
-- Admin Policies for Points Configuration
-- =============================================

-- Admin policies for currency_config
CREATE POLICY "Admins can insert currency config" ON currency_config 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

CREATE POLICY "Admins can update currency config" ON currency_config 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

CREATE POLICY "Admins can delete currency config" ON currency_config 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Admin policies for points_config
CREATE POLICY "Admins can insert points config" ON points_config 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

CREATE POLICY "Admins can update points config" ON points_config 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

CREATE POLICY "Admins can delete points config" ON points_config 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Admin policies for points_spending_config
CREATE POLICY "Admins can insert spending config" ON points_spending_config 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

CREATE POLICY "Admins can update spending config" ON points_spending_config 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

CREATE POLICY "Admins can delete spending config" ON points_spending_config 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Admin policies for viewing all points spending (for analytics)
CREATE POLICY "Admins can view all points spending" ON points_spending 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Admin policies for viewing all user preferences
CREATE POLICY "Admins can view all user preferences" ON user_preferences 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);