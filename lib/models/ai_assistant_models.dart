class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.value,
      'content': content,
    };
  }
}

enum MessageRole {
  system('system'),
  user('user'),
  assistant('assistant');

  const MessageRole(this.value);
  final String value;
}

class AIAssistantSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIAssistantSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  AIAssistantSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIAssistantSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DeepSeekApiRequest {
  final String model;
  final List<Map<String, String>> messages;
  final bool stream;
  final double? temperature;
  final int? maxTokens;

  DeepSeekApiRequest({
    this.model = 'deepseek-chat',
    required this.messages,
    this.stream = false,
    this.temperature,
    this.maxTokens,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'model': model,
      'messages': messages,
      'stream': stream,
    };

    if (temperature != null) json['temperature'] = temperature;
    if (maxTokens != null) json['max_tokens'] = maxTokens;

    return json;
  }
}

class DeepSeekApiResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<DeepSeekChoice> choices;
  final DeepSeekUsage? usage;

  DeepSeekApiResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory DeepSeekApiResponse.fromJson(Map<String, dynamic> json) {
    return DeepSeekApiResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List)
          .map((choice) => DeepSeekChoice.fromJson(choice))
          .toList(),
      usage: json['usage'] != null
          ? DeepSeekUsage.fromJson(json['usage'])
          : null,
    );
  }
}

class DeepSeekChoice {
  final int index;
  final Map<String, dynamic> message;
  final String? finishReason;

  DeepSeekChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory DeepSeekChoice.fromJson(Map<String, dynamic> json) {
    return DeepSeekChoice(
      index: json['index'] as int,
      message: json['message'] as Map<String, dynamic>,
      finishReason: json['finish_reason'] as String?,
    );
  }
}

class DeepSeekUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  DeepSeekUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory DeepSeekUsage.fromJson(Map<String, dynamic> json) {
    return DeepSeekUsage(
      promptTokens: json['prompt_tokens'] as int,
      completionTokens: json['completion_tokens'] as int,
      totalTokens: json['total_tokens'] as int,
    );
  }
}