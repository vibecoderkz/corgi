import 'package:flutter/material.dart';
import '../models/main_page_models.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/course_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Data
  bool _isLoading = true;
  String _error = '';
  UserStats? _userStats;
  List<Map<String, dynamic>> _recentActivities = [];
  
  // Interactive states
  bool _isCoursesPressed = false;
  bool _isLessonsPressed = false;
  bool _isContinueLearningPressed = false;

  // Design constants
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const coursesGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );

  static const lessonsGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const backgroundColor = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);

  static const cardBorderRadius = 16.0;
  static const cardPadding = 20.0;
  static const sectionSpacing = 30.0;
  static const cardSpacing = 16.0;

  static const cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 25,
      offset: Offset(0, 8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final results = await Future.wait([
        UserService.getUserStats(),
        _getRecentActivities(),
      ]);

      if (mounted) {
        setState(() {
          _userStats = results[0] as UserStats?;
          _recentActivities = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    // Return empty list since points/transactions are removed
    return <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildGradientHeader(),
                        const SizedBox(height: sectionSpacing),
                        _buildProgressSection(),
                        const SizedBox(height: sectionSpacing),
                        _buildQuickActions(),
                        const SizedBox(height: sectionSpacing),
                        _buildRecentActivity(),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBar(),
              const SizedBox(height: 20),
              _buildWelcomeSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          timeString,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: const [
            Icon(Icons.signal_cellular_4_bar, color: Colors.white70, size: 18),
            SizedBox(width: 4),
            Icon(Icons.wifi, color: Colors.white70, size: 18),
            SizedBox(width: 4),
            Icon(Icons.battery_full, color: Colors.white70, size: 18),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Добро пожаловать!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Продолжайте свое обучение',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return _buildAnimatedSection(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("📈", "Ваш прогресс"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard(
                    icon: "🎓",
                    value: "${_userStats?.coursesCompleted ?? 0}/${_userStats?.totalCourses ?? 4}",
                    label: "Курсы",
                    gradient: coursesGradient,
                    isPressed: _isCoursesPressed,
                    onTapDown: () => setState(() => _isCoursesPressed = true),
                    onTapUp: () => setState(() => _isCoursesPressed = false),
                    onTapCancel: () => setState(() => _isCoursesPressed = false),
                  ),
                ),
                const SizedBox(width: cardSpacing),
                Expanded(
                  child: _buildProgressCard(
                    icon: "📚",
                    value: "${_userStats?.lessonsCompleted ?? 7}",
                    label: "Уроки",
                    gradient: lessonsGradient,
                    isPressed: _isLessonsPressed,
                    onTapDown: () => setState(() => _isLessonsPressed = true),
                    onTapUp: () => setState(() => _isLessonsPressed = false),
                    onTapCancel: () => setState(() => _isLessonsPressed = false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return _buildAnimatedSection(
      delay: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("⚡", "Быстрые действия"),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: "▶️",
              title: "Continue Learning",
              gradient: coursesGradient,
              isPressed: _isContinueLearningPressed,
              onTapDown: () => setState(() => _isContinueLearningPressed = true),
              onTapUp: () => setState(() => _isContinueLearningPressed = false),
              onTapCancel: () => setState(() => _isContinueLearningPressed = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return _buildAnimatedSection(
      delay: 400,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("🕐", "Последняя активность"),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(cardPadding * 1.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cardBorderRadius),
                boxShadow: cardShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Пока нет активности',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Начните изучать курсы, чтобы увидеть активность здесь',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required Widget child, int delay = 0}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final delayedAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              delay / 800.0,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        );

        return FadeTransition(
          opacity: delayedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(delayedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String icon, String title) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required String icon,
    required String value,
    required String label,
    required Gradient gradient,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(cardBorderRadius),
            boxShadow: cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Reduced from 20 to 12
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 28), // Reduced from 32 to 28
                ),
                const SizedBox(height: 6), // Reduced from 8 to 6
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18, // Reduced from 20 to 18
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4 to 2
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12, // Reduced from 14 to 12
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String icon,
    required String title,
    required Gradient gradient,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(cardBorderRadius),
            boxShadow: cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(cardPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}