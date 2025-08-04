import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

enum StatusEffectType {
  poison,
  burn,
  freeze,
  stun,
  shield,
  regeneration,
  berserk,
  stealth,
}

enum ComboType {
  elemental,
  physical,
  magical,
  mixed,
}

class StatusEffect {
  final StatusEffectType type;
  final int duration;
  final int remainingTurns;
  final double intensity;
  final String description;

  StatusEffect({
    required this.type,
    required this.duration,
    required this.remainingTurns,
    required this.intensity,
    required this.description,
  });

  StatusEffect copyWith({
    StatusEffectType? type,
    int? duration,
    int? remainingTurns,
    double? intensity,
    String? description,
  }) {
    return StatusEffect(
      type: type ?? this.type,
      duration: duration ?? this.duration,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      intensity: intensity ?? this.intensity,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'duration': duration,
      'remainingTurns': remainingTurns,
      'intensity': intensity,
      'description': description,
    };
  }

  factory StatusEffect.fromJson(Map<String, dynamic> json) {
    return StatusEffect(
      type: StatusEffectType.values.firstWhere((e) => e.name == json['type']),
      duration: json['duration'],
      remainingTurns: json['remainingTurns'],
      intensity: json['intensity']?.toDouble() ?? 1.0,
      description: json['description'],
    );
  }
}

class ComboMove {
  final String id;
  final String name;
  final String description;
  final ComboType type;
  final int damage;
  final List<StatusEffect> effects;
  final int manaCost;
  final int cooldown;
  final int currentCooldown;

  ComboMove({
    String? id,
    required this.name,
    required this.description,
    required this.type,
    required this.damage,
    List<StatusEffect>? effects,
    this.manaCost = 0,
    this.cooldown = 0,
    this.currentCooldown = 0,
  })  : id = id ?? _generateComboId(),
        effects = effects ?? [];

  static String _generateComboId() {
    return 'combo_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  bool get isAvailable => currentCooldown <= 0;

  ComboMove copyWith({
    String? id,
    String? name,
    String? description,
    ComboType? type,
    int? damage,
    List<StatusEffect>? effects,
    int? manaCost,
    int? cooldown,
    int? currentCooldown,
  }) {
    return ComboMove(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      damage: damage ?? this.damage,
      effects: effects ?? this.effects,
      manaCost: manaCost ?? this.manaCost,
      cooldown: cooldown ?? this.cooldown,
      currentCooldown: currentCooldown ?? this.currentCooldown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'damage': damage,
      'effects': effects.map((e) => e.toJson()).toList(),
      'manaCost': manaCost,
      'cooldown': cooldown,
      'currentCooldown': currentCooldown,
    };
  }

  factory ComboMove.fromJson(Map<String, dynamic> json) {
    return ComboMove(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: ComboType.values.firstWhere((e) => e.name == json['type']),
      damage: json['damage'],
      effects: (json['effects'] as List<dynamic>).map((e) => StatusEffect.fromJson(e)).toList(),
      manaCost: json['manaCost'] ?? 0,
      cooldown: json['cooldown'] ?? 0,
      currentCooldown: json['currentCooldown'] ?? 0,
    );
  }
}

class BattleParticipant {
  final String id;
  final String name;
  final int maxHealth;
  final int currentHealth;
  final int maxMana;
  final int currentMana;
  final List<StatusEffect> statusEffects;
  final List<ComboMove> availableCombos;
  final bool isPlayer;

  BattleParticipant({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.currentHealth,
    required this.maxMana,
    required this.currentMana,
    List<StatusEffect>? statusEffects,
    List<ComboMove>? availableCombos,
    this.isPlayer = true,
  })  : statusEffects = statusEffects ?? [],
        availableCombos = availableCombos ?? [];

  double get healthPercentage => maxHealth > 0 ? currentHealth / maxHealth : 0.0;
  double get manaPercentage => maxMana > 0 ? currentMana / maxMana : 0.0;
  bool get isAlive => currentHealth > 0;
  bool get isStunned => statusEffects.any((e) => e.type == StatusEffectType.stun && e.remainingTurns > 0);
  bool get isShielded => statusEffects.any((e) => e.type == StatusEffectType.shield && e.remainingTurns > 0);

  BattleParticipant copyWith({
    String? id,
    String? name,
    int? maxHealth,
    int? currentHealth,
    int? maxMana,
    int? currentMana,
    List<StatusEffect>? statusEffects,
    List<ComboMove>? availableCombos,
    bool? isPlayer,
  }) {
    return BattleParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      maxMana: maxMana ?? this.maxMana,
      currentMana: currentMana ?? this.currentMana,
      statusEffects: statusEffects ?? this.statusEffects,
      availableCombos: availableCombos ?? this.availableCombos,
      isPlayer: isPlayer ?? this.isPlayer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'maxHealth': maxHealth,
      'currentHealth': currentHealth,
      'maxMana': maxMana,
      'currentMana': currentMana,
      'statusEffects': statusEffects.map((e) => e.toJson()).toList(),
      'availableCombos': availableCombos.map((c) => c.toJson()).toList(),
      'isPlayer': isPlayer,
    };
  }

  factory BattleParticipant.fromJson(Map<String, dynamic> json) {
    return BattleParticipant(
      id: json['id'],
      name: json['name'],
      maxHealth: json['maxHealth'],
      currentHealth: json['currentHealth'],
      maxMana: json['maxMana'],
      currentMana: json['currentMana'],
      statusEffects: (json['statusEffects'] as List<dynamic>).map((e) => StatusEffect.fromJson(e)).toList(),
      availableCombos: (json['availableCombos'] as List<dynamic>).map((c) => ComboMove.fromJson(c)).toList(),
      isPlayer: json['isPlayer'] ?? true,
    );
  }
}

class AdvancedBattleService extends ChangeNotifier {
  static AdvancedBattleService? _instance;
  static AdvancedBattleService get instance => _instance ??= AdvancedBattleService._();
  
  AdvancedBattleService._();
  
  List<BattleParticipant> _participants = [];
  List<ComboMove> _availableCombos = [];
  List<StatusEffect> _globalEffects = [];
  int _turnNumber = 0;
  String? _currentPlayerId;
  bool _isBattleActive = false;
  
  // Getters
  List<BattleParticipant> get participants => _participants;
  List<BattleParticipant> get aliveParticipants => _participants.where((p) => p.isAlive).toList();
  List<BattleParticipant> get players => _participants.where((p) => p.isPlayer).toList();
  List<BattleParticipant> get enemies => _participants.where((p) => !p.isPlayer).toList();
  BattleParticipant? get currentPlayer {
    try {
      return _participants.firstWhere((p) => p.id == _currentPlayerId);
    } catch (e) {
      return null;
    }
  }
  List<ComboMove> get availableCombos => _availableCombos;
  int get turnNumber => _turnNumber;
  bool get isBattleActive => _isBattleActive;
  bool get isBattleOver => aliveParticipants.length <= 1;

  // Initialize battle
  Future<void> initializeBattle(List<BattleParticipant> participants) async {
    _participants = participants;
    _turnNumber = 1;
    _currentPlayerId = participants.first.id;
    _isBattleActive = true;
    _availableCombos = _generateDefaultCombos();
    
    debugPrint('[ADVANCED_BATTLE] Battle initialized with ${participants.length} participants');
    notifyListeners();
  }

  // Generate default combo moves
  List<ComboMove> _generateDefaultCombos() {
    return [
      ComboMove(
        name: 'Fire Storm',
        description: 'Unleash a devastating fire storm',
        type: ComboType.elemental,
        damage: 150,
        effects: [
          StatusEffect(
            type: StatusEffectType.burn,
            duration: 3,
            remainingTurns: 3,
            intensity: 1.5,
            description: 'Burns enemies for 3 turns',
          ),
        ],
        manaCost: 50,
        cooldown: 3,
      ),
      ComboMove(
        name: 'Ice Prison',
        description: 'Freeze enemies in place',
        type: ComboType.elemental,
        damage: 80,
        effects: [
          StatusEffect(
            type: StatusEffectType.freeze,
            duration: 2,
            remainingTurns: 2,
            intensity: 1.0,
            description: 'Freezes enemies for 2 turns',
          ),
        ],
        manaCost: 40,
        cooldown: 2,
      ),
      ComboMove(
        name: 'Poison Strike',
        description: 'Inflict deadly poison',
        type: ComboType.physical,
        damage: 60,
        effects: [
          StatusEffect(
            type: StatusEffectType.poison,
            duration: 4,
            remainingTurns: 4,
            intensity: 2.0,
            description: 'Poisons enemies for 4 turns',
          ),
        ],
        manaCost: 30,
        cooldown: 1,
      ),
      ComboMove(
        name: 'Shield Wall',
        description: 'Create a protective barrier',
        type: ComboType.magical,
        damage: 0,
        effects: [
          StatusEffect(
            type: StatusEffectType.shield,
            duration: 2,
            remainingTurns: 2,
            intensity: 1.0,
            description: 'Protects from damage for 2 turns',
          ),
        ],
        manaCost: 25,
        cooldown: 2,
      ),
      ComboMove(
        name: 'Berserker Rage',
        description: 'Enter a state of battle frenzy',
        type: ComboType.physical,
        damage: 200,
        effects: [
          StatusEffect(
            type: StatusEffectType.berserk,
            duration: 3,
            remainingTurns: 3,
            intensity: 1.8,
            description: 'Increases damage for 3 turns',
          ),
        ],
        manaCost: 60,
        cooldown: 4,
      ),
    ];
  }

  // Execute a combo move
  Future<void> executeCombo(String comboId, String targetId) async {
    final combo = _availableCombos.firstWhere((c) => c.id == comboId);
    final attacker = _participants.firstWhere((p) => p.id == _currentPlayerId);
    final target = _participants.firstWhere((p) => p.id == targetId);
    
    if (!combo.isAvailable || attacker.currentMana < combo.manaCost) {
      debugPrint('[ADVANCED_BATTLE] Combo not available or insufficient mana');
      return;
    }
    
    // Calculate damage with status effects
    int finalDamage = combo.damage;
    if (attacker.statusEffects.any((e) => e.type == StatusEffectType.berserk)) {
      finalDamage = (finalDamage * 1.5).round();
    }
    
    // Apply damage
    final newHealth = (target.currentHealth - finalDamage).clamp(0, target.maxHealth);
    final targetIndex = _participants.indexWhere((p) => p.id == targetId);
    _participants[targetIndex] = _participants[targetIndex].copyWith(
      currentHealth: newHealth,
    );
    
    // Apply status effects
    for (final effect in combo.effects) {
      _applyStatusEffect(targetId, effect);
    }
    
    // Consume mana
    final newMana = (attacker.currentMana - combo.manaCost).clamp(0, attacker.maxMana);
    final attackerIndex = _participants.indexWhere((p) => p.id == _currentPlayerId);
    _participants[attackerIndex] = _participants[attackerIndex].copyWith(
      currentMana: newMana,
    );
    
    // Set cooldown
    final comboIndex = _availableCombos.indexWhere((c) => c.id == comboId);
    _availableCombos[comboIndex] = _availableCombos[comboIndex].copyWith(
      currentCooldown: combo.cooldown,
    );
    
    debugPrint('[ADVANCED_BATTLE] Executed combo: ${combo.name} for $finalDamage damage');
    notifyListeners();
  }

  // Apply status effect to target
  void _applyStatusEffect(String targetId, StatusEffect effect) {
    final targetIndex = _participants.indexWhere((p) => p.id == targetId);
    if (targetIndex != -1) {
      final target = _participants[targetIndex];
      final newEffects = List<StatusEffect>.from(target.statusEffects)..add(effect);
      
      _participants[targetIndex] = target.copyWith(
        statusEffects: newEffects,
      );
      
      debugPrint('[ADVANCED_BATTLE] Applied status effect: ${effect.type.name} to ${target.name}');
    }
  }

  // Process status effects at turn start
  void _processStatusEffects() {
    for (int i = 0; i < _participants.length; i++) {
      final participant = _participants[i];
      final newEffects = <StatusEffect>[];
      int damageTaken = 0;
      int healingReceived = 0;
      
      for (final effect in participant.statusEffects) {
        if (effect.remainingTurns > 0) {
          // Apply effect
          switch (effect.type) {
            case StatusEffectType.poison:
            case StatusEffectType.burn:
              damageTaken += (20 * effect.intensity).round();
              break;
            case StatusEffectType.regeneration:
              healingReceived += (15 * effect.intensity).round();
              break;
            case StatusEffectType.freeze:
            case StatusEffectType.stun:
              // Skip turn
              break;
            default:
              break;
          }
          
          // Decrease remaining turns
          final newEffect = effect.copyWith(
            remainingTurns: effect.remainingTurns - 1,
          );
          
          if (newEffect.remainingTurns > 0) {
            newEffects.add(newEffect);
          }
        }
      }
      
      // Apply damage/healing
      int newHealth = participant.currentHealth;
      if (damageTaken > 0) {
        newHealth = (newHealth - damageTaken).clamp(0, participant.maxHealth);
      }
      if (healingReceived > 0) {
        newHealth = (newHealth + healingReceived).clamp(0, participant.maxHealth);
      }
      
      _participants[i] = participant.copyWith(
        currentHealth: newHealth,
        statusEffects: newEffects,
      );
    }
  }

  // End turn
  Future<void> endTurn() async {
    if (!_isBattleActive || isBattleOver) return;
    
    // Process status effects
    _processStatusEffects();
    
    // Move to next player
    final currentIndex = _participants.indexWhere((p) => p.id == _currentPlayerId);
    int nextIndex = (currentIndex + 1) % _participants.length;
    
    // Find next alive player
    while (nextIndex != currentIndex) {
      if (_participants[nextIndex].isAlive) {
        break;
      }
      nextIndex = (nextIndex + 1) % _participants.length;
    }
    
    _currentPlayerId = _participants[nextIndex].id;
    _turnNumber++;
    
    // Reduce cooldowns
    for (int i = 0; i < _availableCombos.length; i++) {
      if (_availableCombos[i].currentCooldown > 0) {
        _availableCombos[i] = _availableCombos[i].copyWith(
          currentCooldown: _availableCombos[i].currentCooldown - 1,
        );
      }
    }
    
    debugPrint('[ADVANCED_BATTLE] Turn ended. Current player: ${currentPlayer?.name}');
    notifyListeners();
  }

  // Get battle statistics
  Map<String, dynamic> getBattleStats() {
    return {
      'turnNumber': _turnNumber,
      'aliveParticipants': aliveParticipants.length,
      'totalParticipants': _participants.length,
      'currentPlayer': currentPlayer?.name ?? 'None',
      'isBattleOver': isBattleOver,
      'winner': isBattleOver ? aliveParticipants.firstOrNull?.name : null,
    };
  }

  // Get available combos for current player
  List<ComboMove> getAvailableCombosForCurrentPlayer() {
    return _availableCombos.where((combo) => 
      combo.isAvailable && 
      currentPlayer != null && 
      currentPlayer!.currentMana >= combo.manaCost
    ).toList();
  }

  // Get valid targets for combo
  List<BattleParticipant> getValidTargets(ComboMove combo) {
    if (combo.type == ComboType.magical) {
      // Magical combos can target allies
      return _participants.where((p) => p.isAlive).toList();
    } else {
      // Physical and elemental combos target enemies
      return _participants.where((p) => p.isAlive && !p.isPlayer).toList();
    }
  }

  // End battle
  void endBattle() {
    _isBattleActive = false;
    debugPrint('[ADVANCED_BATTLE] Battle ended');
    notifyListeners();
  }

  // Reset battle
  void resetBattle() {
    _participants.clear();
    _availableCombos.clear();
    _globalEffects.clear();
    _turnNumber = 0;
    _currentPlayerId = null;
    _isBattleActive = false;
    notifyListeners();
  }
} 