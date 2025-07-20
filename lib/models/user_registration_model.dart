import 'dart:io';

class UserRegistrationModel {
  final String name;
  final String email;
  final String password;
  final String? city;
  final DateTime? birthDate;
  final File? avatarFile;
  final bool acceptedTerms;

  UserRegistrationModel({
    required this.name,
    required this.email,
    required this.password,
    this.city,
    this.birthDate,
    this.avatarFile,
    required this.acceptedTerms,
  });

  Map<String, dynamic> toUserMetadata({String? avatarUrl}) {
    return {
      'name': name,
      'role': 'student',
      'city': city,
      'birth_date': birthDate?.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }
}

class CityOption {
  final String name;
  final String country;
  final String fullName;

  CityOption({
    required this.name,
    required this.country,
  }) : fullName = '$name, $country';

  static List<CityOption> getPopularCities() {
    return [
      CityOption(name: 'Алматы', country: 'Казахстан'),
      CityOption(name: 'Астана', country: 'Казахстан'),
      CityOption(name: 'Москва', country: 'Россия'),
      CityOption(name: 'Санкт-Петербург', country: 'Россия'),
      CityOption(name: 'Киев', country: 'Украина'),
      CityOption(name: 'Минск', country: 'Беларусь'),
      CityOption(name: 'Ташкент', country: 'Узбекистан'),
      CityOption(name: 'Бишкек', country: 'Кыргызстан'),
      CityOption(name: 'Душанбе', country: 'Таджикистан'),
      CityOption(name: 'Ереван', country: 'Армения'),
      CityOption(name: 'Баку', country: 'Азербайджан'),
      CityOption(name: 'Тбилиси', country: 'Грузия'),
    ];
  }
}