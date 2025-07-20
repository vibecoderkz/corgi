import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'services/auth_service.dart';
import 'models/user_registration_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _errorMessage;
  
  // Extended fields
  File? _avatarFile;
  String? _selectedCity;
  DateTime? _birthDate;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо разрешение на доступ к камере')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        if (fileSize > 2 * 1024 * 1024) { // 2MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Размер файла не должен превышать 2MB')),
          );
          return;
        }

        setState(() {
          _avatarFile = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при загрузке изображения')),
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Выберите дату рождения',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      fieldLabelText: 'Дата рождения',
      fieldHintText: 'дд.мм.гггг',
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Необходимо принять условия использования';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = UserRegistrationModel(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        city: _selectedCity,
        birthDate: _birthDate,
        avatarFile: _avatarFile,
        acceptedTerms: _acceptedTerms,
      );

      final response = await AuthService().signUpWithExtendedProfile(userData);

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аккаунт создан! Проверьте email для подтверждения.'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        if (e.toString().contains('already registered')) {
          _errorMessage = 'Email уже используется';
        } else {
          _errorMessage = 'Ошибка при создании аккаунта';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        const Text(
          'Фото профиля',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickAvatar,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              color: Colors.grey.shade100,
            ),
            child: _avatarFile != null
                ? ClipOval(
                    child: Image.file(
                      _avatarFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.grey,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickAvatar,
          child: Text(_avatarFile != null ? 'Изменить фото' : 'Добавить фото'),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final cities = CityOption.getPopularCities();
    
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      decoration: const InputDecoration(
        labelText: 'Город (необязательно)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_city),
      ),
      items: cities.map((city) {
        return DropdownMenuItem(
          value: city.fullName,
          child: Text(city.fullName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCity = value;
        });
      },
    );
  }

  Widget _buildBirthDateField() {
    return GestureDetector(
      onTap: _selectBirthDate,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Дата рождения (необязательно)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today),
            hintText: _birthDate != null
                ? '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}'
                : 'Выберите дату',
          ),
          controller: TextEditingController(
            text: _birthDate != null
                ? '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}'
                : '',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              
              const Text(
                'Данные аккаунта',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  if (value.length < 2) {
                    return 'Имя должно содержать минимум 2 символа';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 6) {
                    return 'Пароль должен содержать минимум 6 символов';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Личная информация',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Center(child: _buildAvatarSection()),
              
              const SizedBox(height: 24),
              
              _buildCityDropdown(),
              
              const SizedBox(height: 16),
              
              _buildBirthDateField(),
              
              const SizedBox(height: 32),
              
              const Text(
                'Согласие',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                        if (_acceptedTerms) {
                          _errorMessage = null;
                        }
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('Я принимаю условия использования'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Создать аккаунт'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Уже есть аккаунт? '),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Войти'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
