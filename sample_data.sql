-- =============================================
-- CORGI AI EDU - Sample Data for Testing
-- =============================================
-- Run this to insert sample data for testing the app

BEGIN;

-- Insert sample courses
INSERT INTO public.courses (id, title, description, price, difficulty, estimated_time, image_url, video_preview_url) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'Introduction to AI', 'Learn the fundamentals of artificial intelligence and how it''s changing our world', 29.99, 'Beginner', '4 weeks', 'assets/ai_intro.png', 'assets/ai_intro_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440002', 'Machine Learning Basics', 'Understand the core concepts of machine learning algorithms and techniques', 49.99, 'Intermediate', '6 weeks', 'assets/ml_basics.png', 'assets/ml_basics_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440003', 'Deep Learning Fundamentals', 'Dive into neural networks and deep learning architectures', 79.99, 'Advanced', '8 weeks', 'assets/dl_fundamentals.png', 'assets/dl_fundamentals_preview.mp4')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  difficulty = EXCLUDED.difficulty,
  estimated_time = EXCLUDED.estimated_time,
  image_url = EXCLUDED.image_url,
  video_preview_url = EXCLUDED.video_preview_url;

-- Insert sample modules for Introduction to AI course
INSERT INTO public.modules (id, course_id, title, description, price, order_index, image_url, video_preview_url) VALUES 
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440001', 'What is AI?', 'Understanding artificial intelligence basics and fundamental concepts', 4.99, 1, 'assets/module_1_1.png', 'assets/module_1_1_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440001', 'History of AI', 'Journey through AI development from early concepts to modern breakthroughs', 3.99, 2, 'assets/module_1_2.png', 'assets/module_1_2_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440001', 'AI Applications', 'Real-world AI implementations across various industries and sectors', 5.99, 3, 'assets/module_1_3.png', 'assets/module_1_3_preview.mp4')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  order_index = EXCLUDED.order_index,
  image_url = EXCLUDED.image_url,
  video_preview_url = EXCLUDED.video_preview_url;

-- Insert sample modules for Machine Learning course
INSERT INTO public.modules (id, course_id, title, description, price, order_index, image_url, video_preview_url) VALUES 
('550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440002', 'Supervised Learning', 'Learn supervised learning algorithms and their applications', 9.99, 1, 'assets/module_2_1.png', 'assets/module_2_1_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440002', 'Unsupervised Learning', 'Explore unsupervised learning techniques and clustering methods', 8.99, 2, 'assets/module_2_2.png', 'assets/module_2_2_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440002', 'Model Evaluation', 'Techniques for evaluating ML models and performance metrics', 6.99, 3, 'assets/module_2_3.png', 'assets/module_2_3_preview.mp4')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  order_index = EXCLUDED.order_index,
  image_url = EXCLUDED.image_url,
  video_preview_url = EXCLUDED.video_preview_url;

-- Insert sample modules for Deep Learning course
INSERT INTO public.modules (id, course_id, title, description, price, order_index, image_url, video_preview_url) VALUES 
('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440003', 'Neural Networks', 'Understanding neural network fundamentals and architectures', 12.99, 1, 'assets/module_3_1.png', 'assets/module_3_1_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440003', 'CNNs & Computer Vision', 'Convolutional Neural Networks for image processing', 11.99, 2, 'assets/module_3_2.png', 'assets/module_3_2_preview.mp4'),
('550e8400-e29b-41d4-a716-446655440033', '550e8400-e29b-41d4-a716-446655440003', 'RNNs & Sequence Models', 'Recurrent Neural Networks for sequential data', 10.99, 3, 'assets/module_3_3.png', 'assets/module_3_3_preview.mp4')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  order_index = EXCLUDED.order_index,
  image_url = EXCLUDED.image_url,
  video_preview_url = EXCLUDED.video_preview_url;

-- Insert sample lessons for "What is AI?" module
INSERT INTO public.lessons (id, module_id, title, description, price, order_index, content_type, content_url, duration_minutes) VALUES 
('550e8400-e29b-41d4-a716-446655440111', '550e8400-e29b-41d4-a716-446655440011', 'Introduction to AI', 'Basic concepts and terminology of artificial intelligence', 0.99, 1, 'video', 'assets/lessons/1-1-1.mp4', 15),
('550e8400-e29b-41d4-a716-446655440112', '550e8400-e29b-41d4-a716-446655440011', 'Types of AI', 'Understanding different categories of AI systems', 0.99, 2, 'video', 'assets/lessons/1-1-2.mp4', 18),
('550e8400-e29b-41d4-a716-446655440113', '550e8400-e29b-41d4-a716-446655440011', 'AI vs Machine Learning', 'Distinguishing between AI and machine learning', 0.99, 3, 'video', 'assets/lessons/1-1-3.mp4', 20),
('550e8400-e29b-41d4-a716-446655440114', '550e8400-e29b-41d4-a716-446655440011', 'AI in Daily Life', 'Examples of AI applications in everyday scenarios', 0.99, 4, 'video', 'assets/lessons/1-1-4.mp4', 22),
('550e8400-e29b-41d4-a716-446655440115', '550e8400-e29b-41d4-a716-446655440011', 'Future of AI', 'Exploring the potential and challenges of AI development', 1.01, 5, 'video', 'assets/lessons/1-1-5.mp4', 25)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  order_index = EXCLUDED.order_index,
  content_type = EXCLUDED.content_type,
  content_url = EXCLUDED.content_url,
  duration_minutes = EXCLUDED.duration_minutes;

-- Insert sample homework for lessons
INSERT INTO public.homework (id, lesson_id, title, description, points_reward, requirements, submission_format) VALUES 
('550e8400-e29b-41d4-a716-446655441111', '550e8400-e29b-41d4-a716-446655440111', 'AI Concepts Quiz', 'Complete the quiz about basic AI concepts', 10, ARRAY['Watch the video', 'Complete 10 questions'], 'online_quiz'),
('550e8400-e29b-41d4-a716-446655441112', '550e8400-e29b-41d4-a716-446655440112', 'AI Types Classification', 'Classify different AI systems by type', 10, ARRAY['Watch the video', 'Complete classification exercise'], 'online_exercise'),
('550e8400-e29b-41d4-a716-446655441113', '550e8400-e29b-41d4-a716-446655440113', 'AI vs ML Comparison', 'Create a comparison chart between AI and ML', 15, ARRAY['Watch the video', 'Create comparison chart', 'Submit as PDF'], 'file_upload')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  points_reward = EXCLUDED.points_reward,
  requirements = EXCLUDED.requirements,
  submission_format = EXCLUDED.submission_format;

-- Insert sample final projects
INSERT INTO public.final_projects (id, course_id, module_id, title, description, price, points_reward, requirements, submission_format) VALUES 
('550e8400-e29b-41d4-a716-446655442001', '550e8400-e29b-41d4-a716-446655440001', NULL, 'AI Innovation Project', 'Create a comprehensive AI project proposal', 9.99, 100, ARRAY['Complete all modules', 'Research AI application', 'Create project proposal', 'Present to peers'], 'presentation'),
('550e8400-e29b-41d4-a716-446655442011', NULL, '550e8400-e29b-41d4-a716-446655440011', 'AI Identification Challenge', 'Create a presentation identifying AI systems in your environment', 2.99, 50, ARRAY['Complete all module lessons', 'Identify 10 AI systems in daily life', 'Create a 10-slide presentation', 'Include real-world examples'], 'presentation'),
('550e8400-e29b-41d4-a716-446655442012', NULL, '550e8400-e29b-41d4-a716-446655440012', 'AI Timeline Project', 'Create a comprehensive timeline of AI development milestones', 2.99, 50, ARRAY['Complete all module lessons', 'Research AI history', 'Create interactive timeline', 'Include major milestones'], 'interactive_media')
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  points_reward = EXCLUDED.points_reward,
  requirements = EXCLUDED.requirements,
  submission_format = EXCLUDED.submission_format;

-- Insert sample discussion groups
INSERT INTO public.discussion_groups (id, course_id, module_id, lesson_id, name, description) VALUES 
('550e8400-e29b-41d4-a716-446655443001', '550e8400-e29b-41d4-a716-446655440001', NULL, NULL, 'Introduction to AI - Course Discussion', 'General discussion for the entire Introduction to AI course'),
('550e8400-e29b-41d4-a716-446655443011', NULL, '550e8400-e29b-41d4-a716-446655440011', NULL, 'What is AI? - Module Discussion', 'Discussion for the What is AI? module'),
('550e8400-e29b-41d4-a716-446655443111', NULL, NULL, '550e8400-e29b-41d4-a716-446655440111', 'Introduction to AI - Lesson Discussion', 'Discussion for the Introduction to AI lesson')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

COMMIT;

-- =============================================
-- Verification Query
-- =============================================
-- Run this to verify the data was inserted correctly

SELECT 
  'Courses' as table_name,
  COUNT(*) as count
FROM public.courses
WHERE is_active = true

UNION ALL

SELECT 
  'Modules' as table_name,
  COUNT(*) as count
FROM public.modules
WHERE is_active = true

UNION ALL

SELECT 
  'Lessons' as table_name,
  COUNT(*) as count
FROM public.lessons
WHERE is_active = true

UNION ALL

SELECT 
  'Final Projects' as table_name,
  COUNT(*) as count
FROM public.final_projects
WHERE is_active = true

UNION ALL

SELECT 
  'Homework' as table_name,
  COUNT(*) as count
FROM public.homework
WHERE is_active = true

UNION ALL

SELECT 
  'Discussion Groups' as table_name,
  COUNT(*) as count
FROM public.discussion_groups
WHERE is_active = true;