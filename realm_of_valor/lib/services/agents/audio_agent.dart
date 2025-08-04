import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// Audio types
enum AudioType {
  music,
  sfx,
  ambient,
  voice,
  ui,
  spatial,
}

/// Audio priority levels
enum AudioPriority {
  low,
  medium,
  high,
  critical,
  interrupt, // Highest priority, interrupts everything
}

/// Audio state
enum AudioState {
  stopped,
  playing,
  paused,
  fading,
  loading,
}

/// Spatial audio positioning
class SpatialPosition {
  final double x;
  final double y;
  final double z;
  final double distance;
  final double volume;

  SpatialPosition({
    this.x = 0.0,
    this.y = 0.0,
    this.z = 0.0,
    this.distance = 1.0,
    this.volume = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'distance': distance,
      'volume': volume,
    };
  }

  factory SpatialPosition.fromJson(Map<String, dynamic> json) {
    return SpatialPosition(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      z: (json['z'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 1.0).toDouble(),
      volume: (json['volume'] ?? 1.0).toDouble(),
    );
  }
}

/// Audio track configuration
class AudioTrack {
  final String id;
  final String name;
  final String filePath;
  final AudioType type;
  final AudioPriority priority;
  final bool loop;
  final double volume;
  final double fadeInDuration;
  final double fadeOutDuration;
  final SpatialPosition? spatialPosition;
  final Map<String, dynamic> metadata;
  final List<String> tags;

  AudioTrack({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    this.priority = AudioPriority.medium,
    this.loop = false,
    this.volume = 1.0,
    this.fadeInDuration = 0.0,
    this.fadeOutDuration = 0.0,
    this.spatialPosition,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) : metadata = metadata ?? {},
       tags = tags ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'type': type.toString(),
      'priority': priority.toString(),
      'loop': loop,
      'volume': volume,
      'fadeInDuration': fadeInDuration,
      'fadeOutDuration': fadeOutDuration,
      'spatialPosition': spatialPosition?.toJson(),
      'metadata': metadata,
      'tags': tags,
    };
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'],
      name: json['name'],
      filePath: json['filePath'],
      type: AudioType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => AudioType.sfx,
      ),
      priority: AudioPriority.values.firstWhere(
        (p) => p.toString() == json['priority'],
        orElse: () => AudioPriority.medium,
      ),
      loop: json['loop'] ?? false,
      volume: (json['volume'] ?? 1.0).toDouble(),
      fadeInDuration: (json['fadeInDuration'] ?? 0.0).toDouble(),
      fadeOutDuration: (json['fadeOutDuration'] ?? 0.0).toDouble(),
      spatialPosition: json['spatialPosition'] != null 
          ? SpatialPosition.fromJson(json['spatialPosition'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// Active audio instance
class AudioInstance {
  final String id;
  final AudioTrack track;
  AudioState state;
  double currentVolume;
  DateTime startTime;
  Duration? duration;
  bool isFading;
  Timer? fadeTimer;

  AudioInstance({
    required this.id,
    required this.track,
    this.state = AudioState.stopped,
    double? currentVolume,
    DateTime? startTime,
    this.duration,
    this.isFading = false,
    this.fadeTimer,
  }) : currentVolume = currentVolume ?? track.volume,
       startTime = startTime ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'track': track.toJson(),
      'state': state.toString(),
      'currentVolume': currentVolume,
      'startTime': startTime.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'isFading': isFading,
    };
  }
}

/// Audio context for dynamic music system
class AudioContext {
  final String contextId;
  final String name;
  final Map<String, dynamic> properties;
  final List<String> musicTracks;
  final List<String> ambientTracks;
  final List<String> activeSfx;
  final double baseVolume;
  final Map<AudioType, double> volumeMultipliers;

  AudioContext({
    required this.contextId,
    required this.name,
    Map<String, dynamic>? properties,
    List<String>? musicTracks,
    List<String>? ambientTracks,
    List<String>? activeSfx,
    this.baseVolume = 1.0,
    Map<AudioType, double>? volumeMultipliers,
  }) : properties = properties ?? {},
       musicTracks = musicTracks ?? [],
       ambientTracks = ambientTracks ?? [],
       activeSfx = activeSfx ?? [],
       volumeMultipliers = volumeMultipliers ?? {};

  Map<String, dynamic> toJson() {
    return {
      'contextId': contextId,
      'name': name,
      'properties': properties,
      'musicTracks': musicTracks,
      'ambientTracks': ambientTracks,
      'activeSfx': activeSfx,
      'baseVolume': baseVolume,
      'volumeMultipliers': volumeMultipliers.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory AudioContext.fromJson(Map<String, dynamic> json) {
    final volumeMultipliers = <AudioType, double>{};
    final volumeData = json['volumeMultipliers'] as Map<String, dynamic>? ?? {};
    for (final entry in volumeData.entries) {
      final audioType = AudioType.values.firstWhere(
        (t) => t.toString() == entry.key,
        orElse: () => AudioType.sfx,
      );
      volumeMultipliers[audioType] = (entry.value as num).toDouble();
    }

    return AudioContext(
      contextId: json['contextId'],
      name: json['name'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      musicTracks: List<String>.from(json['musicTracks'] ?? []),
      ambientTracks: List<String>.from(json['ambientTracks'] ?? []),
      activeSfx: List<String>.from(json['activeSfx'] ?? []),
      baseVolume: (json['baseVolume'] ?? 1.0).toDouble(),
      volumeMultipliers: volumeMultipliers,
    );
  }
}

/// Audio settings
class AudioSettings {
  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final double ambientVolume;
  final double voiceVolume;
  final double uiVolume;
  final bool musicEnabled;
  final bool sfxEnabled;
  final bool ambientEnabled;
  final bool spatialAudioEnabled;
  final String audioQuality;

  AudioSettings({
    this.masterVolume = 1.0,
    this.musicVolume = 0.8,
    this.sfxVolume = 1.0,
    this.ambientVolume = 0.6,
    this.voiceVolume = 1.0,
    this.uiVolume = 0.8,
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.ambientEnabled = true,
    this.spatialAudioEnabled = true,
    this.audioQuality = 'high',
  });

  double getVolumeForType(AudioType type) {
    switch (type) {
      case AudioType.music:
        return musicEnabled ? masterVolume * musicVolume : 0.0;
      case AudioType.sfx:
        return sfxEnabled ? masterVolume * sfxVolume : 0.0;
      case AudioType.ambient:
        return ambientEnabled ? masterVolume * ambientVolume : 0.0;
      case AudioType.voice:
        return masterVolume * voiceVolume;
      case AudioType.ui:
        return masterVolume * uiVolume;
      case AudioType.spatial:
        return spatialAudioEnabled ? masterVolume * sfxVolume : 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'masterVolume': masterVolume,
      'musicVolume': musicVolume,
      'sfxVolume': sfxVolume,
      'ambientVolume': ambientVolume,
      'voiceVolume': voiceVolume,
      'uiVolume': uiVolume,
      'musicEnabled': musicEnabled,
      'sfxEnabled': sfxEnabled,
      'ambientEnabled': ambientEnabled,
      'spatialAudioEnabled': spatialAudioEnabled,
      'audioQuality': audioQuality,
    };
  }

  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      masterVolume: (json['masterVolume'] ?? 1.0).toDouble(),
      musicVolume: (json['musicVolume'] ?? 0.8).toDouble(),
      sfxVolume: (json['sfxVolume'] ?? 1.0).toDouble(),
      ambientVolume: (json['ambientVolume'] ?? 0.6).toDouble(),
      voiceVolume: (json['voiceVolume'] ?? 1.0).toDouble(),
      uiVolume: (json['uiVolume'] ?? 0.8).toDouble(),
      musicEnabled: json['musicEnabled'] ?? true,
      sfxEnabled: json['sfxEnabled'] ?? true,
      ambientEnabled: json['ambientEnabled'] ?? true,
      spatialAudioEnabled: json['spatialAudioEnabled'] ?? true,
      audioQuality: json['audioQuality'] ?? 'high',
    );
  }

  AudioSettings copyWith({
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
    double? ambientVolume,
    double? voiceVolume,
    double? uiVolume,
    bool? musicEnabled,
    bool? sfxEnabled,
    bool? ambientEnabled,
    bool? spatialAudioEnabled,
    String? audioQuality,
  }) {
    return AudioSettings(
      masterVolume: masterVolume ?? this.masterVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      ambientVolume: ambientVolume ?? this.ambientVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      uiVolume: uiVolume ?? this.uiVolume,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      ambientEnabled: ambientEnabled ?? this.ambientEnabled,
      spatialAudioEnabled: spatialAudioEnabled ?? this.spatialAudioEnabled,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }
}

/// Audio Agent - Immersive spatial audio and dynamic music
class AudioAgent extends BaseAgent {
  static const String _agentTypeId = 'audio';

  final SharedPreferences _prefs;

  // Current user context
  String? _currentUserId;

  // Audio system state
  AudioSettings _audioSettings = AudioSettings();
  AudioContext _currentContext = AudioContext(contextId: 'default', name: 'Default');

  // Audio management
  final Map<String, AudioTrack> _audioLibrary = {};
  final Map<String, AudioInstance> _activeInstances = {};
  final Map<String, AudioContext> _audioContexts = {};

  // Dynamic music system
  String? _currentMusicTrack;
  Timer? _musicTransitionTimer;
  Timer? _contextAnalysisTimer;

  // Spatial audio
  final Map<String, SpatialPosition> _spatialSources = {};
  SpatialPosition _listenerPosition = SpatialPosition();

  // Performance monitoring
  final List<Map<String, dynamic>> _audioMetrics = [];
  int _totalTracksPlayed = 0;
  DateTime? _lastAudioEvent;

  AudioAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: _agentTypeId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Audio Agent', name: _agentTypeId);

    // Load audio settings
    await _loadAudioSettings();

    // Load audio library
    await _loadAudioLibrary();

    // Load audio contexts
    await _loadAudioContexts();

    // Initialize default context
    await _initializeDefaultContext();

    // Start context analysis
    _startContextAnalysis();

    developer.log('Audio Agent initialized with ${_audioLibrary.length} tracks and ${_audioContexts.length} contexts', name: _agentTypeId);
  }

  @override
  void subscribeToEvents() {
    // Character events
    subscribe(EventTypes.characterLevelUp, _handleCharacterLevelUp);
    subscribe(EventTypes.characterStatsChanged, _handleStatsChanged);

    // Quest events
    subscribe(EventTypes.questStarted, _handleQuestStarted);
    subscribe(EventTypes.questCompleted, _handleQuestCompleted);
    subscribe(EventTypes.questProgress, _handleQuestProgress);

    // Battle events
    subscribe(EventTypes.battleStarted, _handleBattleStarted);
    subscribe(EventTypes.battleTurnResolved, _handleBattleTurn);
    subscribe(EventTypes.battleEnded, _handleBattleEnded);
    subscribe(EventTypes.battleResult, _handleBattleResult);

    // Location events
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);
    subscribe(EventTypes.poiDetected, _handlePOIDetected);
    subscribe(EventTypes.geofenceEntered, _handleGeofenceEntered);

    // Fitness events
    subscribe(EventTypes.fitnessUpdate, _handleFitnessUpdate);
    subscribe(EventTypes.activityDetected, _handleActivityDetected);

    // Card events
    subscribe(EventTypes.cardScanned, _handleCardScanned);
    subscribe(EventTypes.inventoryChanged, _handleInventoryChanged);

    // Achievement events
    subscribe(EventTypes.achievementUnlocked, _handleAchievementUnlocked);

    // AR events
    subscribe(EventTypes.arExperienceTriggered, _handleARExperience);

    // UI events
    subscribe(EventTypes.uiButtonPressed, _handleUIButtonPressed);
    subscribe(EventTypes.uiWindowOpened, _handleUIWindowOpened);
    subscribe(EventTypes.uiNotification, _handleUINotification);

    // Audio-specific events
    subscribe('audio_play', _handlePlayAudio);
    subscribe('audio_stop', _handleStopAudio);
    subscribe('audio_pause', _handlePauseAudio);
    subscribe('audio_resume', _handleResumeAudio);
    subscribe('audio_volume_change', _handleVolumeChange);
    subscribe('audio_context_change', _handleContextChange);
    subscribe('audio_spatial_update', _handleSpatialUpdate);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Play audio track
  String playAudio(String trackId, {
    double? volume,
    bool? loop,
    double? fadeInDuration,
    SpatialPosition? spatialPosition,
    Map<String, dynamic>? metadata,
  }) {
    final track = _audioLibrary[trackId];
    if (track == null) {
      developer.log('Audio track not found: $trackId', name: _agentTypeId);
      return '';
    }

    // Create audio instance
    final instanceId = 'instance_${DateTime.now().millisecondsSinceEpoch}';
    final instance = AudioInstance(
      id: instanceId,
      track: AudioTrack(
        id: track.id,
        name: track.name,
        filePath: track.filePath,
        type: track.type,
        priority: track.priority,
        loop: loop ?? track.loop,
        volume: volume ?? track.volume,
        fadeInDuration: fadeInDuration ?? track.fadeInDuration,
        fadeOutDuration: track.fadeOutDuration,
        spatialPosition: spatialPosition ?? track.spatialPosition,
        metadata: {...track.metadata, ...?metadata},
        tags: track.tags,
      ),
      state: AudioState.loading,
    );

    // Check priority and manage interruptions
    _handleAudioPriority(instance);

    // Calculate final volume with settings
    final finalVolume = _calculateFinalVolume(instance.track);
    instance.currentVolume = finalVolume;

    // Add to active instances
    _activeInstances[instanceId] = instance;

    // Simulate audio playing
    _simulateAudioPlayback(instance);

    // Publish audio event
    publishEvent(createEvent(
      eventType: 'audio_started',
      data: {
        'instanceId': instanceId,
        'trackId': trackId,
        'type': track.type.toString(),
        'priority': track.priority.toString(),
        'volume': finalVolume,
        'spatial': spatialPosition != null,
      },
    ));

    _logAudioMetric('track_played', {
      'trackId': trackId,
      'type': track.type.toString(),
      'priority': track.priority.toString(),
      'volume': finalVolume,
    });

    _totalTracksPlayed++;
    _lastAudioEvent = DateTime.now();

    developer.log('Playing audio: ${track.name} (ID: $instanceId)', name: _agentTypeId);
    return instanceId;
  }

  /// Stop audio instance
  bool stopAudio(String instanceId, {double? fadeOutDuration}) {
    final instance = _activeInstances[instanceId];
    if (instance == null) return false;

    final fadeTime = fadeOutDuration ?? instance.track.fadeOutDuration;
    
    if (fadeTime > 0) {
      _fadeOutAudio(instance, fadeTime);
    } else {
      _stopAudioImmediately(instance);
    }

    return true;
  }

  /// Stop all audio of a specific type
  void stopAudioByType(AudioType type, {double? fadeOutDuration}) {
    final instancesToStop = _activeInstances.values
        .where((instance) => instance.track.type == type)
        .toList();

    for (final instance in instancesToStop) {
      stopAudio(instance.id, fadeOutDuration: fadeOutDuration);
    }
  }

  /// Change audio context
  void changeAudioContext(String contextId) {
    final context = _audioContexts[contextId];
    if (context == null) {
      developer.log('Audio context not found: $contextId', name: _agentTypeId);
      return;
    }

    final previousContext = _currentContext.contextId;
    _currentContext = context;

    // Transition music if needed
    _transitionMusic();

    // Update ambient sounds
    _updateAmbientSounds();

    // Publish context change event
    publishEvent(createEvent(
      eventType: 'audio_context_changed',
      data: {
        'previousContext': previousContext,
        'newContext': contextId,
        'contextData': context.toJson(),
      },
    ));

    _logAudioMetric('context_changed', {
      'previousContext': previousContext,
      'newContext': contextId,
    });

    developer.log('Audio context changed: $previousContext -> $contextId', name: _agentTypeId);
  }

  /// Update spatial audio listener position
  void updateListenerPosition(SpatialPosition position) {
    _listenerPosition = position;
    
    // Update all spatial audio sources
    for (final instance in _activeInstances.values) {
      if (instance.track.spatialPosition != null) {
        _updateSpatialAudio(instance);
      }
    }

    publishEvent(createEvent(
      eventType: 'audio_spatial_updated',
      data: {
        'listenerPosition': position.toJson(),
        'spatialSources': _spatialSources.length,
      },
    ));
  }

  /// Update audio settings
  void updateAudioSettings(AudioSettings newSettings) {
    final previousSettings = _audioSettings;
    _audioSettings = newSettings;

    // Update volumes for all active instances
    for (final instance in _activeInstances.values) {
      final newVolume = _calculateFinalVolume(instance.track);
      _updateInstanceVolume(instance, newVolume);
    }

    // Save settings
    _saveAudioSettings();

    publishEvent(createEvent(
      eventType: 'audio_settings_changed',
      data: {
        'previousSettings': previousSettings.toJson(),
        'newSettings': newSettings.toJson(),
      },
    ));

    _logAudioMetric('settings_changed', {
      'masterVolume': newSettings.masterVolume,
      'musicEnabled': newSettings.musicEnabled,
      'sfxEnabled': newSettings.sfxEnabled,
    });
  }

  /// Get audio analytics
  Map<String, dynamic> getAudioAnalytics() {
    final activeByType = <String, int>{};
    for (final type in AudioType.values) {
      activeByType[type.toString()] = _activeInstances.values
          .where((instance) => instance.track.type == type)
          .length;
    }

    return {
      'totalTracksPlayed': _totalTracksPlayed,
      'activeInstances': _activeInstances.length,
      'currentContext': _currentContext.contextId,
      'activeByType': activeByType,
      'audioLibrarySize': _audioLibrary.length,
      'contextsAvailable': _audioContexts.length,
      'spatialSources': _spatialSources.length,
      'lastAudioEvent': _lastAudioEvent?.toIso8601String(),
      'audioSettings': _audioSettings.toJson(),
    };
  }

  /// Handle audio priority and interruptions
  void _handleAudioPriority(AudioInstance newInstance) {
    final newPriority = newInstance.track.priority;
    
    // Handle interrupt priority
    if (newPriority == AudioPriority.interrupt) {
      // Stop all other audio except higher priority interrupts
      final instancesToStop = _activeInstances.values
          .where((instance) => instance.track.priority != AudioPriority.interrupt)
          .toList();
      
      for (final instance in instancesToStop) {
        _pauseAudio(instance);
      }
      return;
    }

    // Handle music priority - only one music track at a time
    if (newInstance.track.type == AudioType.music) {
      final musicInstances = _activeInstances.values
          .where((instance) => instance.track.type == AudioType.music)
          .toList();
      
      for (final instance in musicInstances) {
        _fadeOutAudio(instance, 2.0); // 2 second fade out
      }
    }

    // Handle spatial audio conflicts
    if (newInstance.track.spatialPosition != null) {
      _manageSpatialAudioSources(newInstance);
    }
  }

  /// Calculate final volume with all modifiers
  double _calculateFinalVolume(AudioTrack track) {
    double volume = track.volume;
    
    // Apply audio settings
    volume *= _audioSettings.getVolumeForType(track.type);
    
    // Apply context modifiers
    final contextMultiplier = _currentContext.volumeMultipliers[track.type] ?? 1.0;
    volume *= contextMultiplier;
    
    // Apply base context volume
    volume *= _currentContext.baseVolume;

    // Apply spatial audio distance attenuation
    if (track.spatialPosition != null) {
      volume *= _calculateSpatialAttenuation(track.spatialPosition!);
    }

    return math.max(0.0, math.min(1.0, volume));
  }

  /// Calculate spatial audio attenuation
  double _calculateSpatialAttenuation(SpatialPosition position) {
    final distance = math.sqrt(
      math.pow(position.x - _listenerPosition.x, 2) +
      math.pow(position.y - _listenerPosition.y, 2) +
      math.pow(position.z - _listenerPosition.z, 2)
    );

    // Simple inverse distance attenuation
    final attenuation = 1.0 / (1.0 + distance * 0.1);
    return math.max(0.1, math.min(1.0, attenuation)) * position.volume;
  }

  /// Simulate audio playback (placeholder for actual audio system)
  void _simulateAudioPlayback(AudioInstance instance) {
    instance.state = AudioState.playing;
    
    // Simulate fade in
    if (instance.track.fadeInDuration > 0) {
      instance.isFading = true;
      Timer(Duration(milliseconds: (instance.track.fadeInDuration * 1000).round()), () {
        instance.isFading = false;
      });
    }

    // Simulate track duration (if not looping)
    if (!instance.track.loop) {
      final simulatedDuration = Duration(
        seconds: 30 + math.Random().nextInt(120), // Random 30-150 seconds
      );
      instance.duration = simulatedDuration;
      
      Timer(simulatedDuration, () {
        if (_activeInstances.containsKey(instance.id)) {
          _stopAudioImmediately(instance);
        }
      });
    }
  }

  /// Fade out audio
  void _fadeOutAudio(AudioInstance instance, double duration) {
    instance.isFading = true;
    instance.state = AudioState.fading;

    instance.fadeTimer = Timer(Duration(milliseconds: (duration * 1000).round()), () {
      _stopAudioImmediately(instance);
    });
  }

  /// Stop audio immediately
  void _stopAudioImmediately(AudioInstance instance) {
    instance.state = AudioState.stopped;
    instance.fadeTimer?.cancel();
    _activeInstances.remove(instance.id);

    publishEvent(createEvent(
      eventType: 'audio_stopped',
      data: {
        'instanceId': instance.id,
        'trackId': instance.track.id,
        'type': instance.track.type.toString(),
      },
    ));

    _logAudioMetric('track_stopped', {
      'trackId': instance.track.id,
      'type': instance.track.type.toString(),
      'duration': DateTime.now().difference(instance.startTime).inSeconds,
    });
  }

  /// Pause audio
  void _pauseAudio(AudioInstance instance) {
    if (instance.state == AudioState.playing) {
      instance.state = AudioState.paused;
    }
  }

  /// Resume audio
  void _resumeAudio(AudioInstance instance) {
    if (instance.state == AudioState.paused) {
      instance.state = AudioState.playing;
    }
  }

  /// Update instance volume
  void _updateInstanceVolume(AudioInstance instance, double newVolume) {
    instance.currentVolume = newVolume;
    // In a real implementation, this would update the actual audio player volume
  }

  /// Update spatial audio for instance
  void _updateSpatialAudio(AudioInstance instance) {
    if (instance.track.spatialPosition == null) return;

    final newVolume = _calculateFinalVolume(instance.track);
    _updateInstanceVolume(instance, newVolume);
  }

  /// Manage spatial audio sources
  void _manageSpatialAudioSources(AudioInstance newInstance) {
    if (newInstance.track.spatialPosition == null) return;

    _spatialSources[newInstance.id] = newInstance.track.spatialPosition!;
    
    // Limit number of spatial sources for performance
    if (_spatialSources.length > 8) {
      // Remove oldest/furthest sources
      final sortedSources = _spatialSources.entries.toList()
        ..sort((a, b) => b.value.distance.compareTo(a.value.distance));
      
      for (int i = 8; i < sortedSources.length; i++) {
        final instanceId = sortedSources[i].key;
        _spatialSources.remove(instanceId);
        stopAudio(instanceId, fadeOutDuration: 1.0);
      }
    }
  }

  /// Transition music based on context
  void _transitionMusic() {
    if (_currentContext.musicTracks.isEmpty) {
      // Stop current music
      stopAudioByType(AudioType.music, fadeOutDuration: 3.0);
      _currentMusicTrack = null;
      return;
    }

    // Select appropriate music track
    final newTrack = _selectContextualMusic();
    if (newTrack != null && newTrack != _currentMusicTrack) {
      // Stop current music
      stopAudioByType(AudioType.music, fadeOutDuration: 2.0);
      
      // Start new music after brief pause
      Timer(const Duration(seconds: 3), () {
        _currentMusicTrack = newTrack;
        playAudio(newTrack, fadeInDuration: 2.0, loop: true);
      });
    }
  }

  /// Select contextual music based on current state
  String? _selectContextualMusic() {
    final availableTracks = _currentContext.musicTracks;
    if (availableTracks.isEmpty) return null;

    // Simple selection logic - could be enhanced with more sophisticated algorithms
    final random = math.Random();
    return availableTracks[random.nextInt(availableTracks.length)];
  }

  /// Update ambient sounds for current context
  void _updateAmbientSounds() {
    // Stop current ambient sounds
    stopAudioByType(AudioType.ambient, fadeOutDuration: 1.5);

    // Start new ambient sounds
    for (final trackId in _currentContext.ambientTracks) {
      Timer(Duration(milliseconds: 500 + math.Random().nextInt(1000)), () {
        playAudio(trackId, loop: true, fadeInDuration: 2.0);
      });
    }
  }

  /// Start context analysis timer
  void _startContextAnalysis() {
    _contextAnalysisTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _analyzeAudioContext();
    });
  }

  /// Analyze current context and adjust audio
  void _analyzeAudioContext() {
    // This could analyze current game state and automatically adjust audio context
    // For now, we'll just clean up finished audio instances
    
    final finishedInstances = _activeInstances.values
        .where((instance) => instance.state == AudioState.stopped)
        .toList();

    for (final instance in finishedInstances) {
      _activeInstances.remove(instance.id);
      _spatialSources.remove(instance.id);
    }
  }

  /// Initialize default audio context
  Future<void> _initializeDefaultContext() async {
    _audioContexts['default'] = AudioContext(
      contextId: 'default',
      name: 'Default Context',
      musicTracks: ['theme_main', 'ambient_exploration'],
      ambientTracks: ['wind_gentle', 'nature_sounds'],
      baseVolume: 1.0,
      volumeMultipliers: {
        AudioType.music: 0.8,
        AudioType.ambient: 0.6,
        AudioType.sfx: 1.0,
      },
    );

    // Add more contexts
    _audioContexts.addAll({
      'battle': AudioContext(
        contextId: 'battle',
        name: 'Battle Context',
        musicTracks: ['battle_intense', 'battle_epic'],
        ambientTracks: [],
        baseVolume: 1.0,
        volumeMultipliers: {
          AudioType.music: 1.0,
          AudioType.sfx: 1.2,
          AudioType.ambient: 0.3,
        },
      ),
      'exploration': AudioContext(
        contextId: 'exploration',
        name: 'Exploration Context',
        musicTracks: ['ambient_exploration', 'peaceful_journey'],
        ambientTracks: ['wind_gentle', 'nature_sounds', 'birds_chirping'],
        baseVolume: 0.9,
        volumeMultipliers: {
          AudioType.music: 0.7,
          AudioType.ambient: 0.8,
          AudioType.sfx: 0.9,
        },
      ),
      'urban': AudioContext(
        contextId: 'urban',
        name: 'Urban Context',
        musicTracks: ['urban_adventure', 'city_beats'],
        ambientTracks: ['traffic_distant', 'city_hum'],
        baseVolume: 1.0,
        volumeMultipliers: {
          AudioType.music: 0.8,
          AudioType.ambient: 0.7,
          AudioType.sfx: 1.0,
        },
      ),
      'ar_experience': AudioContext(
        contextId: 'ar_experience',
        name: 'AR Experience Context',
        musicTracks: ['magical_theme', 'mystery_ambient'],
        ambientTracks: ['magical_shimmer'],
        baseVolume: 1.0,
        volumeMultipliers: {
          AudioType.music: 0.6,
          AudioType.spatial: 1.2,
          AudioType.sfx: 1.1,
        },
      ),
    });
  }

  /// Load audio library
  Future<void> _loadAudioLibrary() async {
    // Initialize with sample audio tracks
    _audioLibrary.addAll({
      // Music tracks
      'theme_main': AudioTrack(
        id: 'theme_main',
        name: 'Main Theme',
        filePath: 'assets/audio/music/theme_main.mp3',
        type: AudioType.music,
        priority: AudioPriority.medium,
        loop: true,
        volume: 0.8,
        fadeInDuration: 3.0,
        fadeOutDuration: 2.0,
        tags: ['theme', 'orchestral', 'epic'],
      ),
      'battle_intense': AudioTrack(
        id: 'battle_intense',
        name: 'Intense Battle',
        filePath: 'assets/audio/music/battle_intense.mp3',
        type: AudioType.music,
        priority: AudioPriority.high,
        loop: true,
        volume: 0.9,
        tags: ['battle', 'action', 'drums'],
      ),
      'ambient_exploration': AudioTrack(
        id: 'ambient_exploration',
        name: 'Exploration Ambient',
        filePath: 'assets/audio/music/ambient_exploration.mp3',
        type: AudioType.music,
        priority: AudioPriority.medium,
        loop: true,
        volume: 0.6,
        tags: ['ambient', 'peaceful', 'exploration'],
      ),

      // SFX tracks
      'ui_button_click': AudioTrack(
        id: 'ui_button_click',
        name: 'Button Click',
        filePath: 'assets/audio/sfx/ui_button_click.wav',
        type: AudioType.ui,
        priority: AudioPriority.low,
        volume: 0.7,
        tags: ['ui', 'click'],
      ),
      'sword_swing': AudioTrack(
        id: 'sword_swing',
        name: 'Sword Swing',
        filePath: 'assets/audio/sfx/sword_swing.wav',
        type: AudioType.sfx,
        priority: AudioPriority.medium,
        volume: 0.8,
        tags: ['weapon', 'sword', 'combat'],
      ),
      'level_up_fanfare': AudioTrack(
        id: 'level_up_fanfare',
        name: 'Level Up Fanfare',
        filePath: 'assets/audio/sfx/level_up_fanfare.wav',
        type: AudioType.sfx,
        priority: AudioPriority.high,
        volume: 0.9,
        tags: ['achievement', 'fanfare', 'positive'],
      ),
      'quest_complete_chime': AudioTrack(
        id: 'quest_complete_chime',
        name: 'Quest Complete Chime',
        filePath: 'assets/audio/sfx/quest_complete_chime.wav',
        type: AudioType.sfx,
        priority: AudioPriority.high,
        volume: 0.8,
        tags: ['quest', 'complete', 'chime'],
      ),
      'card_scan_beep': AudioTrack(
        id: 'card_scan_beep',
        name: 'Card Scan Beep',
        filePath: 'assets/audio/sfx/card_scan_beep.wav',
        type: AudioType.sfx,
        priority: AudioPriority.medium,
        volume: 0.6,
        tags: ['card', 'scan', 'technology'],
      ),

      // Ambient tracks
      'wind_gentle': AudioTrack(
        id: 'wind_gentle',
        name: 'Gentle Wind',
        filePath: 'assets/audio/ambient/wind_gentle.wav',
        type: AudioType.ambient,
        priority: AudioPriority.low,
        loop: true,
        volume: 0.4,
        tags: ['wind', 'nature', 'peaceful'],
      ),
      'nature_sounds': AudioTrack(
        id: 'nature_sounds',
        name: 'Nature Sounds',
        filePath: 'assets/audio/ambient/nature_sounds.wav',
        type: AudioType.ambient,
        priority: AudioPriority.low,
        loop: true,
        volume: 0.5,
        tags: ['nature', 'forest', 'ambient'],
      ),
      'city_hum': AudioTrack(
        id: 'city_hum',
        name: 'City Hum',
        filePath: 'assets/audio/ambient/city_hum.wav',
        type: AudioType.ambient,
        priority: AudioPriority.low,
        loop: true,
        volume: 0.3,
        tags: ['city', 'urban', 'traffic'],
      ),

      // Spatial audio examples
      'treasure_sparkle': AudioTrack(
        id: 'treasure_sparkle',
        name: 'Treasure Sparkle',
        filePath: 'assets/audio/spatial/treasure_sparkle.wav',
        type: AudioType.spatial,
        priority: AudioPriority.medium,
        volume: 0.7,
        spatialPosition: SpatialPosition(x: 0, y: 0, z: 0, distance: 1.0),
        tags: ['treasure', 'magical', 'sparkle'],
      ),
    });

    developer.log('Loaded ${_audioLibrary.length} audio tracks', name: _agentTypeId);
  }

  /// Load audio contexts
  Future<void> _loadAudioContexts() async {
    final contextsJson = _prefs.getString('audio_contexts');
    if (contextsJson != null) {
      try {
        final data = jsonDecode(contextsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _audioContexts[entry.key] = AudioContext.fromJson(entry.value);
        }
      } catch (e) {
        developer.log('Error loading audio contexts: $e', name: _agentTypeId);
      }
    }
  }

  /// Save audio contexts
  Future<void> _saveAudioContexts() async {
    final data = _audioContexts.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString('audio_contexts', jsonEncode(data));
  }

  /// Load audio settings
  Future<void> _loadAudioSettings() async {
    final settingsJson = _prefs.getString('audio_settings');
    if (settingsJson != null) {
      try {
        final data = jsonDecode(settingsJson) as Map<String, dynamic>;
        _audioSettings = AudioSettings.fromJson(data);
      } catch (e) {
        developer.log('Error loading audio settings: $e', name: _agentTypeId);
      }
    }
  }

  /// Save audio settings
  Future<void> _saveAudioSettings() async {
    await _prefs.setString('audio_settings', jsonEncode(_audioSettings.toJson()));
  }

  /// Log audio metric
  void _logAudioMetric(String metricType, Map<String, dynamic> data) {
    _audioMetrics.add({
      'metricType': metricType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 metrics
    if (_audioMetrics.length > 100) {
      _audioMetrics.removeAt(0);
    }
  }

  // Event Handlers

  /// Handle character level up events
  Future<AgentEventResponse?> _handleCharacterLevelUp(AgentEvent event) async {
    playAudio('level_up_fanfare');

    return createResponse(
      originalEventId: event.id,
      responseType: 'level_up_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle stats changed events
  Future<AgentEventResponse?> _handleStatsChanged(AgentEvent event) async {
    // Play subtle stat change sound
    playAudio('ui_button_click', volume: 0.5);

    return createResponse(
      originalEventId: event.id,
      responseType: 'stats_change_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle quest started events
  Future<AgentEventResponse?> _handleQuestStarted(AgentEvent event) async {
    playAudio('quest_complete_chime', volume: 0.7);

    // Change to exploration context if not in battle
    if (_currentContext.contextId != 'battle') {
      changeAudioContext('exploration');
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_start_audio_played',
      data: {'audioPlayed': true, 'contextChanged': true},
    );
  }

  /// Handle quest completed events
  Future<AgentEventResponse?> _handleQuestCompleted(AgentEvent event) async {
    playAudio('quest_complete_chime');

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_complete_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle quest progress events
  Future<AgentEventResponse?> _handleQuestProgress(AgentEvent event) async {
    // Subtle progress sound
    playAudio('ui_button_click', volume: 0.3);

    return createResponse(
      originalEventId: event.id,
      responseType: 'quest_progress_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle battle started events
  Future<AgentEventResponse?> _handleBattleStarted(AgentEvent event) async {
    changeAudioContext('battle');
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_audio_context_activated',
      data: {'contextChanged': 'battle'},
    );
  }

  /// Handle battle turn events
  Future<AgentEventResponse?> _handleBattleTurn(AgentEvent event) async {
    final actionType = event.data['actionType'];
    
    if (actionType == 'attack') {
      playAudio('sword_swing', volume: 0.8);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_turn_audio_played',
      data: {'actionType': actionType, 'audioPlayed': true},
    );
  }

  /// Handle battle ended events
  Future<AgentEventResponse?> _handleBattleEnded(AgentEvent event) async {
    // Return to previous context (usually exploration)
    changeAudioContext('exploration');

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_audio_context_deactivated',
      data: {'contextChanged': 'exploration'},
    );
  }

  /// Handle battle result events
  Future<AgentEventResponse?> _handleBattleResult(AgentEvent event) async {
    final isVictory = event.data['isVictory'] ?? false;
    
    if (isVictory) {
      playAudio('level_up_fanfare', volume: 0.8);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'battle_result_audio_played',
      data: {'isVictory': isVictory, 'audioPlayed': true},
    );
  }

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    final location = event.data['location'];
    
    if (location != null) {
      // Update listener position for spatial audio
      updateListenerPosition(SpatialPosition(
        x: location['latitude']?.toDouble() ?? 0.0,
        y: location['longitude']?.toDouble() ?? 0.0,
        z: location['altitude']?.toDouble() ?? 0.0,
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'location_audio_updated',
      data: {'spatialUpdated': true},
    );
  }

  /// Handle POI detected events
  Future<AgentEventResponse?> _handlePOIDetected(AgentEvent event) async {
    // Play spatial treasure sound if POI has rewards
    final poi = event.data['poi'];
    if (poi != null && poi['rewards'] != null) {
      final distance = event.data['distance'] ?? 50.0;
      
      playAudio('treasure_sparkle', 
        spatialPosition: SpatialPosition(
          x: 10.0, y: 0.0, z: 0.0,
          distance: distance / 100.0, // Normalize distance
          volume: math.max(0.2, 1.0 - (distance / 100.0)),
        )
      );
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'poi_audio_played',
      data: {'spatialAudioPlayed': true},
    );
  }

  /// Handle geofence entered events
  Future<AgentEventResponse?> _handleGeofenceEntered(AgentEvent event) async {
    // Play location entry sound
    playAudio('ui_button_click', volume: 0.6);

    return createResponse(
      originalEventId: event.id,
      responseType: 'geofence_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle fitness update events
  Future<AgentEventResponse?> _handleFitnessUpdate(AgentEvent event) async {
    // No audio for regular fitness updates to avoid spam
    return createResponse(
      originalEventId: event.id,
      responseType: 'fitness_update_audio_processed',
      data: {'audioPlayed': false},
    );
  }

  /// Handle activity detected events
  Future<AgentEventResponse?> _handleActivityDetected(AgentEvent event) async {
    // Play subtle activity confirmation
    playAudio('ui_button_click', volume: 0.4);

    return createResponse(
      originalEventId: event.id,
      responseType: 'activity_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle card scanned events
  Future<AgentEventResponse?> _handleCardScanned(AgentEvent event) async {
    playAudio('card_scan_beep');

    return createResponse(
      originalEventId: event.id,
      responseType: 'card_scan_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle inventory changed events
  Future<AgentEventResponse?> _handleInventoryChanged(AgentEvent event) async {
    final itemsGained = event.data['itemsGained'] ?? [];
    
    if (itemsGained.isNotEmpty) {
      playAudio('ui_button_click', volume: 0.6);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'inventory_audio_played',
      data: {'itemsGained': itemsGained.length, 'audioPlayed': itemsGained.isNotEmpty},
    );
  }

  /// Handle achievement unlocked events
  Future<AgentEventResponse?> _handleAchievementUnlocked(AgentEvent event) async {
    playAudio('level_up_fanfare', volume: 0.9);

    return createResponse(
      originalEventId: event.id,
      responseType: 'achievement_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle AR experience events
  Future<AgentEventResponse?> _handleARExperience(AgentEvent event) async {
    changeAudioContext('ar_experience');

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_audio_context_activated',
      data: {'contextChanged': 'ar_experience'},
    );
  }

  /// Handle UI button pressed events
  Future<AgentEventResponse?> _handleUIButtonPressed(AgentEvent event) async {
    playAudio('ui_button_click', volume: 0.5);

    return createResponse(
      originalEventId: event.id,
      responseType: 'ui_button_audio_played',
      data: {'audioPlayed': true},
    );
  }

  /// Handle UI window opened events
  Future<AgentEventResponse?> _handleUIWindowOpened(AgentEvent event) async {
    final currentScreen = event.data['currentScreen'];
    
    // Change audio context based on screen
    switch (currentScreen) {
      case 'battle':
        changeAudioContext('battle');
        break;
      case 'map':
        changeAudioContext('exploration');
        break;
      default:
        // Stay in current context or use default
        break;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ui_window_audio_processed',
      data: {'currentScreen': currentScreen},
    );
  }

  /// Handle UI notification events
  Future<AgentEventResponse?> _handleUINotification(AgentEvent event) async {
    final notificationType = event.data['type'];
    
    // Play different sounds for different notification types
    switch (notificationType) {
      case 'NotificationType.achievement':
      case 'NotificationType.levelUp':
        playAudio('level_up_fanfare', volume: 0.7);
        break;
      case 'NotificationType.questComplete':
        playAudio('quest_complete_chime', volume: 0.8);
        break;
      default:
        playAudio('ui_button_click', volume: 0.6);
        break;
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'notification_audio_played',
      data: {'notificationType': notificationType, 'audioPlayed': true},
    );
  }

  /// Handle play audio events
  Future<AgentEventResponse?> _handlePlayAudio(AgentEvent event) async {
    final trackId = event.data['trackId'];
    final volume = event.data['volume']?.toDouble();
    final loop = event.data['loop'];
    final fadeInDuration = event.data['fadeInDuration']?.toDouble();

    if (trackId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'play_audio_failed',
        data: {'error': 'No track ID provided'},
        success: false,
      );
    }

    final instanceId = playAudio(
      trackId,
      volume: volume,
      loop: loop,
      fadeInDuration: fadeInDuration,
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'audio_played',
      data: {
        'trackId': trackId,
        'instanceId': instanceId,
        'success': instanceId.isNotEmpty,
      },
      success: instanceId.isNotEmpty,
    );
  }

  /// Handle stop audio events
  Future<AgentEventResponse?> _handleStopAudio(AgentEvent event) async {
    final instanceId = event.data['instanceId'];
    final fadeOutDuration = event.data['fadeOutDuration']?.toDouble();

    if (instanceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'stop_audio_failed',
        data: {'error': 'No instance ID provided'},
        success: false,
      );
    }

    final success = stopAudio(instanceId, fadeOutDuration: fadeOutDuration);

    return createResponse(
      originalEventId: event.id,
      responseType: 'audio_stopped',
      data: {'instanceId': instanceId, 'success': success},
      success: success,
    );
  }

  /// Handle pause audio events
  Future<AgentEventResponse?> _handlePauseAudio(AgentEvent event) async {
    final instanceId = event.data['instanceId'];

    if (instanceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'pause_audio_failed',
        data: {'error': 'No instance ID provided'},
        success: false,
      );
    }

    final instance = _activeInstances[instanceId];
    if (instance != null) {
      _pauseAudio(instance);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'audio_paused',
      data: {'instanceId': instanceId, 'success': instance != null},
      success: instance != null,
    );
  }

  /// Handle resume audio events
  Future<AgentEventResponse?> _handleResumeAudio(AgentEvent event) async {
    final instanceId = event.data['instanceId'];

    if (instanceId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'resume_audio_failed',
        data: {'error': 'No instance ID provided'},
        success: false,
      );
    }

    final instance = _activeInstances[instanceId];
    if (instance != null) {
      _resumeAudio(instance);
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'audio_resumed',
      data: {'instanceId': instanceId, 'success': instance != null},
      success: instance != null,
    );
  }

  /// Handle volume change events
  Future<AgentEventResponse?> _handleVolumeChange(AgentEvent event) async {
    final audioType = event.data['audioType'];
    final volume = event.data['volume']?.toDouble();

    if (volume == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'volume_change_failed',
        data: {'error': 'No volume provided'},
        success: false,
      );
    }

    // Update settings based on audio type
    AudioSettings newSettings = _audioSettings;
    
    switch (audioType) {
      case 'master':
        newSettings = _audioSettings.copyWith(masterVolume: volume);
        break;
      case 'music':
        newSettings = _audioSettings.copyWith(musicVolume: volume);
        break;
      case 'sfx':
        newSettings = _audioSettings.copyWith(sfxVolume: volume);
        break;
      case 'ambient':
        newSettings = _audioSettings.copyWith(ambientVolume: volume);
        break;
      case 'voice':
        newSettings = _audioSettings.copyWith(voiceVolume: volume);
        break;
      case 'ui':
        newSettings = _audioSettings.copyWith(uiVolume: volume);
        break;
    }

    updateAudioSettings(newSettings);

    return createResponse(
      originalEventId: event.id,
      responseType: 'volume_changed',
      data: {'audioType': audioType, 'volume': volume},
    );
  }

  /// Handle context change events
  Future<AgentEventResponse?> _handleContextChange(AgentEvent event) async {
    final contextId = event.data['contextId'];

    if (contextId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'context_change_failed',
        data: {'error': 'No context ID provided'},
        success: false,
      );
    }

    changeAudioContext(contextId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'audio_context_changed',
      data: {'contextId': contextId},
    );
  }

  /// Handle spatial update events
  Future<AgentEventResponse?> _handleSpatialUpdate(AgentEvent event) async {
    final position = event.data['position'];

    if (position != null) {
      updateListenerPosition(SpatialPosition.fromJson(position));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'spatial_audio_updated',
      data: {'positionUpdated': position != null},
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    final userId = event.data['userId'];
    _currentUserId = userId;

    // Load user-specific audio settings
    await _loadAudioSettings();

    // Start with default context
    changeAudioContext('default');

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_audio_processed',
      data: {'userId': userId},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    // Save settings
    await _saveAudioSettings();
    await _saveAudioContexts();

    // Stop all audio
    for (final instanceId in _activeInstances.keys.toList()) {
      stopAudio(instanceId, fadeOutDuration: 1.0);
    }

    _currentUserId = null;

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_audio_processed',
      data: {'audioStopped': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Cancel timers
    _musicTransitionTimer?.cancel();
    _contextAnalysisTimer?.cancel();

    // Stop all audio
    for (final instance in _activeInstances.values) {
      instance.fadeTimer?.cancel();
    }
    _activeInstances.clear();

    // Save settings
    await _saveAudioSettings();
    await _saveAudioContexts();

    developer.log('Audio Agent disposed', name: _agentTypeId);
  }
}