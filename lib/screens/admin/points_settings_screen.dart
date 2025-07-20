import 'package:flutter/material.dart';
import '../../services/points_config_service.dart';

class PointsSettingsScreen extends StatefulWidget {
  const PointsSettingsScreen({super.key});

  @override
  State<PointsSettingsScreen> createState() => _PointsSettingsScreenState();
}

class _PointsSettingsScreenState extends State<PointsSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Points configuration
  Map<String, int> _pointsConfig = {};
  Map<String, TextEditingController> _pointsControllers = {};
  
  // Currency configuration
  List<Map<String, dynamic>> _currencyConfigs = [];
  Map<String, TextEditingController> _currencyControllers = {};
  
  // Spending configuration
  Map<String, double> _spendingConfig = {};
  Map<String, TextEditingController> _spendingControllers = {};
  
  // Analytics
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose controllers
    for (final controller in _pointsControllers.values) {
      controller.dispose();
    }
    for (final controller in _currencyControllers.values) {
      controller.dispose();
    }
    for (final controller in _spendingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load points configuration
      final pointsConfig = await PointsConfigService.getPointsConfig();
      
      // Load currency configurations
      final currencyConfigs = await PointsConfigService.getAllCurrencyConfigs();
      
      // Load spending configuration
      final spendingConfig = await PointsConfigService.getSpendingConfig();
      
      // Load analytics
      final analytics = await PointsConfigService.getPointsSpendingAnalytics();

      setState(() {
        _pointsConfig = pointsConfig;
        _currencyConfigs = currencyConfigs;
        _spendingConfig = spendingConfig;
        _analytics = analytics;
        _isLoading = false;
      });

      // Initialize controllers
      _initializeControllers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _initializeControllers() {
    // Points controllers
    for (final entry in _pointsConfig.entries) {
      _pointsControllers[entry.key] = TextEditingController(
        text: entry.value.toString(),
      );
    }
    
    // Currency controllers
    for (final config in _currencyConfigs) {
      final key = config['country_code'] as String;
      _currencyControllers['${key}_currency'] = TextEditingController(
        text: config['currency_code'] as String,
      );
      _currencyControllers['${key}_symbol'] = TextEditingController(
        text: config['currency_symbol'] as String,
      );
      _currencyControllers['${key}_rate'] = TextEditingController(
        text: config['points_per_currency'].toString(),
      );
    }
    
    // Spending controllers
    for (final entry in _spendingConfig.entries) {
      _spendingControllers[entry.key] = TextEditingController(
        text: entry.value.toString(),
      );
    }
  }

  Future<void> _savePointsConfig() async {
    try {
      for (final entry in _pointsControllers.entries) {
        final points = int.tryParse(entry.value.text) ?? 0;
        await PointsConfigService.updatePointsConfig(
          activityType: entry.key,
          basePoints: points,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving points config: $e')),
        );
      }
    }
  }

  Future<void> _saveCurrencyConfig() async {
    try {
      for (final config in _currencyConfigs) {
        final countryCode = config['country_code'] as String;
        final currencyCode = _currencyControllers['${countryCode}_currency']?.text ?? '';
        final symbol = _currencyControllers['${countryCode}_symbol']?.text ?? '';
        final rate = double.tryParse(_currencyControllers['${countryCode}_rate']?.text ?? '0') ?? 0.0;
        
        await PointsConfigService.updateCurrencyConfig(
          countryCode: countryCode,
          currencyCode: currencyCode,
          currencySymbol: symbol,
          pointsPerCurrency: rate,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Currency configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving currency config: $e')),
        );
      }
    }
  }

  Future<void> _saveSpendingConfig() async {
    try {
      for (final entry in _spendingControllers.entries) {
        final value = double.tryParse(entry.value.text) ?? 0.0;
        await PointsConfigService.updateSpendingConfig(
          spendingType: entry.key,
          value: value,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving spending config: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points Settings'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Points Earning'),
            Tab(text: 'Currency'),
            Tab(text: 'Spending'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPointsEarningTab(),
                _buildCurrencyTab(),
                _buildSpendingTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildPointsEarningTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Configure points earned for different activities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildPointsConfigTile('homework_completed', 'Homework Completed'),
                _buildPointsConfigTile('final_project_completed', 'Final Project Completed'),
                _buildPointsConfigTile('module_completed', 'Module Completed'),
                _buildPointsConfigTile('course_completed', 'Course Completed'),
                _buildPointsConfigTile('useful_post', 'Useful Post'),
                _buildPointsConfigTile('daily_login', 'Daily Login'),
                _buildPointsConfigTile('achievement_earned', 'Achievement Earned'),
                _buildPointsConfigTile('referral_bonus', 'Referral Bonus'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _savePointsConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Points Configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsConfigTile(String key, String title) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: SizedBox(
          width: 80,
          child: TextField(
            controller: _pointsControllers[key],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Configure currency settings and conversion rates',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _currencyConfigs.length,
              itemBuilder: (context, index) {
                final config = _currencyConfigs[index];
                final countryCode = config['country_code'] as String;
                return _buildCurrencyConfigCard(config, countryCode);
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveCurrencyConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Currency Configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyConfigCard(Map<String, dynamic> config, String countryCode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Country: $countryCode',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _currencyControllers['${countryCode}_currency'],
                    decoration: const InputDecoration(
                      labelText: 'Currency Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _currencyControllers['${countryCode}_symbol'],
                    decoration: const InputDecoration(
                      labelText: 'Symbol',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currencyControllers['${countryCode}_rate'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Points per Currency Unit',
                border: OutlineInputBorder(),
                helperText: 'How many points equal 1 unit of this currency',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Configure points spending and discount limits',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildSpendingConfigTile('course_discount', 'Course Discount %'),
                _buildSpendingConfigTile('module_discount', 'Module Discount %'),
                _buildSpendingConfigTile('lesson_discount', 'Lesson Discount %'),
                _buildSpendingConfigTile('max_discount_percentage', 'Maximum Discount %'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveSpendingConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Spending Configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingConfigTile(String key, String title) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: SizedBox(
          width: 80,
          child: TextField(
            controller: _spendingControllers[key],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              suffixText: '%',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Points Spending Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Points Spent',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_analytics['total_points_spent'] ?? 0} points',
                    style: const TextStyle(fontSize: 24, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Spending by Currency',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_analytics['spending_by_currency'] != null)
            ..._buildCurrencyAnalytics(_analytics['spending_by_currency']),
          const SizedBox(height: 16),
          const Text(
            'Recent Spending',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: (_analytics['recent_spending'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final spending = (_analytics['recent_spending'] as List)[index];
                return _buildRecentSpendingTile(spending);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCurrencyAnalytics(Map<String, dynamic> byCurrency) {
    return byCurrency.entries.map((entry) {
      final currency = entry.key;
      final data = entry.value as Map<String, dynamic>;
      return Card(
        child: ListTile(
          title: Text(currency),
          subtitle: Text('${data['total_points']} points'),
          trailing: Text(
            '${data['total_value']?.toStringAsFixed(2)} $currency',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRecentSpendingTile(Map<String, dynamic> spending) {
    return Card(
      child: ListTile(
        title: Text('${spending['points_spent']} points'),
        subtitle: Text(spending['description'] ?? 'No description'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${spending['currency_value']} ${spending['currency_code']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              spending['created_at'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}