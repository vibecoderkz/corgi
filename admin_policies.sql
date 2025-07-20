-- =============================================
-- ADMIN POLICIES FOR COURSE MANAGEMENT
-- =============================================
-- Run this to add admin policies for course creation and management

BEGIN;

-- =============================================
-- Add admin-specific RLS policies
-- =============================================

-- Admin users can create courses
CREATE POLICY "Admins can create courses" ON public.courses 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can update courses
CREATE POLICY "Admins can update courses" ON public.courses 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can delete courses
CREATE POLICY "Admins can delete courses" ON public.courses 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can create modules
CREATE POLICY "Admins can create modules" ON public.modules 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can update modules
CREATE POLICY "Admins can update modules" ON public.modules 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can delete modules
CREATE POLICY "Admins can delete modules" ON public.modules 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can create lessons
CREATE POLICY "Admins can create lessons" ON public.lessons 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can update lessons
CREATE POLICY "Admins can update lessons" ON public.lessons 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can delete lessons
CREATE POLICY "Admins can delete lessons" ON public.lessons 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can create homework
CREATE POLICY "Admins can create homework" ON public.homework 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can update homework
CREATE POLICY "Admins can update homework" ON public.homework 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can delete homework
CREATE POLICY "Admins can delete homework" ON public.homework 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can create final projects
CREATE POLICY "Admins can create final projects" ON public.final_projects 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can update final projects
CREATE POLICY "Admins can update final projects" ON public.final_projects 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can delete final projects
CREATE POLICY "Admins can delete final projects" ON public.final_projects 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Admin users can manage discussion groups
CREATE POLICY "Admins can create discussion groups" ON public.discussion_groups 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update discussion groups" ON public.discussion_groups 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete discussion groups" ON public.discussion_groups 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- =============================================
-- Helper functions for admin operations
-- =============================================

-- Function to check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get course with edit permissions
CREATE OR REPLACE FUNCTION public.get_course_for_admin(course_uuid UUID)
RETURNS TABLE (
  id UUID,
  title VARCHAR(255),
  description TEXT,
  price DECIMAL(10,2),
  difficulty VARCHAR(50),
  estimated_time VARCHAR(100),
  image_url TEXT,
  video_preview_url TEXT,
  is_active BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  -- Check if user is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;

  RETURN QUERY
  SELECT 
    c.id,
    c.title,
    c.description,
    c.price,
    c.difficulty,
    c.estimated_time,
    c.image_url,
    c.video_preview_url,
    c.is_active,
    c.created_at,
    c.updated_at
  FROM public.courses c
  WHERE c.id = course_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create discussion group automatically when content is created
CREATE OR REPLACE FUNCTION public.create_discussion_group_for_content()
RETURNS TRIGGER AS $$
BEGIN
  -- Create discussion group for course
  IF TG_TABLE_NAME = 'courses' THEN
    INSERT INTO public.discussion_groups (course_id, name, description)
    VALUES (NEW.id, NEW.title || ' - Course Discussion', 'General discussion for ' || NEW.title);
  
  -- Create discussion group for module
  ELSIF TG_TABLE_NAME = 'modules' THEN
    INSERT INTO public.discussion_groups (module_id, name, description)
    VALUES (NEW.id, NEW.title || ' - Module Discussion', 'Discussion for the ' || NEW.title || ' module');
  
  -- Create discussion group for lesson
  ELSIF TG_TABLE_NAME = 'lessons' THEN
    INSERT INTO public.discussion_groups (lesson_id, name, description)
    VALUES (NEW.id, NEW.title || ' - Lesson Discussion', 'Discussion for the ' || NEW.title || ' lesson');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically create discussion groups
DROP TRIGGER IF EXISTS create_course_discussion_group ON public.courses;
CREATE TRIGGER create_course_discussion_group
  AFTER INSERT ON public.courses
  FOR EACH ROW
  EXECUTE FUNCTION public.create_discussion_group_for_content();

DROP TRIGGER IF EXISTS create_module_discussion_group ON public.modules;
CREATE TRIGGER create_module_discussion_group
  AFTER INSERT ON public.modules
  FOR EACH ROW
  EXECUTE FUNCTION public.create_discussion_group_for_content();

DROP TRIGGER IF EXISTS create_lesson_discussion_group ON public.lessons;
CREATE TRIGGER create_lesson_discussion_group
  AFTER INSERT ON public.lessons
  FOR EACH ROW
  EXECUTE FUNCTION public.create_discussion_group_for_content();

-- Grant execute permissions on admin functions
GRANT EXECUTE ON FUNCTION public.is_admin TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_course_for_admin TO authenticated;

COMMIT;

-- =============================================
-- Test admin user creation (optional)
-- =============================================
-- Uncomment and modify to create a test admin user
-- UPDATE public.users SET role = 'admin' WHERE email = 'your-admin-email@example.com';