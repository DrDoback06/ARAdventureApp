import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// AR tracking state
enum ARTrackingState {
  notAvailable,
  initializing,
  tracking,
  limitedTracking,
  stopped,
}

/// AR anchor types
enum ARAnchorType {
  plane,
  image,
  object,
  location,
  face,
  body,
}

/// AR rendering modes
enum ARRenderingMode {
  standard,
  occlusion,
  lightEstimation,
  environmentProbe,
  shadowReceiving,
}

/// AR session configuration
enum ARSessionConfiguration {
  worldTracking,
  orientationTracking,
  faceTracking,
  imageTracking,
  objectTracking,
  geoTracking,
}

/// 3D Vector for AR positioning
class ARVector3 {
  final double x;
  final double y;
  final double z;

  const ARVector3(this.x, this.y, this.z);

  ARVector3 operator +(ARVector3 other) {
    return ARVector3(x + other.x, y + other.y, z + other.z);
  }

  ARVector3 operator -(ARVector3 other) {
    return ARVector3(x - other.x, y - other.y, z - other.z);
  }

  ARVector3 operator *(double scalar) {
    return ARVector3(x * scalar, y * scalar, z * scalar);
  }

  double get magnitude => math.sqrt(x * x + y * y + z * z);

  ARVector3 get normalized {
    final mag = magnitude;
    return mag > 0 ? ARVector3(x / mag, y / mag, z / mag) : const ARVector3(0, 0, 0);
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};

  factory ARVector3.fromJson(Map<String, dynamic> json) {
    return ARVector3(
      (json['x'] ?? 0.0).toDouble(),
      (json['y'] ?? 0.0).toDouble(),
      (json['z'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() => 'ARVector3($x, $y, $z)';
}

/// 4x4 transformation matrix for AR objects
class ARMatrix4 {
  final List<double> matrix;

  ARMatrix4(this.matrix) : assert(matrix.length == 16);

  factory ARMatrix4.identity() {
    return ARMatrix4([
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
  }

  factory ARMatrix4.translation(ARVector3 translation) {
    return ARMatrix4([
      1, 0, 0, translation.x,
      0, 1, 0, translation.y,
      0, 0, 1, translation.z,
      0, 0, 0, 1,
    ]);
  }

  factory ARMatrix4.rotationY(double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return ARMatrix4([
      cos, 0, sin, 0,
      0, 1, 0, 0,
      -sin, 0, cos, 0,
      0, 0, 0, 1,
    ]);
  }

  ARVector3 get translation => ARVector3(matrix[3], matrix[7], matrix[11]);

  Map<String, dynamic> toJson() => {'matrix': matrix};

  factory ARMatrix4.fromJson(Map<String, dynamic> json) {
    return ARMatrix4(List<double>.from(json['matrix'] ?? []));
  }
}

/// AR anchor representing a tracked point in 3D space
class ARAnchor {
  final String anchorId;
  final ARAnchorType type;
  final ARMatrix4 transform;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isTracking;
  final Map<String, dynamic> metadata;

  ARAnchor({
    String? anchorId,
    required this.type,
    required this.transform,
    DateTime? createdAt,
    DateTime? lastUpdated,
    this.isTracking = true,
    Map<String, dynamic>? metadata,
  }) : anchorId = anchorId ?? 'anchor_${DateTime.now().millisecondsSinceEpoch}',
       createdAt = createdAt ?? DateTime.now(),
       lastUpdated = lastUpdated ?? DateTime.now(),
       metadata = metadata ?? {};

  ARAnchor copyWith({
    ARMatrix4? transform,
    DateTime? lastUpdated,
    bool? isTracking,
    Map<String, dynamic>? metadata,
  }) {
    return ARAnchor(
      anchorId: anchorId,
      type: type,
      transform: transform ?? this.transform,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      isTracking: isTracking ?? this.isTracking,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anchorId': anchorId,
      'type': type.toString(),
      'transform': transform.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isTracking': isTracking,
      'metadata': metadata,
    };
  }

  factory ARAnchor.fromJson(Map<String, dynamic> json) {
    return ARAnchor(
      anchorId: json['anchorId'],
      type: ARAnchorType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => ARAnchorType.plane,
      ),
      transform: ARMatrix4.fromJson(json['transform']),
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isTracking: json['isTracking'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// AR object to be rendered in 3D space
class ARObject {
  final String objectId;
  final String modelPath;
  final String? texturePath;
  final ARAnchor anchor;
  final ARVector3 scale;
  final ARVector3 rotation;
  final Map<String, dynamic> animations;
  final Map<String, dynamic> properties;
  final bool isVisible;
  final double opacity;
  final String? parentObjectId;

  ARObject({
    String? objectId,
    required this.modelPath,
    this.texturePath,
    required this.anchor,
    this.scale = const ARVector3(1, 1, 1),
    this.rotation = const ARVector3(0, 0, 0),
    Map<String, dynamic>? animations,
    Map<String, dynamic>? properties,
    this.isVisible = true,
    this.opacity = 1.0,
    this.parentObjectId,
  }) : objectId = objectId ?? 'object_${DateTime.now().millisecondsSinceEpoch}',
       animations = animations ?? {},
       properties = properties ?? {};

  ARObject copyWith({
    String? modelPath,
    String? texturePath,
    ARAnchor? anchor,
    ARVector3? scale,
    ARVector3? rotation,
    Map<String, dynamic>? animations,
    Map<String, dynamic>? properties,
    bool? isVisible,
    double? opacity,
    String? parentObjectId,
  }) {
    return ARObject(
      objectId: objectId,
      modelPath: modelPath ?? this.modelPath,
      texturePath: texturePath ?? this.texturePath,
      anchor: anchor ?? this.anchor,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      animations: animations ?? Map.from(this.animations),
      properties: properties ?? Map.from(this.properties),
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      parentObjectId: parentObjectId ?? this.parentObjectId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'modelPath': modelPath,
      'texturePath': texturePath,
      'anchor': anchor.toJson(),
      'scale': scale.toJson(),
      'rotation': rotation.toJson(),
      'animations': animations,
      'properties': properties,
      'isVisible': isVisible,
      'opacity': opacity,
      'parentObjectId': parentObjectId,
    };
  }

  factory ARObject.fromJson(Map<String, dynamic> json) {
    return ARObject(
      objectId: json['objectId'],
      modelPath: json['modelPath'],
      texturePath: json['texturePath'],
      anchor: ARAnchor.fromJson(json['anchor']),
      scale: ARVector3.fromJson(json['scale']),
      rotation: ARVector3.fromJson(json['rotation']),
      animations: Map<String, dynamic>.from(json['animations'] ?? {}),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      isVisible: json['isVisible'] ?? true,
      opacity: (json['opacity'] ?? 1.0).toDouble(),
      parentObjectId: json['parentObjectId'],
    );
  }
}

/// AR session state and configuration
class ARSession {
  final String sessionId;
  final ARSessionConfiguration configuration;
  final ARTrackingState trackingState;
  final Map<String, dynamic> capabilities;
  final DateTime startTime;
  final int frameCount;
  final double frameRate;
  final ARVector3? lightEstimate;
  final List<String> detectedPlanes;

  ARSession({
    String? sessionId,
    required this.configuration,
    this.trackingState = ARTrackingState.initializing,
    Map<String, dynamic>? capabilities,
    DateTime? startTime,
    this.frameCount = 0,
    this.frameRate = 60.0,
    this.lightEstimate,
    List<String>? detectedPlanes,
  }) : sessionId = sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
       capabilities = capabilities ?? {},
       startTime = startTime ?? DateTime.now(),
       detectedPlanes = detectedPlanes ?? [];

  ARSession copyWith({
    ARTrackingState? trackingState,
    int? frameCount,
    double? frameRate,
    ARVector3? lightEstimate,
    List<String>? detectedPlanes,
  }) {
    return ARSession(
      sessionId: sessionId,
      configuration: configuration,
      trackingState: trackingState ?? this.trackingState,
      capabilities: capabilities,
      startTime: startTime,
      frameCount: frameCount ?? this.frameCount,
      frameRate: frameRate ?? this.frameRate,
      lightEstimate: lightEstimate ?? this.lightEstimate,
      detectedPlanes: detectedPlanes ?? List.from(this.detectedPlanes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'configuration': configuration.toString(),
      'trackingState': trackingState.toString(),
      'capabilities': capabilities,
      'startTime': startTime.toIso8601String(),
      'frameCount': frameCount,
      'frameRate': frameRate,
      'lightEstimate': lightEstimate?.toJson(),
      'detectedPlanes': detectedPlanes,
    };
  }
}

/// AR interaction event
class ARInteraction {
  final String interactionId;
  final String objectId;
  final String type; // tap, gesture, proximity, collision
  final ARVector3 position;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ARInteraction({
    String? interactionId,
    required this.objectId,
    required this.type,
    required this.position,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) : interactionId = interactionId ?? 'interaction_${DateTime.now().millisecondsSinceEpoch}',
       data = data ?? {},
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'interactionId': interactionId,
      'objectId': objectId,
      'type': type,
      'position': position.toJson(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ARInteraction.fromJson(Map<String, dynamic> json) {
    return ARInteraction(
      interactionId: json['interactionId'],
      objectId: json['objectId'],
      type: json['type'],
      position: ARVector3.fromJson(json['position']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// AR Rendering Agent - Advanced 3D AR content and object tracking
class ARRenderingAgent extends BaseAgent {
  static const String _agentTypeId = 'ar_rendering';

  final SharedPreferences _prefs;

  // Current AR session
  ARSession? _currentSession;
  ARTrackingState _trackingState = ARTrackingState.notAvailable;

  // AR object management
  final Map<String, ARAnchor> _anchors = {};
  final Map<String, ARObject> _objects = {};
  final Map<String, ARInteraction> _interactions = {};

  // Rendering state
  ARRenderingMode _renderingMode = ARRenderingMode.standard;
  double _renderScale = 1.0;
  bool _occlusionEnabled = true;
  bool _lightEstimationEnabled = true;
  bool _shadowsEnabled = true;

  // Performance monitoring
  final List<Map<String, dynamic>> _performanceMetrics = [];
  Timer? _performanceTimer;
  int _totalFramesRendered = 0;
  double _averageFrameTime = 16.67; // 60 FPS target

  // AR content library
  final Map<String, Map<String, dynamic>> _arModels = {};
  final Map<String, String> _arTextures = {};
  final Map<String, Map<String, dynamic>> _arAnimations = {};

  ARRenderingAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(agentId: _agentTypeId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing AR Rendering Agent', name: _agentTypeId);

    // Load AR content library
    await _loadARContentLibrary();

    // Load saved AR data
    await _loadARData();

    // Initialize performance monitoring
    _startPerformanceMonitoring();

    // Initialize AR content library
    await _initializeARModels();

    developer.log('AR Rendering Agent initialized with ${_arModels.length} models', name: _agentTypeId);
  }

  @override
  void subscribeToEvents() {
    // AR experience triggers
    subscribe(EventTypes.arExperienceTriggered, _handleARExperienceTriggered);

    // Location events for location-based AR
    subscribe(EventTypes.locationUpdate, _handleLocationUpdate);
    subscribe(EventTypes.poiDetected, _handlePOIDetected);

    // Card events for AR card interactions
    subscribe(EventTypes.cardScanned, _handleCardScanned);

    // Quest events for AR quest content
    subscribe(EventTypes.questStarted, _handleQuestStarted);
    subscribe(EventTypes.questProgress, _handleQuestProgress);

    // Battle events for AR battle visualizations
    subscribe(EventTypes.battleStarted, _handleBattleStarted);
    subscribe(EventTypes.battleTurnResolved, _handleBattleTurn);

    // Achievement events for AR celebrations
    subscribe(EventTypes.achievementUnlocked, _handleAchievementUnlocked);

    // AR-specific events
    subscribe('ar_session_start', _handleSessionStart);
    subscribe('ar_session_stop', _handleSessionStop);
    subscribe('ar_object_place', _handleObjectPlace);
    subscribe('ar_object_remove', _handleObjectRemove);
    subscribe('ar_object_interact', _handleObjectInteraction);
    subscribe('ar_plane_detected', _handlePlaneDetected);
    subscribe('ar_tracking_state_changed', _handleTrackingStateChanged);

    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Start AR session with specified configuration
  Future<String> startARSession(ARSessionConfiguration configuration) async {
    if (_currentSession != null) {
      await stopARSession();
    }

    _currentSession = ARSession(configuration: configuration);
    _trackingState = ARTrackingState.initializing;

    // Simulate session initialization
    await Future.delayed(const Duration(seconds: 2));
    _trackingState = ARTrackingState.tracking;

    _currentSession = _currentSession!.copyWith(trackingState: _trackingState);

    // Publish session started event
    publishEvent(createEvent(
      eventType: 'ar_session_started',
      data: {
        'sessionId': _currentSession!.sessionId,
        'configuration': configuration.toString(),
        'trackingState': _trackingState.toString(),
      },
    ));

    _logPerformanceMetric('session_started', {
      'configuration': configuration.toString(),
      'sessionId': _currentSession!.sessionId,
    });

    developer.log('AR Session started: ${_currentSession!.sessionId}', name: _agentTypeId);
    return _currentSession!.sessionId;
  }

  /// Stop current AR session
  Future<void> stopARSession() async {
    if (_currentSession == null) return;

    final sessionId = _currentSession!.sessionId;
    
    // Clear all AR objects and anchors
    _objects.clear();
    _anchors.clear();
    
    _trackingState = ARTrackingState.stopped;
    _currentSession = null;

    // Publish session stopped event
    publishEvent(createEvent(
      eventType: 'ar_session_stopped',
      data: {
        'sessionId': sessionId,
        'totalObjects': _objects.length,
        'totalAnchors': _anchors.length,
      },
    ));

    _logPerformanceMetric('session_stopped', {
      'sessionId': sessionId,
      'duration': DateTime.now().difference(DateTime.now()).inSeconds,
    });

    developer.log('AR Session stopped: $sessionId', name: _agentTypeId);
  }

  /// Place AR object at specified position
  String placeARObject(String modelPath, ARVector3 position, {
    String? texturePath,
    ARVector3? scale,
    ARVector3? rotation,
    Map<String, dynamic>? properties,
  }) {
    if (_currentSession == null || _trackingState != ARTrackingState.tracking) {
      developer.log('Cannot place AR object: No active tracking session', name: _agentTypeId);
      return '';
    }

    // Create anchor at position
    final anchor = ARAnchor(
      type: ARAnchorType.plane,
      transform: ARMatrix4.translation(position),
    );

    // Create AR object
    final arObject = ARObject(
      modelPath: modelPath,
      texturePath: texturePath,
      anchor: anchor,
      scale: scale ?? const ARVector3(1, 1, 1),
      rotation: rotation ?? const ARVector3(0, 0, 0),
      properties: properties ?? {},
    );

    _anchors[anchor.anchorId] = anchor;
    _objects[arObject.objectId] = arObject;

    // Publish object placed event
    publishEvent(createEvent(
      eventType: 'ar_object_placed',
      data: {
        'objectId': arObject.objectId,
        'modelPath': modelPath,
        'position': position.toJson(),
        'sessionId': _currentSession!.sessionId,
      },
    ));

    _logPerformanceMetric('object_placed', {
      'objectId': arObject.objectId,
      'modelPath': modelPath,
    });

    developer.log('AR Object placed: ${arObject.objectId} at ${position}', name: _agentTypeId);
    return arObject.objectId;
  }

  /// Remove AR object
  bool removeARObject(String objectId) {
    final arObject = _objects[objectId];
    if (arObject == null) return false;

    _objects.remove(objectId);
    _anchors.remove(arObject.anchor.anchorId);

    // Publish object removed event
    publishEvent(createEvent(
      eventType: 'ar_object_removed',
      data: {
        'objectId': objectId,
        'sessionId': _currentSession?.sessionId,
      },
    ));

    _logPerformanceMetric('object_removed', {'objectId': objectId});

    developer.log('AR Object removed: $objectId', name: _agentTypeId);
    return true;
  }

  /// Animate AR object
  void animateARObject(String objectId, String animationType, {
    Duration duration = const Duration(seconds: 1),
    Map<String, dynamic>? parameters,
  }) {
    final arObject = _objects[objectId];
    if (arObject == null) return;

    final animation = {
      'type': animationType,
      'duration': duration.inMilliseconds,
      'parameters': parameters ?? {},
      'startTime': DateTime.now().toIso8601String(),
    };

    // Update object with animation
    final updatedObject = arObject.copyWith(
      animations: {...arObject.animations, animationType: animation},
    );

    _objects[objectId] = updatedObject;

    // Publish animation started event
    publishEvent(createEvent(
      eventType: 'ar_animation_started',
      data: {
        'objectId': objectId,
        'animationType': animationType,
        'duration': duration.inMilliseconds,
      },
    ));

    // Schedule animation completion
    Timer(duration, () {
      final obj = _objects[objectId];
      if (obj != null) {
        final animations = Map<String, dynamic>.from(obj.animations);
        animations.remove(animationType);
        _objects[objectId] = obj.copyWith(animations: animations);

        publishEvent(createEvent(
          eventType: 'ar_animation_completed',
          data: {
            'objectId': objectId,
            'animationType': animationType,
          },
        ));
      }
    });

    _logPerformanceMetric('animation_started', {
      'objectId': objectId,
      'type': animationType,
      'duration': duration.inMilliseconds,
    });
  }

  /// Detect collision between AR objects
  List<String> detectCollisions(String objectId) {
    final targetObject = _objects[objectId];
    if (targetObject == null) return [];

    final collisions = <String>[];
    final targetPos = targetObject.anchor.transform.translation;

    for (final otherObject in _objects.values) {
      if (otherObject.objectId == objectId) continue;

      final otherPos = otherObject.anchor.transform.translation;
      final distance = (targetPos - otherPos).magnitude;

      // Simple sphere collision detection
      final collisionDistance = 0.5; // 50cm collision radius
      if (distance < collisionDistance) {
        collisions.add(otherObject.objectId);
      }
    }

    if (collisions.isNotEmpty) {
      publishEvent(createEvent(
        eventType: 'ar_collision_detected',
        data: {
          'objectId': objectId,
          'collidingObjects': collisions,
          'position': targetPos.toJson(),
        },
      ));
    }

    return collisions;
  }

  /// Get AR analytics
  Map<String, dynamic> getARAnalytics() {
    final session = _currentSession;
    
    return {
      'hasActiveSession': session != null,
      'sessionId': session?.sessionId,
      'trackingState': _trackingState.toString(),
      'totalObjects': _objects.length,
      'totalAnchors': _anchors.length,
      'totalInteractions': _interactions.length,
      'renderingMode': _renderingMode.toString(),
      'averageFrameTime': _averageFrameTime,
      'totalFramesRendered': _totalFramesRendered,
      'modelsLoaded': _arModels.length,
      'texturesLoaded': _arTextures.length,
      'animationsLoaded': _arAnimations.length,
      'occlusionEnabled': _occlusionEnabled,
      'lightEstimationEnabled': _lightEstimationEnabled,
      'shadowsEnabled': _shadowsEnabled,
    };
  }

  /// Initialize AR models library
  Future<void> _initializeARModels() async {
    // Initialize sample 3D models for game content
    _arModels.addAll({
      'treasure_chest': {
        'path': 'models/treasure_chest.glb',
        'scale': const ARVector3(0.5, 0.5, 0.5),
        'materials': ['gold', 'wood', 'metal'],
        'animations': ['open', 'close', 'sparkle'],
        'category': 'treasure',
      },
      'battle_arena': {
        'path': 'models/battle_arena.glb',
        'scale': const ARVector3(2.0, 1.0, 2.0),
        'materials': ['stone', 'magic_circle'],
        'animations': ['summon', 'activate', 'disappear'],
        'category': 'battle',
      },
      'quest_marker': {
        'path': 'models/quest_marker.glb',
        'scale': const ARVector3(1.0, 2.0, 1.0),
        'materials': ['crystal', 'light_beam'],
        'animations': ['pulse', 'rotate', 'beacon'],
        'category': 'quest',
      },
      'card_portal': {
        'path': 'models/card_portal.glb',
        'scale': const ARVector3(1.5, 1.5, 1.5),
        'materials': ['energy', 'runes', 'portal_frame'],
        'animations': ['open_portal', 'card_summon', 'close_portal'],
        'category': 'card',
      },
      'achievement_trophy': {
        'path': 'models/achievement_trophy.glb',
        'scale': const ARVector3(0.8, 1.0, 0.8),
        'materials': ['gold', 'crystal', 'ribbon'],
        'animations': ['rise', 'shine', 'celebrate'],
        'category': 'achievement',
      },
      'magic_circle': {
        'path': 'models/magic_circle.glb',
        'scale': const ARVector3(3.0, 0.1, 3.0),
        'materials': ['runes', 'energy_lines', 'center_gem'],
        'animations': ['activate', 'pulse', 'spell_cast'],
        'category': 'magic',
      },
      'crystal_shard': {
        'path': 'models/crystal_shard.glb',
        'scale': const ARVector3(0.3, 0.8, 0.3),
        'materials': ['crystal', 'inner_light'],
        'animations': ['float', 'glow', 'collect'],
        'category': 'collectible',
      },
      'dungeon_entrance': {
        'path': 'models/dungeon_entrance.glb',
        'scale': const ARVector3(2.5, 3.0, 1.0),
        'materials': ['stone', 'metal_gate', 'moss'],
        'animations': ['gate_open', 'gate_close', 'spooky_glow'],
        'category': 'location',
      },
    });

    // Initialize textures
    _arTextures.addAll({
      'treasure_gold': 'textures/treasure_gold.jpg',
      'stone_ancient': 'textures/stone_ancient.jpg',
      'crystal_blue': 'textures/crystal_blue.jpg',
      'energy_purple': 'textures/energy_purple.jpg',
      'runes_glowing': 'textures/runes_glowing.jpg',
      'metal_weathered': 'textures/metal_weathered.jpg',
    });

    // Initialize animations
    _arAnimations.addAll({
      'float': {
        'type': 'transform',
        'property': 'position.y',
        'keyframes': [0, 0.2, 0, -0.2, 0],
        'duration': 4000,
        'loop': true,
      },
      'rotate': {
        'type': 'transform',
        'property': 'rotation.y',
        'keyframes': [0, 360],
        'duration': 10000,
        'loop': true,
      },
      'pulse': {
        'type': 'scale',
        'property': 'scale',
        'keyframes': [1.0, 1.2, 1.0, 0.8, 1.0],
        'duration': 2000,
        'loop': true,
      },
      'glow': {
        'type': 'material',
        'property': 'emissive',
        'keyframes': [0.0, 1.0, 0.0],
        'duration': 3000,
        'loop': true,
      },
    });

    developer.log('AR Content Library initialized', name: _agentTypeId);
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && _trackingState == ARTrackingState.tracking) {
        // Simulate frame rendering metrics
        _totalFramesRendered += 60; // Assume 60 FPS
        _averageFrameTime = 16.67 + (math.Random().nextDouble() - 0.5) * 2; // Simulate variation

        _logPerformanceMetric('frame_stats', {
          'frameTime': _averageFrameTime,
          'fps': 1000 / _averageFrameTime,
          'objectCount': _objects.length,
          'anchorCount': _anchors.length,
        });
      }
    });
  }

  /// Load AR content library
  Future<void> _loadARContentLibrary() async {
    try {
      final modelsJson = _prefs.getString('ar_models');
      if (modelsJson != null) {
        final data = jsonDecode(modelsJson) as Map<String, dynamic>;
        _arModels.addAll(Map<String, Map<String, dynamic>>.from(data));
      }

      final texturesJson = _prefs.getString('ar_textures');
      if (texturesJson != null) {
        final data = jsonDecode(texturesJson) as Map<String, dynamic>;
        _arTextures.addAll(Map<String, String>.from(data));
      }

      final animationsJson = _prefs.getString('ar_animations');
      if (animationsJson != null) {
        final data = jsonDecode(animationsJson) as Map<String, dynamic>;
        _arAnimations.addAll(Map<String, Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      developer.log('Error loading AR content library: $e', name: _agentTypeId);
    }
  }

  /// Save AR content library
  Future<void> _saveARContentLibrary() async {
    try {
      await _prefs.setString('ar_models', jsonEncode(_arModels));
      await _prefs.setString('ar_textures', jsonEncode(_arTextures));
      await _prefs.setString('ar_animations', jsonEncode(_arAnimations));
    } catch (e) {
      developer.log('Error saving AR content library: $e', name: _agentTypeId);
    }
  }

  /// Load AR data
  Future<void> _loadARData() async {
    try {
      final anchorsJson = _prefs.getString('ar_anchors');
      if (anchorsJson != null) {
        final data = jsonDecode(anchorsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _anchors[entry.key] = ARAnchor.fromJson(entry.value);
        }
      }

      final objectsJson = _prefs.getString('ar_objects');
      if (objectsJson != null) {
        final data = jsonDecode(objectsJson) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _objects[entry.key] = ARObject.fromJson(entry.value);
        }
      }
    } catch (e) {
      developer.log('Error loading AR data: $e', name: _agentTypeId);
    }
  }

  /// Save AR data
  Future<void> _saveARData() async {
    try {
      final anchorsData = _anchors.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('ar_anchors', jsonEncode(anchorsData));

      final objectsData = _objects.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString('ar_objects', jsonEncode(objectsData));
    } catch (e) {
      developer.log('Error saving AR data: $e', name: _agentTypeId);
    }
  }

  /// Log performance metric
  void _logPerformanceMetric(String metricType, Map<String, dynamic> data) {
    _performanceMetrics.add({
      'metricType': metricType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 metrics
    if (_performanceMetrics.length > 100) {
      _performanceMetrics.removeAt(0);
    }
  }

  // Event Handlers

  /// Handle AR experience triggered events
  Future<AgentEventResponse?> _handleARExperienceTriggered(AgentEvent event) async {
    final experienceType = event.data['type'] ?? '';
    final position = event.data['position'];

    if (position != null) {
      final arPos = ARVector3.fromJson(position);
      
      switch (experienceType) {
        case 'treasure_hunt':
          placeARObject('treasure_chest', arPos);
          break;
        case 'virtual_battle':
          placeARObject('battle_arena', arPos);
          break;
        case 'card_scan':
          placeARObject('card_portal', arPos);
          break;
        case 'puzzle_game':
          placeARObject('magic_circle', arPos);
          break;
        case 'location_marker':
          placeARObject('quest_marker', arPos);
          break;
        default:
          placeARObject('crystal_shard', arPos);
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_experience_rendered',
      data: {
        'experienceType': experienceType,
        'objectsPlaced': 1,
      },
    );
  }

  /// Handle location update events
  Future<AgentEventResponse?> _handleLocationUpdate(AgentEvent event) async {
    // Update location-based AR anchors if needed
    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_location_processed',
      data: {'processed': true},
    );
  }

  /// Handle POI detected events
  Future<AgentEventResponse?> _handlePOIDetected(AgentEvent event) async {
    final poi = event.data['poi'];
    if (poi != null && _currentSession != null) {
      // Place AR marker at POI location
      final position = ARVector3(0, 0, -2); // 2 meters in front of user
      placeARObject('quest_marker', position, properties: {
        'poiId': poi['id'],
        'poiName': poi['name'],
        'poiType': poi['type'],
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_poi_marker_placed',
      data: {'poiProcessed': poi != null},
    );
  }

  /// Handle card scanned events
  Future<AgentEventResponse?> _handleCardScanned(AgentEvent event) async {
    if (_currentSession != null) {
      // Create AR portal effect for card scanning
      final position = ARVector3(0, 0, -1); // 1 meter in front
      final objectId = placeARObject('card_portal', position);
      
      // Animate the portal
      animateARObject(objectId, 'open_portal', duration: const Duration(seconds: 2));
      
      // Auto-remove after 5 seconds
      Timer(const Duration(seconds: 5), () {
        removeARObject(objectId);
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_card_portal_created',
      data: {'portalCreated': _currentSession != null},
    );
  }

  /// Handle quest started events
  Future<AgentEventResponse?> _handleQuestStarted(AgentEvent event) async {
    if (_currentSession != null) {
      // Place quest marker
      final position = ARVector3(0, 1, -3); // Elevated and further away
      placeARObject('quest_marker', position, properties: {
        'questId': event.data['questId'],
        'questType': event.data['type'],
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_quest_marker_placed',
      data: {'markerPlaced': _currentSession != null},
    );
  }

  /// Handle quest progress events
  Future<AgentEventResponse?> _handleQuestProgress(AgentEvent event) async {
    // Update quest markers or create progress indicators
    final progress = event.data['progress'] ?? 0.0;
    
    // Find quest markers and update them
    final questObjects = _objects.values.where((obj) => 
        obj.properties['questId'] == event.data['questId']).toList();

    for (final obj in questObjects) {
      animateARObject(obj.objectId, 'pulse');
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_quest_progress_visualized',
      data: {'progress': progress, 'markersUpdated': questObjects.length},
    );
  }

  /// Handle battle started events
  Future<AgentEventResponse?> _handleBattleStarted(AgentEvent event) async {
    if (_currentSession != null) {
      // Create battle arena
      final position = ARVector3(0, 0, -2);
      final arenaId = placeARObject('battle_arena', position);
      
      // Add magic circle
      final circlePosition = ARVector3(0, 0.1, -2);
      placeARObject('magic_circle', circlePosition);
      
      // Animate arena activation
      animateARObject(arenaId, 'activate');
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_battle_arena_created',
      data: {'arenaCreated': _currentSession != null},
    );
  }

  /// Handle battle turn events
  Future<AgentEventResponse?> _handleBattleTurn(AgentEvent event) async {
    // Animate battle effects
    final actionType = event.data['actionType'];
    
    if (actionType == 'attack') {
      // Find battle arena objects and animate them
      final battleObjects = _objects.values.where((obj) => 
          obj.modelPath.contains('battle') || obj.modelPath.contains('magic')).toList();

      for (final obj in battleObjects) {
        animateARObject(obj.objectId, 'spell_cast', duration: const Duration(milliseconds: 800));
      }
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_battle_effect_played',
      data: {'actionType': actionType},
    );
  }

  /// Handle achievement unlocked events
  Future<AgentEventResponse?> _handleAchievementUnlocked(AgentEvent event) async {
    if (_currentSession != null) {
      // Create achievement trophy
      final position = ARVector3(0, 1.5, -1.5); // Elevated celebration
      final trophyId = placeARObject('achievement_trophy', position);
      
      // Animate celebration
      animateARObject(trophyId, 'rise', duration: const Duration(seconds: 2));
      Timer(const Duration(seconds: 2), () {
        animateARObject(trophyId, 'celebrate', duration: const Duration(seconds: 3));
      });
      
      // Auto-remove after celebration
      Timer(const Duration(seconds: 8), () {
        removeARObject(trophyId);
      });
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_achievement_celebration_created',
      data: {'celebrationCreated': _currentSession != null},
    );
  }

  /// Handle session start events
  Future<AgentEventResponse?> _handleSessionStart(AgentEvent event) async {
    final configurationName = event.data['configuration'] ?? 'worldTracking';
    final configuration = ARSessionConfiguration.values.firstWhere(
      (c) => c.toString().contains(configurationName),
      orElse: () => ARSessionConfiguration.worldTracking,
    );

    final sessionId = await startARSession(configuration);

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_session_started',
      data: {
        'sessionId': sessionId,
        'configuration': configuration.toString(),
        'success': sessionId.isNotEmpty,
      },
      success: sessionId.isNotEmpty,
    );
  }

  /// Handle session stop events
  Future<AgentEventResponse?> _handleSessionStop(AgentEvent event) async {
    final hadActiveSession = _currentSession != null;
    await stopARSession();

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_session_stopped',
      data: {'hadActiveSession': hadActiveSession},
    );
  }

  /// Handle object place events
  Future<AgentEventResponse?> _handleObjectPlace(AgentEvent event) async {
    final modelPath = event.data['modelPath'];
    final position = event.data['position'];

    if (modelPath == null || position == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'ar_object_place_failed',
        data: {'error': 'Missing modelPath or position'},
        success: false,
      );
    }

    final arPosition = ARVector3.fromJson(position);
    final objectId = placeARObject(
      modelPath,
      arPosition,
      texturePath: event.data['texturePath'],
      scale: event.data['scale'] != null ? ARVector3.fromJson(event.data['scale']) : null,
      rotation: event.data['rotation'] != null ? ARVector3.fromJson(event.data['rotation']) : null,
      properties: event.data['properties'],
    );

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_object_placed',
      data: {
        'objectId': objectId,
        'success': objectId.isNotEmpty,
      },
      success: objectId.isNotEmpty,
    );
  }

  /// Handle object remove events
  Future<AgentEventResponse?> _handleObjectRemove(AgentEvent event) async {
    final objectId = event.data['objectId'];

    if (objectId == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'ar_object_remove_failed',
        data: {'error': 'No object ID provided'},
        success: false,
      );
    }

    final success = removeARObject(objectId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_object_removed',
      data: {'objectId': objectId, 'success': success},
      success: success,
    );
  }

  /// Handle object interaction events
  Future<AgentEventResponse?> _handleObjectInteraction(AgentEvent event) async {
    final objectId = event.data['objectId'];
    final interactionType = event.data['type'] ?? 'tap';
    final position = event.data['position'];

    if (objectId == null || position == null) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'ar_interaction_failed',
        data: {'error': 'Missing objectId or position'},
        success: false,
      );
    }

    final interaction = ARInteraction(
      objectId: objectId,
      type: interactionType,
      position: ARVector3.fromJson(position),
      data: event.data,
    );

    _interactions[interaction.interactionId] = interaction;

    // Trigger interaction animation
    animateARObject(objectId, 'pulse', duration: const Duration(milliseconds: 500));

    // Check for collisions
    final collisions = detectCollisions(objectId);

    publishEvent(createEvent(
      eventType: 'ar_object_interacted',
      data: {
        'interactionId': interaction.interactionId,
        'objectId': objectId,
        'type': interactionType,
        'collisions': collisions,
      },
    ));

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_interaction_processed',
      data: {
        'interactionId': interaction.interactionId,
        'collisions': collisions,
      },
    );
  }

  /// Handle plane detected events
  Future<AgentEventResponse?> _handlePlaneDetected(AgentEvent event) async {
    final planeId = event.data['planeId'];
    
    if (_currentSession != null && planeId != null) {
      _currentSession = _currentSession!.copyWith(
        detectedPlanes: [..._currentSession!.detectedPlanes, planeId],
      );

      publishEvent(createEvent(
        eventType: 'ar_plane_tracking_updated',
        data: {
          'planeId': planeId,
          'totalPlanes': _currentSession!.detectedPlanes.length,
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_plane_processed',
      data: {'planeId': planeId},
    );
  }

  /// Handle tracking state changed events
  Future<AgentEventResponse?> _handleTrackingStateChanged(AgentEvent event) async {
    final newStateName = event.data['trackingState'];
    
    if (newStateName != null) {
      _trackingState = ARTrackingState.values.firstWhere(
        (state) => state.toString().contains(newStateName),
        orElse: () => _trackingState,
      );

      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(trackingState: _trackingState);
      }

      publishEvent(createEvent(
        eventType: 'ar_tracking_state_updated',
        data: {
          'trackingState': _trackingState.toString(),
          'sessionActive': _currentSession != null,
        },
      ));
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'ar_tracking_state_processed',
      data: {'trackingState': _trackingState.toString()},
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    // Load user-specific AR content and settings
    await _loadARData();

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_ar_processed',
      data: {'arDataLoaded': true},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    // Stop any active AR session
    if (_currentSession != null) {
      await stopARSession();
    }

    // Save all AR data
    await _saveARData();
    await _saveARContentLibrary();

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_ar_processed',
      data: {'arDataSaved': true},
    );
  }

  @override
  Future<void> onDispose() async {
    // Stop performance monitoring
    _performanceTimer?.cancel();

    // Stop any active AR session
    if (_currentSession != null) {
      await stopARSession();
    }

    // Save all data
    await _saveARData();
    await _saveARContentLibrary();

    developer.log('AR Rendering Agent disposed', name: _agentTypeId);
  }
}