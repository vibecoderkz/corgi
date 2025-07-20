import 'package:flutter/material.dart';
import '../models/discussion_models.dart';
import '../services/discussion_service.dart';

class CreateDiscussionScreen extends StatefulWidget {
  const CreateDiscussionScreen({super.key});

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<ContentItem> _availableContent = [];
  ContentItem? _selectedContent;
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableContent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await DiscussionService.getAccessibleContent();
      if (mounted) {
        setState(() {
          _availableContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки доступного контента: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createDiscussion() async {
    if (!_formKey.currentState!.validate() || _selectedContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final request = CreateDiscussionGroupRequest(
        courseId: _selectedContent!.type == 'course' ? _selectedContent!.id : null,
        moduleId: _selectedContent!.type == 'module' ? _selectedContent!.id : null,
        lessonId: _selectedContent!.type == 'lesson' ? _selectedContent!.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      final discussionId = await DiscussionService.createDiscussionGroup(request);
      
      if (mounted && discussionId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Обсуждение создано успешно!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания обсуждения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать обсуждение'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAvailableContent,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _availableContent.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Нет доступного контента',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Купите курсы, модули или уроки,\nчтобы создавать обсуждения',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info card
                            Card(
                              color: Colors.blue[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[600]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Создайте обсуждение для любого курса, модуля или урока, к которому у вас есть доступ.',
                                        style: TextStyle(color: Colors.blue[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Content selection
                            Text(
                              'Выберите контент *',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ContentItem>(
                                  value: _selectedContent,
                                  hint: const Text('Выберите курс, модуль или урок'),
                                  isExpanded: true,
                                  onChanged: (ContentItem? value) {
                                    setState(() {
                                      _selectedContent = value;
                                    });
                                  },
                                  items: _availableContent.map((ContentItem content) {
                                    return DropdownMenuItem<ContentItem>(
                                      value: content,
                                      child: Row(
                                        children: [
                                          _getContentIcon(content.type),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  content.title,
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  _getContentTypeText(content.type),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Discussion name
                            Text(
                              'Название обсуждения *',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Введите название обсуждения',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Название обсуждения обязательно';
                                }
                                if (value.trim().length < 3) {
                                  return 'Название должно содержать минимум 3 символа';
                                }
                                if (value.trim().length > 100) {
                                  return 'Название не должно превышать 100 символов';
                                }
                                return null;
                              },
                              maxLength: 100,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Discussion description
                            Text(
                              'Описание обсуждения',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                hintText: 'Опишите цель и тематику обсуждения (необязательно)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 4,
                              maxLength: 500,
                              validator: (value) {
                                if (value != null && value.trim().length > 500) {
                                  return 'Описание не должно превышать 500 символов';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Create button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isCreating ? null : _createDiscussion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isCreating
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Создание...'),
                                        ],
                                      )
                                    : const Text(
                                        'Создать обсуждение',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Cancel button
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _isCreating 
                                    ? null 
                                    : () => Navigator.pop(context),
                                child: const Text('Отмена'),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _getContentIcon(String type) {
    switch (type) {
      case 'course':
        return Icon(Icons.school, size: 20, color: Colors.green[600]);
      case 'module':
        return Icon(Icons.book, size: 20, color: Colors.orange[600]);
      case 'lesson':
        return Icon(Icons.play_lesson, size: 20, color: Colors.blue[600]);
      default:
        return Icon(Icons.help_outline, size: 20, color: Colors.grey[600]);
    }
  }

  String _getContentTypeText(String type) {
    switch (type) {
      case 'course':
        return 'Курс';
      case 'module':
        return 'Модуль';
      case 'lesson':
        return 'Урок';
      default:
        return 'Неизвестно';
    }
  }
}