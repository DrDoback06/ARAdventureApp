import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../constants/theme.dart';

class AudioSettingsWidget extends StatelessWidget {
  const AudioSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.volume_up,
                      color: RealmOfValorTheme.accentGold,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Audio Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: !audioService.isMuted,
                      onChanged: (value) => audioService.toggleMute(),
                      activeColor: RealmOfValorTheme.accentGold,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Master Volume
                _buildVolumeSlider(
                  context,
                  'Master Volume',
                  audioService.masterVolume,
                  (value) => audioService.setMasterVolume(value),
                  Icons.volume_up,
                ),
                
                const SizedBox(height: 12),
                
                // Music Volume
                _buildVolumeSlider(
                  context,
                  'Music Volume',
                  audioService.musicVolume,
                  (value) => audioService.setMusicVolume(value),
                  Icons.music_note,
                ),
                
                const SizedBox(height: 12),
                
                // SFX Volume
                _buildVolumeSlider(
                  context,
                  'Sound Effects',
                  audioService.sfxVolume,
                  (value) => audioService.setSfxVolume(value),
                  Icons.speaker,
                ),
                
                const SizedBox(height: 12),
                
                // UI Volume
                _buildVolumeSlider(
                  context,
                  'UI Sounds',
                  audioService.uiVolume,
                  (value) => audioService.setUiVolume(value),
                  Icons.touch_app,
                ),
                
                const SizedBox(height: 16),
                
                // Test Sounds Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => audioService.playButtonClick(),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Test UI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RealmOfValorTheme.primaryLight,
                          foregroundColor: RealmOfValorTheme.accentGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => audioService.playAttack(),
                        icon: const Icon(Icons.sports_martial_arts, size: 16),
                        label: const Text('Test SFX'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RealmOfValorTheme.primaryLight,
                          foregroundColor: RealmOfValorTheme.accentGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => audioService.playBackgroundMusic('assets/sounds/background_music.mp3'),
                        icon: const Icon(Icons.music_note, size: 16),
                        label: const Text('Test Music'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RealmOfValorTheme.primaryLight,
                          foregroundColor: RealmOfValorTheme.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolumeSlider(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: RealmOfValorTheme.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: RealmOfValorTheme.accentGold,
            inactiveTrackColor: RealmOfValorTheme.surfaceLight,
            thumbColor: RealmOfValorTheme.accentGold,
            overlayColor: RealmOfValorTheme.accentGold.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            divisions: 20,
          ),
        ),
      ],
    );
  }
} 