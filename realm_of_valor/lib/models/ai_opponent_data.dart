import '../services/ai_battle_service.dart';

class AIOpponentData {
  final String name;
  final String description;
  final AIDifficulty difficulty;
  final AIStrategy strategy;

  const AIOpponentData({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.strategy,
  });
} 