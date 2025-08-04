import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/audio_service.dart';
import '../providers/character_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _masterVolume = 0.7;
  double _sfxVolume = 0.8;
  double _musicVolume = 0.6;
  bool _audioEnabled = true;
  bool _notificationsEnabled = true;
  bool _autoSaveEnabled = true;
  String _selectedTheme = 'Dark';
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Audio Settings', [
              _buildSwitchTile(
                'Enable Audio',
                'Enable or disable all audio',
                _audioEnabled,
                (value) => setState(() => _audioEnabled = value),
                Icons.volume_up,
              ),
              _buildSliderTile(
                'Master Volume',
                _masterVolume,
                (value) => setState(() => _masterVolume = value),
                Icons.volume_up,
              ),
              _buildSliderTile(
                'SFX Volume',
                _sfxVolume,
                (value) => setState(() => _sfxVolume = value),
                Icons.speaker,
              ),
              _buildSliderTile(
                'Music Volume',
                _musicVolume,
                (value) => setState(() => _musicVolume = value),
                Icons.music_note,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Game Settings', [
              _buildSwitchTile(
                'Notifications',
                'Enable push notifications',
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
                Icons.notifications,
              ),
              _buildSwitchTile(
                'Auto Save',
                'Automatically save game progress',
                _autoSaveEnabled,
                (value) => setState(() => _autoSaveEnabled = value),
                Icons.save,
              ),
              _buildDropdownTile(
                'Theme',
                _selectedTheme,
                ['Dark', 'Light', 'Auto'],
                (value) => setState(() => _selectedTheme = value),
                Icons.palette,
              ),
              _buildDropdownTile(
                'Language',
                _selectedLanguage,
                ['English', 'Spanish', 'French', 'German'],
                (value) => setState(() => _selectedLanguage = value),
                Icons.language,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Account', [
              _buildActionTile(
                'Character Management',
                'View and manage your characters',
                () => _openCharacterManagement(),
                Icons.person,
              ),
              _buildActionTile(
                'Data Export',
                'Export your game data',
                () => _exportData(),
                Icons.download,
              ),
              _buildActionTile(
                'Data Import',
                'Import game data',
                () => _importData(),
                Icons.upload,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Support', [
              _buildActionTile(
                'Help & Tutorial',
                'Learn how to play',
                () => _openHelp(),
                Icons.help,
              ),
              _buildActionTile(
                'Report Bug',
                'Report a bug or issue',
                () => _reportBug(),
                Icons.bug_report,
              ),
              _buildActionTile(
                'Feedback',
                'Send us feedback',
                () => _sendFeedback(),
                Icons.feedback,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('About', [
              _buildInfoTile(
                'Version',
                '1.0.0',
                Icons.info,
              ),
              _buildInfoTile(
                'Build',
                '2024.1.1',
                Icons.build,
              ),
              _buildActionTile(
                'Privacy Policy',
                'View privacy policy',
                () => _openPrivacyPolicy(),
                Icons.privacy_tip,
              ),
              _buildActionTile(
                'Terms of Service',
                'View terms of service',
                () => _openTermsOfService(),
                Icons.description,
              ),
            ]),
            const SizedBox(height: 24),
            _buildDangerSection('Danger Zone', [
              _buildActionTile(
                'Reset Progress',
                'Reset all character progress (irreversible)',
                () => _showResetConfirmation(),
                Icons.restore,
                color: Colors.red,
              ),
              _buildActionTile(
                'Delete All Data',
                'Delete all game data (irreversible)',
                () => _showDeleteConfirmation(),
                Icons.delete_forever,
                color: Colors.red,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.accentGold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceMedium,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDangerSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceMedium,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.5)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: RealmOfValorTheme.accentGold,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: RealmOfValorTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: RealmOfValorTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  Widget _buildSliderTile(String title, double value, ValueChanged<double> onChanged, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: RealmOfValorTheme.accentGold,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: RealmOfValorTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Slider(
        value: value,
        onChanged: onChanged,
        activeColor: RealmOfValorTheme.accentGold,
        inactiveColor: RealmOfValorTheme.surfaceDark,
      ),
      trailing: Text(
        '${(value * 100).round()}%',
        style: TextStyle(
          color: RealmOfValorTheme.accentGold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> options, ValueChanged<String> onChanged, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: RealmOfValorTheme.accentGold,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: RealmOfValorTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
        dropdownColor: RealmOfValorTheme.surfaceMedium,
        style: TextStyle(
          color: RealmOfValorTheme.textPrimary,
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, VoidCallback onTap, IconData icon, {Color? color}) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? RealmOfValorTheme.accentGold,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? RealmOfValorTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: RealmOfValorTheme.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: color ?? RealmOfValorTheme.accentGold,
        size: 16,
      ),
      onTap: () {
        AudioService.instance.playSound(AudioType.buttonClick);
        onTap();
      },
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: RealmOfValorTheme.accentGold,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: RealmOfValorTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: RealmOfValorTheme.textSecondary,
        ),
      ),
    );
  }

  void _openCharacterManagement() {
    // TODO: Implement character management
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Character management coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data export coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _importData() {
    // TODO: Implement data import
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data import coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _openHelp() {
    // TODO: Implement help system
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Help system coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _reportBug() {
    // TODO: Implement bug reporting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bug reporting coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _sendFeedback() {
    // TODO: Implement feedback system
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feedback system coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _openPrivacyPolicy() {
    // TODO: Implement privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Privacy policy coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _openTermsOfService() {
    // TODO: Implement terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terms of service coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: Text(
          'Reset Progress',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all character progress? This action cannot be undone.',
          style: TextStyle(color: RealmOfValorTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: RealmOfValorTheme.accentGold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement reset progress
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Progress reset coming soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: Text(
          'Delete All Data',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all game data? This action cannot be undone.',
          style: TextStyle(color: RealmOfValorTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: RealmOfValorTheme.accentGold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete all data
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data deletion coming soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 