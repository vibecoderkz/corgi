import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_assistant_models.dart';
import '../services/ai_assistant_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AIAssistantSession _currentSession;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _hasText = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Design constants
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color userMessageColor = Color(0xFF6366F1);
  static const Color assistantMessageColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
  }

  void _initializeChat() {
    _currentSession = AIAssistantService.createNewSession();
    
    // Listen to text changes
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
    
    setState(() {
      _isInitialized = true;
    });
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _currentSession = _currentSession.copyWith(
        messages: [..._currentSession.messages, userMessage],
        updatedAt: DateTime.now(),
      );
    });

    _messageController.clear();
    _scrollToBottom();

    // Add loading message
    final loadingMessage = ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content: 'Думаю...',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _currentSession = _currentSession.copyWith(
        messages: [..._currentSession.messages, loadingMessage],
      );
    });

    _scrollToBottom();

    try {
      // Send message to AI
      final response = await AIAssistantService.sendMessage(
        userMessage: message,
        conversationHistory: _currentSession.messages
            .where((msg) => !msg.isLoading)
            .toList(),
      );

      setState(() {
        // Remove loading message
        final messagesWithoutLoading = _currentSession.messages
            .where((msg) => !msg.isLoading)
            .toList();

        if (response != null) {
          _currentSession = _currentSession.copyWith(
            messages: [...messagesWithoutLoading, response],
            updatedAt: DateTime.now(),
          );
        } else {
          final errorMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Извините, произошла ошибка. Попробуйте еще раз.',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          );
          _currentSession = _currentSession.copyWith(
            messages: [...messagesWithoutLoading, errorMessage],
            updatedAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      setState(() {
        final messagesWithoutLoading = _currentSession.messages
            .where((msg) => !msg.isLoading)
            .toList();
        
        final errorMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Произошла ошибка подключения. Проверьте интернет и попробуйте снова.',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        );
        
        _currentSession = _currentSession.copyWith(
          messages: [...messagesWithoutLoading, errorMessage],
          updatedAt: DateTime.now(),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  void _startNewChat() {
    setState(() {
      _currentSession = AIAssistantService.createNewSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildChatArea(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.psychology, color: primaryColor),
          SizedBox(width: 8),
          Text(
            'ИИ-Помощник',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: primaryColor),
          onPressed: _startNewChat,
          tooltip: 'Новый чат',
        ),
      ],
    );
  }

  Widget _buildChatArea() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _currentSession.messages.isEmpty
            ? _buildWelcomeScreen()
            : _buildMessagesList(),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final suggestedQuestions = AIAssistantService.getSuggestedQuestions();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.psychology,
              size: 64,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Добро пожаловать в ИИ-Помощник!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Я помогу вам изучать искусственный интеллект, машинное обучение и науку о данных. Задавайте любые вопросы!',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Популярные вопросы:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...suggestedQuestions.take(4).map((question) => _buildSuggestedQuestion(question)),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestion(String question) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _sendSuggestedQuestion(question),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _currentSession.messages.length,
      itemBuilder: (context, index) {
        final message = _currentSession.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final isLoading = message.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? userMessageColor : assistantMessageColor,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    _buildTypingIndicator()
                  else
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : textPrimary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  if (!isLoading) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: isUser ? Colors.white70 : textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser ? userMessageColor : primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.psychology,
        color: isUser ? Colors.white : primaryColor,
        size: 20,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++) ...[
          _buildTypingDot(i),
          if (i < 2) const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final animationValue = (_fadeController.value + index * 0.3) % 1.0;
        return Opacity(
          opacity: (0.3 + 0.7 * (1 - (animationValue - 0.5).abs() * 2)).clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Напишите ваш вопрос...',
                    hintStyle: TextStyle(color: textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hasText && !_isLoading
                    ? primaryColor
                    : textSecondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}