import 'character_model.dart';

enum BattleOutcome {
  victory,
  defeat,
  draw,
  escape,
}

class BattleResult {
  final String battleId;
  final BattleOutcome outcome;
  final GameCharacter? winner;
  final GameCharacter? loser;
  final int experienceGained;
  final int goldGained;
  final List<dynamic> itemsGained;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  BattleResult({
    required this.battleId,
    required this.outcome,
    this.winner,
    this.loser,
    this.experienceGained = 0,
    this.goldGained = 0,
    List<dynamic>? itemsGained,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : itemsGained = itemsGained ?? [],
        timestamp = timestamp ?? DateTime.now(),
        metadata = metadata ?? {};

  bool get isVictory => outcome == BattleOutcome.victory;
  bool get isDefeat => outcome == BattleOutcome.defeat;
  bool get isDraw => outcome == BattleOutcome.draw;
  bool get isEscape => outcome == BattleOutcome.escape;

  BattleResult copyWith({
    String? battleId,
    BattleOutcome? outcome,
    GameCharacter? winner,
    GameCharacter? loser,
    int? experienceGained,
    int? goldGained,
    List<dynamic>? itemsGained,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return BattleResult(
      battleId: battleId ?? this.battleId,
      outcome: outcome ?? this.outcome,
      winner: winner ?? this.winner,
      loser: loser ?? this.loser,
      experienceGained: experienceGained ?? this.experienceGained,
      goldGained: goldGained ?? this.goldGained,
      itemsGained: itemsGained ?? this.itemsGained,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
} 