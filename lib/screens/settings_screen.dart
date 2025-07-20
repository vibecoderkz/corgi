import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            'Edit Profile',
            'Update your personal information',
            Icons.person,
            () {
              // TODO: Navigate to edit profile
            },
          ),
          _buildSettingsTile(
            'Privacy & Security',
            'Manage your privacy settings',
            Icons.security,
            () {
              // TODO: Navigate to privacy settings
            },
          ),
          _buildSettingsTile(
            'Change Password',
            'Update your account password',
            Icons.lock,
            () {
              // TODO: Navigate to change password
            },
          ),
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Enable Notifications',
            'Receive notifications about your courses',
            Icons.notifications,
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildSwitchTile(
            'Email Notifications',
            'Receive notifications via email',
            Icons.email,
            _emailNotifications,
            (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            'Push Notifications',
            'Receive push notifications on your device',
            Icons.notifications_active,
            _pushNotifications,
            (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            'Dark Mode',
            'Use dark theme for the app',
            Icons.dark_mode,
            _darkMode,
            (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          _buildDropdownTile(
            'Language',
            'Select your preferred language',
            Icons.language,
            _language,
            ['English', 'Russian', 'Spanish', 'French'],
            (value) {
              setState(() {
                _language = value!;
              });
            },
          ),
          _buildSectionHeader('Learning'),
          _buildSettingsTile(
            'Learning Preferences',
            'Customize your learning experience',
            Icons.school,
            () {
              // TODO: Navigate to learning preferences
            },
          ),
          _buildSettingsTile(
            'Download Settings',
            'Manage offline content downloads',
            Icons.download,
            () {
              // TODO: Navigate to download settings
            },
          ),
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            'Help & Support',
            'Get help and contact support',
            Icons.help,
            () {
              // TODO: Navigate to help
            },
          ),
          _buildSettingsTile(
            'About',
            'App version and information',
            Icons.info,
            () {
              // TODO: Navigate to about
            },
          ),
          _buildSettingsTile(
            'Terms of Service',
            'Read our terms and conditions',
            Icons.description,
            () {
              // TODO: Navigate to terms
            },
          ),
          _buildSettingsTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip,
            () {
              // TODO: Navigate to privacy policy
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }
}