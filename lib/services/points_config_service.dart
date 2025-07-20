import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PointsConfigService {
  static final PointsConfigService _instance = PointsConfigService._internal();
  factory PointsConfigService() => _instance;
  PointsConfigService._internal();

  static SupabaseClient get _client => SupabaseService.client;

  // Get currency configuration for a country
  static Future<Map<String, dynamic>?> getCurrencyConfig(String countryCode) async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('currency_config')
          .select('*')
          .eq('country_code', countryCode)
          .eq('is_active', true)
          .maybeSingle();
      
      if (response == null) {
        // Fallback to default
        final defaultResponse = await _client
            .from('currency_config')
            .select('*')
            .eq('country_code', 'DEFAULT')
            .eq('is_active', true)
            .single();
        return defaultResponse;
      }
      
      return response;
    });
  }

  // Get user's currency configuration
  static Future<Map<String, dynamic>?> getUserCurrencyConfig() async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .rpc('get_user_currency_config', params: {
            'user_uuid': userId,
          });
      
      if (result != null && result.isNotEmpty) {
        return result[0];
      }
      
      // Fallback to default
      final defaultConfig = await getCurrencyConfig('DEFAULT');
      return defaultConfig ?? {
        'currency_code': 'USD',
        'currency_symbol': '\$',
        'points_per_currency': 100.0,
      };
    });
  }

  // Calculate points value in user's currency
  static Future<Map<String, dynamic>?> calculatePointsValue(int points) async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .rpc('calculate_points_value', params: {
            'points_amount': points,
            'user_uuid': userId,
          });
      
      return result;
    });
  }

  // Get points configuration for activities
  static Future<Map<String, int>> getPointsConfig() async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('points_config')
          .select('activity_type, base_points, multiplier')
          .eq('is_active', true);
      
      final config = <String, int>{};
      for (final item in response) {
        final basePoints = item['base_points'] as int;
        final multiplier = double.parse(item['multiplier'].toString());
        config[item['activity_type']] = (basePoints * multiplier).round();
      }
      
      return config;
    }) ?? {};
  }

  // Get spending configuration
  static Future<Map<String, double>> getSpendingConfig() async {
    return await SupabaseService.safeExecute(() async {
      final response = await _client
          .from('points_spending_config')
          .select('spending_type, value')
          .eq('is_active', true);
      
      final config = <String, double>{};
      for (final item in response) {
        config[item['spending_type']] = double.parse(item['value'].toString());
      }
      
      return config;
    }) ?? {};
  }

  // Calculate maximum discount for a purchase
  static Future<Map<String, dynamic>?> calculateMaxDiscount({
    required String purchaseType,
    required double originalPrice,
    required int userPoints,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      final result = await _client
          .rpc('calculate_max_discount', params: {
            'purchase_type': purchaseType,
            'original_price': originalPrice,
            'user_points': userPoints,
            'user_uuid': userId,
          });
      
      return result;
    });
  }

  // Update user's currency preference
  static Future<bool> updateUserCurrencyPreference({
    required String currencyCode,
    required String countryCode,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if preference exists
      final existing = await _client
          .from('user_preferences')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing
        await _client
            .from('user_preferences')
            .update({
              'preferred_currency': currencyCode,
              'country_code': countryCode,
            })
            .eq('user_id', userId);
      } else {
        // Insert new
        await _client
            .from('user_preferences')
            .insert({
              'user_id': userId,
              'preferred_currency': currencyCode,
              'country_code': countryCode,
            });
      }
      
      return true;
    }) ?? false;
  }

  // Admin functions
  
  // Update currency configuration
  static Future<bool> updateCurrencyConfig({
    required String countryCode,
    required String currencyCode,
    required String currencySymbol,
    required double pointsPerCurrency,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if admin
      final isAdmin = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single()
          .then((data) => data['role'] == 'admin');
      
      if (!isAdmin) {
        throw Exception('Only admins can update currency configuration');
      }
      
      // Check if exists
      final existing = await _client
          .from('currency_config')
          .select('id')
          .eq('country_code', countryCode)
          .maybeSingle();
      
      if (existing != null) {
        // Update
        await _client
            .from('currency_config')
            .update({
              'currency_code': currencyCode,
              'currency_symbol': currencySymbol,
              'points_per_currency': pointsPerCurrency,
            })
            .eq('country_code', countryCode);
      } else {
        // Insert
        await _client
            .from('currency_config')
            .insert({
              'country_code': countryCode,
              'currency_code': currencyCode,
              'currency_symbol': currencySymbol,
              'points_per_currency': pointsPerCurrency,
            });
      }
      
      return true;
    }) ?? false;
  }

  // Update points configuration
  static Future<bool> updatePointsConfig({
    required String activityType,
    required int basePoints,
    double multiplier = 1.0,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if admin
      final isAdmin = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single()
          .then((data) => data['role'] == 'admin');
      
      if (!isAdmin) {
        throw Exception('Only admins can update points configuration');
      }
      
      await _client
          .from('points_config')
          .update({
            'base_points': basePoints,
            'multiplier': multiplier,
          })
          .eq('activity_type', activityType);
      
      return true;
    }) ?? false;
  }

  // Update spending configuration
  static Future<bool> updateSpendingConfig({
    required String spendingType,
    required double value,
  }) async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if admin
      final isAdmin = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single()
          .then((data) => data['role'] == 'admin');
      
      if (!isAdmin) {
        throw Exception('Only admins can update spending configuration');
      }
      
      await _client
          .from('points_spending_config')
          .update({
            'value': value,
          })
          .eq('spending_type', spendingType);
      
      return true;
    }) ?? false;
  }

  // Get all currency configurations (admin only)
  static Future<List<Map<String, dynamic>>> getAllCurrencyConfigs() async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if admin
      final isAdmin = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single()
          .then((data) => data['role'] == 'admin');
      
      if (!isAdmin) {
        throw Exception('Only admins can view all currency configurations');
      }
      
      final response = await _client
          .from('currency_config')
          .select('*')
          .order('country_code');
      
      return List<Map<String, dynamic>>.from(response);
    }) ?? [];
  }

  // Get points spending analytics (admin only)
  static Future<Map<String, dynamic>> getPointsSpendingAnalytics() async {
    return await SupabaseService.requireAuth((userId) async {
      // Check if admin
      final isAdmin = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single()
          .then((data) => data['role'] == 'admin');
      
      if (!isAdmin) {
        throw Exception('Only admins can view spending analytics');
      }
      
      // Get total points spent
      final totalSpentResponse = await _client
          .from('points_spending')
          .select('points_spent')
          .then((data) => data.fold<int>(0, (sum, item) => sum + (item['points_spent'] as int)));
      
      // Get spending by currency
      final byCurrencyResponse = await _client
          .rpc('get_points_spending_by_currency')
          .catchError((e) async {
            // If function doesn't exist, do manual calculation
            final response = await _client
                .from('points_spending')
                .select('currency_code, points_spent, currency_value');
            
            final byCurrency = <String, Map<String, dynamic>>{};
            for (final item in response) {
              final code = item['currency_code'] as String;
              if (!byCurrency.containsKey(code)) {
                byCurrency[code] = {
                  'total_points': 0,
                  'total_value': 0.0,
                };
              }
              byCurrency[code]!['total_points'] += item['points_spent'] as int;
              byCurrency[code]!['total_value'] += double.parse(item['currency_value'].toString());
            }
            return byCurrency;
          });
      
      // Get recent spending
      final recentSpending = await _client
          .from('points_spending')
          .select('*, users(full_name, email)')
          .order('created_at', ascending: false)
          .limit(20);
      
      return {
        'total_points_spent': totalSpentResponse,
        'spending_by_currency': byCurrencyResponse,
        'recent_spending': recentSpending,
      };
    }) ?? {};
  }
}