import 'package:flutter/material.dart';
import 'dart:math' as math;

enum ShakeType {
  light,
  medium,
  heavy,
  earthquake,
  explosion,
  impact,
  rumble,
  tremor,
}

enum ShakeDirection {
  horizontal,
  vertical,
  diagonal,
  random,
  circular,
}

class ShakeConfig {
  final ShakeType type;
  final ShakeDirection direction;
  final Duration duration;
  final double intensity;
  final double frequency;
  final bool fadeOut;

  ShakeConfig({
    required this.type,
    this.direction = ShakeDirection.random,
    required this.duration,
    required this.intensity,
    this.frequency = 10.0,
    this.fadeOut = true,
  });

  // Predefined shake configurations
  static ShakeConfig light() => ShakeConfig(
    type: ShakeType.light,
    duration: const Duration(milliseconds: 200),
    intensity: 2.0,
    frequency: 15.0,
  );

  static ShakeConfig medium() => ShakeConfig(
    type: ShakeType.medium,
    duration: const Duration(milliseconds: 400),
    intensity: 5.0,
    frequency: 12.0,
  );

  static ShakeConfig heavy() => ShakeConfig(
    type: ShakeType.heavy,
    duration: const Duration(milliseconds: 600),
    intensity: 10.0,
    frequency: 8.0,
  );

  static ShakeConfig explosion() => ShakeConfig(
    type: ShakeType.explosion,
    duration: const Duration(milliseconds: 800),
    intensity: 15.0,
    frequency: 6.0,
  );

  static ShakeConfig earthquake() => ShakeConfig(
    type: ShakeType.earthquake,
    direction: ShakeDirection.horizontal,
    duration: const Duration(seconds: 2),
    intensity: 8.0,
    frequency: 4.0,
  );
}

class ScreenShakeService extends ChangeNotifier {
  static ScreenShakeService? _instance;
  static ScreenShakeService get instance => _instance ??= ScreenShakeService._();
  
  ScreenShakeService._();
  
  Offset _currentOffset = Offset.zero;
  bool _isShaking = false;
  bool _isEnabled = true;
  ShakeConfig? _currentConfig;
  DateTime? _shakeStartTime;
  double _elapsedTime = 0.0;
  
  // Getters
  Offset get currentOffset => _currentOffset;
  bool get isShaking => _isShaking;
  bool get isEnabled => _isEnabled;
  ShakeConfig? get currentConfig => _currentConfig;

  // Initialize screen shake service
  void initialize() {
    _isEnabled = true;
    debugPrint('[SCREEN_SHAKE] Service initialized');
  }

  // Start screen shake
  void shake(ShakeConfig config) {
    if (!_isEnabled) return;
    
    _currentConfig = config;
    _shakeStartTime = DateTime.now();
    _elapsedTime = 0.0;
    _isShaking = true;
    
    debugPrint('[SCREEN_SHAKE] Started ${config.type.name} shake');
    notifyListeners();
  }

  // Quick shake methods
  void lightShake() => shake(ShakeConfig.light());
  void mediumShake() => shake(ShakeConfig.medium());
  void heavyShake() => shake(ShakeConfig.heavy());
  void explosionShake() => shake(ShakeConfig.explosion());
  void earthquakeShake() => shake(ShakeConfig.earthquake());

  // Update shake animation
  void update(double deltaTime) {
    if (!_isShaking || _currentConfig == null || _shakeStartTime == null) return;
    
    _elapsedTime += deltaTime;
    final progress = _elapsedTime / (_currentConfig!.duration.inMilliseconds / 1000.0);
    
    if (progress >= 1.0) {
      _stopShake();
      return;
    }
    
    // Calculate shake offset based on type and direction
    final offset = _calculateShakeOffset(progress);
    _currentOffset = offset;
    
    notifyListeners();
  }

  // Calculate shake offset
  Offset _calculateShakeOffset(double progress) {
    if (_currentConfig == null) return Offset.zero;
    
    final config = _currentConfig!;
    final time = _elapsedTime;
    final frequency = config.frequency;
    final intensity = config.intensity;
    
    // Apply fade out if enabled
    final fadeMultiplier = config.fadeOut ? (1.0 - progress) : 1.0;
    final adjustedIntensity = intensity * fadeMultiplier;
    
    double xOffset = 0.0;
    double yOffset = 0.0;
    
    switch (config.direction) {
      case ShakeDirection.horizontal:
        xOffset = _generateShakeValue(time, frequency, adjustedIntensity);
        break;
      case ShakeDirection.vertical:
        yOffset = _generateShakeValue(time, frequency, adjustedIntensity);
        break;
      case ShakeDirection.diagonal:
        final value = _generateShakeValue(time, frequency, adjustedIntensity);
        xOffset = value * 0.707; // cos(45°)
        yOffset = value * 0.707; // sin(45°)
        break;
      case ShakeDirection.random:
        xOffset = _generateShakeValue(time, frequency, adjustedIntensity);
        yOffset = _generateShakeValue(time + 0.5, frequency, adjustedIntensity);
        break;
      case ShakeDirection.circular:
        final angle = time * frequency * 2 * math.pi;
        final radius = _generateShakeValue(time, frequency, adjustedIntensity);
        xOffset = math.cos(angle) * radius;
        yOffset = math.sin(angle) * radius;
        break;
    }
    
    return Offset(xOffset, yOffset);
  }

  // Generate shake value using noise
  double _generateShakeValue(double time, double frequency, double intensity) {
    // Simple noise function for shake
    final noise = math.sin(time * frequency) * 
                  math.sin(time * frequency * 0.5) * 
                  math.sin(time * frequency * 0.25);
    
    return noise * intensity;
  }

  // Stop shake
  void _stopShake() {
    _isShaking = false;
    _currentOffset = Offset.zero;
    _currentConfig = null;
    _shakeStartTime = null;
    _elapsedTime = 0.0;
    
    debugPrint('[SCREEN_SHAKE] Stopped shake');
    notifyListeners();
  }

  // Stop shake immediately
  void stopShake() {
    _stopShake();
  }

  // Enable/disable screen shake
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _stopShake();
    }
    notifyListeners();
  }

  // Get shake statistics
  Map<String, dynamic> getStats() {
    return {
      'isShaking': _isShaking,
      'isEnabled': _isEnabled,
      'currentOffset': {
        'x': _currentOffset.dx,
        'y': _currentOffset.dy,
      },
      'currentType': _currentConfig?.type.name,
      'elapsedTime': _elapsedTime,
    };
  }
} 