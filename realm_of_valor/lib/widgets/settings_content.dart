import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/audio_service.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool _soundEnabled = true;
  bool _hapticFeedback = true;
  bool _achievementPopups = true;
  bool _levelUpAnimations = true;
  bool _showTutorials = true;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building Settings Content');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio Settings
          _buildSettingsSection(
            'Audio Settings',
            Icons.volume_up,
            [
              _buildSwitchSetting(
                'Sound Effects',
                _soundEnabled,
                (value) => setState(() => _soundEnabled = value),
                Icons.speaker,
              ),
              _buildSliderSetting(
                'Music Volume',
                _musicVolume,
                (value) => setState(() => _musicVolume = value),
                Icons.music_note,
              ),
              _buildSliderSetting(
                'SFX Volume',
                _sfxVolume,
                (value) => setState(() => _sfxVolume = value),
                Icons.speaker_group,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Feedback Settings
          _buildSettingsSection(
            'Feedback Settings',
            Icons.vibration,
            [
              _buildSwitchSetting(
                'Haptic Feedback',
                _hapticFeedback,
                (value) => setState(() => _hapticFeedback = value),
                Icons.touch_app,
              ),
              _buildSwitchSetting(
                'Achievement Popups',
                _achievementPopups,
                (value) => setState(() => _achievementPopups = value),
                Icons.emoji_events,
              ),
              _buildSwitchSetting(
                'Level Up Animations',
                _levelUpAnimations,
                (value) => setState(() => _levelUpAnimations = value),
                Icons.trending_up,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Game Settings
          _buildSettingsSection(
            'Game Settings',
            Icons.sports_esports,
            [
              _buildSwitchSetting(
                'Show Tutorials',
                _showTutorials,
                (value) => setState(() => _showTutorials = value),
                Icons.help_outline,
              ),
              _buildButtonSetting(
                'Reset Progress',
                () => _showResetConfirmation(),
                Icons.refresh,
                color: RealmOfValorTheme.healthRed,
              ),
              _buildButtonSetting(
                'Export Data',
                () => _exportData(),
                Icons.download,
              ),
              _buildButtonSetting(
                'Import Data',
                () => _importData(),
                Icons.upload,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSettingsSection(
            'About',
            Icons.info,
            [
              _buildInfoSetting(
                'Version',
                '1.0.0',
                Icons.tag,
              ),
              _buildInfoSetting(
                'Build',
                '2024.1.1',
                Icons.build,
              ),
              _buildButtonSetting(
                'Privacy Policy',
                () => _openPrivacyPolicy(),
                Icons.privacy_tip,
              ),
              _buildButtonSetting(
                'Terms of Service',
                () => _openTermsOfService(),
                Icons.description,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: RealmOfValorTheme.accentGold,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RealmOfValorTheme.primaryLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? RealmOfValorTheme.accentGold,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RealmOfValorTheme.accentGold,
            activeTrackColor: RealmOfValorTheme.accentGold.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RealmOfValorTheme.primaryLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: RealmOfValorTheme.accentGold,
              inactiveTrackColor: RealmOfValorTheme.surfaceMedium,
              thumbColor: RealmOfValorTheme.accentGold,
              overlayColor: RealmOfValorTheme.accentGold.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSetting(
    String title,
    VoidCallback onPressed,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: RealmOfValorTheme.primaryLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color ?? RealmOfValorTheme.accentGold,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: color ?? RealmOfValorTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: RealmOfValorTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSetting(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RealmOfValorTheme.primaryLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: RealmOfValorTheme.accentGold,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: RealmOfValorTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceMedium,
        title: const Text(
          'Reset Progress',
          style: TextStyle(color: RealmOfValorTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to reset all progress? This action cannot be undone.',
          style: TextStyle(color: RealmOfValorTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: RealmOfValorTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement reset functionality
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: RealmOfValorTheme.healthRed),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _importData() {
    // TODO: Implement data import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _openPrivacyPolicy() {
    // TODO: Open privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy Policy coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }

  void _openTermsOfService() {
    // TODO: Open terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of Service coming soon!'),
        backgroundColor: RealmOfValorTheme.accentGold,
      ),
    );
  }
} 