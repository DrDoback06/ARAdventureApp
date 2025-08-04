import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioType {
  cardLift,
  cardDrop,
  spellCast,
  spellResolve,
  attack,
  criticalHit,
  superCritical,
  devastatingCritical,
  levelUp,
  victory,
  defeat,
  error,
  targetHover,
  buttonClick,
  menuOpen,
  menuClose,
  itemFound,
  questComplete,
  achievement,
  backgroundMusic,
}

class AudioService extends ChangeNotifier {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  
  AudioService._();
  
  final AudioPlayer _soundEffectsPlayer = AudioPlayer();
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _uiPlayer = AudioPlayer();
  
  bool _isMuted = false;
  double _masterVolume = 1.0;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  double _uiVolume = 0.6;
  
  // Preloaded audio assets
  final Map<AudioType, String> _audioAssets = {
    AudioType.cardLift: 'assets/sounds/card_lift.mp3',
    AudioType.cardDrop: 'assets/sounds/card_drop.mp3',
    AudioType.spellCast: 'assets/sounds/spell_cast.mp3',
    AudioType.spellResolve: 'assets/sounds/spell_resolve.mp3',
    AudioType.attack: 'assets/sounds/attack.mp3',
    AudioType.criticalHit: 'assets/sounds/critical_hit.mp3',
    AudioType.superCritical: 'assets/sounds/super_critical.mp3',
    AudioType.devastatingCritical: 'assets/sounds/devastating_critical.mp3',
    AudioType.levelUp: 'assets/sounds/level_up.mp3',
    AudioType.victory: 'assets/sounds/victory.mp3',
    AudioType.defeat: 'assets/sounds/defeat.mp3',
    AudioType.error: 'assets/sounds/error.mp3',
    AudioType.targetHover: 'assets/sounds/target_hover.mp3',
    AudioType.buttonClick: 'assets/sounds/button_click.mp3',
    AudioType.menuOpen: 'assets/sounds/menu_open.mp3',
    AudioType.menuClose: 'assets/sounds/menu_close.mp3',
    AudioType.itemFound: 'assets/sounds/item_found.mp3',
    AudioType.questComplete: 'assets/sounds/quest_complete.mp3',
    AudioType.achievement: 'assets/sounds/achievement.mp3',
    AudioType.backgroundMusic: 'assets/sounds/background_music.mp3',
  };
  
  // Fallback sounds for missing assets
  final Map<AudioType, String> _fallbackSounds = {
    AudioType.cardLift: 'assets/sounds/ui_click.mp3',
    AudioType.cardDrop: 'assets/sounds/ui_click.mp3',
    AudioType.spellCast: 'assets/sounds/ui_click.mp3',
    AudioType.spellResolve: 'assets/sounds/ui_click.mp3',
    AudioType.attack: 'assets/sounds/ui_click.mp3',
    AudioType.criticalHit: 'assets/sounds/ui_click.mp3',
    AudioType.superCritical: 'assets/sounds/ui_click.mp3',
    AudioType.devastatingCritical: 'assets/sounds/ui_click.mp3',
    AudioType.levelUp: 'assets/sounds/ui_click.mp3',
    AudioType.victory: 'assets/sounds/ui_click.mp3',
    AudioType.defeat: 'assets/sounds/ui_click.mp3',
    AudioType.error: 'assets/sounds/ui_click.mp3',
    AudioType.targetHover: 'assets/sounds/ui_click.mp3',
    AudioType.buttonClick: 'assets/sounds/ui_click.mp3',
    AudioType.menuOpen: 'assets/sounds/ui_click.mp3',
    AudioType.menuClose: 'assets/sounds/ui_click.mp3',
    AudioType.itemFound: 'assets/sounds/ui_click.mp3',
    AudioType.questComplete: 'assets/sounds/ui_click.mp3',
    AudioType.achievement: 'assets/sounds/ui_click.mp3',
    AudioType.backgroundMusic: 'assets/sounds/background_music.mp3',
  };
  
  @override
  void dispose() {
    _soundEffectsPlayer.dispose();
    _backgroundMusicPlayer.dispose();
    _uiPlayer.dispose();
    super.dispose();
  }
  
  // Initialize audio settings from preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('audio_muted') ?? false;
      _masterVolume = prefs.getDouble('audio_master_volume') ?? 1.0;
      _musicVolume = prefs.getDouble('audio_music_volume') ?? 0.7;
      _sfxVolume = prefs.getDouble('audio_sfx_volume') ?? 0.8;
      _uiVolume = prefs.getDouble('audio_ui_volume') ?? 0.6;
      
      // Set initial volumes
      await _backgroundMusicPlayer.setVolume(_musicVolume * _masterVolume);
      await _soundEffectsPlayer.setVolume(_sfxVolume * _masterVolume);
      await _uiPlayer.setVolume(_uiVolume * _masterVolume);
      
      debugPrint('[AUDIO] Audio service initialized successfully');
    } catch (e) {
      debugPrint('[AUDIO] Error initializing audio service: $e');
    }
  }
  
  // Save audio settings to preferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('audio_muted', _isMuted);
      await prefs.setDouble('audio_master_volume', _masterVolume);
      await prefs.setDouble('audio_music_volume', _musicVolume);
      await prefs.setDouble('audio_sfx_volume', _sfxVolume);
      await prefs.setDouble('audio_ui_volume', _uiVolume);
    } catch (e) {
      debugPrint('[AUDIO] Error saving audio settings: $e');
    }
  }
  
  // Play sound effect
  Future<void> playSound(AudioType type) async {
    if (_isMuted) return;
    
    try {
      String assetPath = _audioAssets[type] ?? _fallbackSounds[type] ?? '';
      if (assetPath.isEmpty) {
        debugPrint('[AUDIO] No audio asset found for type: $type');
        return;
      }
      
      // Check if the asset file actually exists
      try {
        await AudioPlayer().setSource(AssetSource(assetPath));
      } catch (e) {
        debugPrint('[AUDIO] Audio file not found: $assetPath');
        debugPrint('[AUDIO] Playing sound: $type');
        return; // Silently fail instead of throwing errors
      }
      
      AudioPlayer player;
      double volume;
      
      switch (type) {
        case AudioType.backgroundMusic:
          player = _backgroundMusicPlayer;
          volume = _musicVolume * _masterVolume;
          break;
        case AudioType.buttonClick:
        case AudioType.menuOpen:
        case AudioType.menuClose:
          player = _uiPlayer;
          volume = _uiVolume * _masterVolume;
          break;
        default:
          player = _soundEffectsPlayer;
          volume = _sfxVolume * _masterVolume;
          break;
      }
      
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath)).catchError((error) {
        // Silently handle missing audio files
        debugPrint('[AUDIO] Audio file not found: $assetPath');
      });
      
      debugPrint('[AUDIO] Playing sound: $type');
    } catch (e) {
      debugPrint('[AUDIO] Error playing sound $type: $e');
    }
  }
  
  // Play background music
  Future<void> playBackgroundMusic(String musicAsset) async {
    if (_isMuted) return;
    
    try {
      await _backgroundMusicPlayer.setVolume(_musicVolume * _masterVolume);
      await _backgroundMusicPlayer.play(AssetSource(musicAsset));
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      debugPrint('[AUDIO] Playing background music: $musicAsset');
    } catch (e) {
      debugPrint('[AUDIO] Error playing background music: $e');
    }
  }
  
  // Stop background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.stop();
      debugPrint('[AUDIO] Stopped background music');
    } catch (e) {
      debugPrint('[AUDIO] Error stopping background music: $e');
    }
  }
  
  // Pause background music
  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.pause();
      debugPrint('[AUDIO] Paused background music');
    } catch (e) {
      debugPrint('[AUDIO] Error pausing background music: $e');
    }
  }
  
  // Resume background music
  Future<void> resumeBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.resume();
      debugPrint('[AUDIO] Resumed background music');
    } catch (e) {
      debugPrint('[AUDIO] Error resuming background music: $e');
    }
  }
  
  // Set master volume
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    await _updateAllVolumes();
    await saveSettings();
    notifyListeners();
  }
  
  // Set music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _backgroundMusicPlayer.setVolume(_musicVolume * _masterVolume);
    await saveSettings();
    notifyListeners();
  }
  
  // Set SFX volume
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _soundEffectsPlayer.setVolume(_sfxVolume * _masterVolume);
    await saveSettings();
    notifyListeners();
  }
  
  // Set UI volume
  Future<void> setUiVolume(double volume) async {
    _uiVolume = volume.clamp(0.0, 1.0);
    await _uiPlayer.setVolume(_uiVolume * _masterVolume);
    await saveSettings();
    notifyListeners();
  }
  
  // Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await _backgroundMusicPlayer.pause();
    } else {
      await _backgroundMusicPlayer.resume();
    }
    await saveSettings();
    notifyListeners();
  }
  
  // Update all volumes
  Future<void> _updateAllVolumes() async {
    await _backgroundMusicPlayer.setVolume(_musicVolume * _masterVolume);
    await _soundEffectsPlayer.setVolume(_sfxVolume * _masterVolume);
    await _uiPlayer.setVolume(_uiVolume * _masterVolume);
  }
  
  // Getters
  bool get isMuted => _isMuted;
  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  double get uiVolume => _uiVolume;
  
  // Convenience methods for common sounds
  Future<void> playCardLift() => playSound(AudioType.cardLift);
  Future<void> playCardDrop() => playSound(AudioType.cardDrop);
  Future<void> playSpellCast() => playSound(AudioType.spellCast);
  Future<void> playSpellResolve() => playSound(AudioType.spellResolve);
  Future<void> playAttack() => playSound(AudioType.attack);
  Future<void> playCriticalHit() => playSound(AudioType.criticalHit);
  Future<void> playSuperCritical() => playSound(AudioType.superCritical);
  Future<void> playDevastatingCritical() => playSound(AudioType.devastatingCritical);
  Future<void> playLevelUp() => playSound(AudioType.levelUp);
  Future<void> playVictory() => playSound(AudioType.victory);
  Future<void> playDefeat() => playSound(AudioType.defeat);
  Future<void> playError() => playSound(AudioType.error);
  Future<void> playTargetHover() => playSound(AudioType.targetHover);
  Future<void> playButtonClick() => playSound(AudioType.buttonClick);
  Future<void> playMenuOpen() => playSound(AudioType.menuOpen);
  Future<void> playMenuClose() => playSound(AudioType.menuClose);
  Future<void> playItemFound() => playSound(AudioType.itemFound);
  Future<void> playQuestComplete() => playSound(AudioType.questComplete);
  Future<void> playAchievement() => playSound(AudioType.achievement);
} 