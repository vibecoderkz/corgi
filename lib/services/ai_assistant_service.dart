import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/ai_assistant_models.dart';
import 'supabase_service.dart';

class AIAssistantService {
  static final AIAssistantService _instance = AIAssistantService._internal();
  factory AIAssistantService() => _instance;
  AIAssistantService._internal();

  static String get _baseUrl => dotenv.env['DEEPSEEK_API_URL'] ?? 'https://api.deepseek.com/v1';
  static String get _apiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  // System prompt for the AI assistant specialized for your app
  static const String _systemPrompt = '''
Вы - ИИ-помощник для образовательной платформы Corgi AI Edu, специализирующейся на искусственном интеллекте и машинном обучении.

Ваши основные функции:
- Помощь студентам в изучении ИИ, машинного обучения и науки о данных
- Объяснение сложных концепций простым языком
- Помощь с домашними заданиями и проектами
- Рекомендации по курсам и материалам для изучения
- Ответы на вопросы о карьере в сфере ИИ
- Помощь в решении технических проблем с кодом

Стиль общения:
- Дружелюбный и поддерживающий
- Адаптируйтесь к уровню знаний студента
- Используйте примеры и аналогии для объяснения
- Предлагайте практические упражнения
- Отвечайте на русском языке, если не указано иное

Ограничения:
- Не выполняйте домашние задания полностью - направляйте к решению
- Не предоставляйте готовые ответы на экзамены
- При сложных вопросах предлагайте обратиться к преподавателю
- Сосредоточьтесь только на темах, связанных с ИИ и образованием

Помните: вы здесь, чтобы помочь студентам учиться и развиваться в области искусственного интеллекта!
''';

  /// Send a message to the AI assistant and get a response
  static Future<ChatMessage?> sendMessage({
    required String userMessage,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      // Prepare messages for API
      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': _systemPrompt},
      ];

      // Add conversation history (last 10 messages to keep context manageable)
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final recentHistory = conversationHistory
            .where((msg) => msg.role != MessageRole.system)
            .take(10)
            .toList();

        for (final message in recentHistory) {
          messages.add({
            'role': message.role.value,
            'content': message.content,
          });
        }
      }

      // Add the new user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Create API request
      final request = DeepSeekApiRequest(
        messages: messages,
        temperature: 0.7,
        maxTokens: 2048,
      );

      // Make API call
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final apiResponse = DeepSeekApiResponse.fromJson(responseData);

        if (apiResponse.choices.isNotEmpty) {
          final content = apiResponse.choices.first.message['content'] as String;
          
          return ChatMessage(
            id: _generateMessageId(),
            content: content.trim(),
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          );
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _createErrorMessage('Извините, произошла ошибка при обращении к ИИ-помощнику. Попробуйте еще раз.');
      }
    } catch (e) {
      print('AI Assistant Error: $e');
      return _createErrorMessage('Не удалось подключиться к ИИ-помощнику. Проверьте интернет-соединение.');
    }

    return null;
  }

  /// Get suggested questions for the AI assistant
  static List<String> getSuggestedQuestions() {
    return [
      'Что такое машинное обучение и как оно работает?',
      'Какие языки программирования лучше изучать для ИИ?',
      'Как начать карьеру в области искусственного интеллекта?',
      'Объясни разницу между supervised и unsupervised learning',
      'Какие проекты можно сделать для портфолио в сфере ИИ?',
      'Как работают нейронные сети?',
      'Что такое deep learning и чем он отличается от ML?',
      'Какие математические знания нужны для ИИ?',
    ];
  }

  /// Get conversation starters based on user's current course progress
  static List<String> getPersonalizedQuestions({
    String? currentCourse,
    String? difficulty,
  }) {
    if (currentCourse?.toLowerCase().contains('beginner') == true) {
      return [
        'Помоги разобраться с основами ИИ',
        'Какие первые шаги в изучении машинного обучения?',
        'Объясни простыми словами, что такое алгоритм',
        'Какие ресурсы для новичков в ИИ ты рекомендуешь?',
      ];
    } else if (currentCourse?.toLowerCase().contains('intermediate') == true) {
      return [
        'Помоги с пониманием алгоритмов машинного обучения',
        'Как выбрать правильную модель для задачи?',
        'Объясни preprocessing данных',
        'Как оценивать качество модели?',
      ];
    } else if (currentCourse?.toLowerCase().contains('advanced') == true) {
      return [
        'Помоги оптимизировать нейронную сеть',
        'Как работать с transfer learning?',
        'Объясни архитектуры трансформеров',
        'Как решать проблему overfitting?',
      ];
    }

    return getSuggestedQuestions();
  }

  /// Create a new chat session
  static AIAssistantSession createNewSession({String? title}) {
    final now = DateTime.now();
    return AIAssistantSession(
      id: _generateSessionId(),
      title: title ?? 'Новый чат ${_formatDateTime(now)}',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Save chat session (could be extended to save to Supabase)
  static Future<bool> saveChatSession(AIAssistantSession session) async {
    try {
      // For now, just return true. In the future, you could save to Supabase
      // final userId = SupabaseService.currentUserId;
      // if (userId != null) {
      //   await SupabaseService.client
      //       .from('ai_chat_sessions')
      //       .upsert({
      //         'id': session.id,
      //         'user_id': userId,
      //         'title': session.title,
      //         'messages': session.messages.map((m) => m.toJson()).toList(),
      //         'created_at': session.createdAt.toIso8601String(),
      //         'updated_at': session.updatedAt.toIso8601String(),
      //       });
      // }
      return true;
    } catch (e) {
      print('Error saving chat session: $e');
      return false;
    }
  }

  /// Load chat sessions (could be extended to load from Supabase)
  static Future<List<AIAssistantSession>> loadChatSessions() async {
    try {
      // For now, return empty list. In the future, you could load from Supabase
      // final userId = SupabaseService.currentUserId;
      // if (userId != null) {
      //   final response = await SupabaseService.client
      //       .from('ai_chat_sessions')
      //       .select('*')
      //       .eq('user_id', userId)
      //       .order('updated_at', ascending: false);
      //   
      //   return response.map((data) => AIAssistantSession.fromJson(data)).toList();
      // }
      return [];
    } catch (e) {
      print('Error loading chat sessions: $e');
      return [];
    }
  }

  // Helper methods
  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  static String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static ChatMessage _createErrorMessage(String content) {
    return ChatMessage(
      id: _generateMessageId(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }

  /// Test the AI assistant connection
  static Future<bool> testConnection() async {
    try {
      final testMessage = await sendMessage(
        userMessage: 'Привет! Ты работаешь?',
      );
      return testMessage != null;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}