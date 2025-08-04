import 'package:flutter/material.dart';
import '../services/battle_rewards_service.dart';
import '../providers/character_provider.dart';
import '../constants/theme.dart';

class BattleRewardsWidget extends StatelessWidget {
  final List<BattleReward> rewards;
  final BattlePerformance performance;
  final VoidCallback? onApplyRewards;
  final CharacterProvider characterProvider;

  const BattleRewardsWidget({
    super.key,
    required this.rewards,
    required this.performance,
    this.onApplyRewards,
    required this.characterProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPerformanceColor(performance),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _getPerformanceIcon(performance),
                color: _getPerformanceColor(performance),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPerformanceTitle(performance),
                      style: TextStyle(
                        color: _getPerformanceColor(performance),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getPerformanceDescription(performance),
                      style: const TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Rewards List
          ...rewards.map((reward) => _buildRewardItem(reward)),
          
          const SizedBox(height: 20),
          
          // Apply Rewards Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _applyRewards();
                onApplyRewards?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Claim Rewards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(BattleReward reward) {
    final displayInfo = BattleRewardsService.instance.getRewardDisplayInfo(reward);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: displayInfo['color'] as Color,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            displayInfo['icon'] as IconData,
            color: displayInfo['color'] as Color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${displayInfo['label']} x${reward.amount}',
                  style: const TextStyle(
                    color: RealmOfValorTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (reward.description != null)
                  Text(
                    reward.description!,
                    style: const TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(BattlePerformance performance) {
    switch (performance) {
      case BattlePerformance.poor:
        return Colors.red;
      case BattlePerformance.average:
        return Colors.orange;
      case BattlePerformance.good:
        return Colors.green;
      case BattlePerformance.excellent:
        return Colors.blue;
      case BattlePerformance.legendary:
        return Colors.purple;
    }
  }

  IconData _getPerformanceIcon(BattlePerformance performance) {
    switch (performance) {
      case BattlePerformance.poor:
        return Icons.sentiment_dissatisfied;
      case BattlePerformance.average:
        return Icons.sentiment_neutral;
      case BattlePerformance.good:
        return Icons.sentiment_satisfied;
      case BattlePerformance.excellent:
        return Icons.sentiment_very_satisfied;
      case BattlePerformance.legendary:
        return Icons.emoji_events;
    }
  }

  String _getPerformanceTitle(BattlePerformance performance) {
    switch (performance) {
      case BattlePerformance.poor:
        return 'Poor Performance';
      case BattlePerformance.average:
        return 'Average Performance';
      case BattlePerformance.good:
        return 'Good Performance';
      case BattlePerformance.excellent:
        return 'Excellent Performance';
      case BattlePerformance.legendary:
        return 'Legendary Performance';
    }
  }

  String _getPerformanceDescription(BattlePerformance performance) {
    switch (performance) {
      case BattlePerformance.poor:
        return 'Room for improvement - keep practicing!';
      case BattlePerformance.average:
        return 'Not bad - you can do better!';
      case BattlePerformance.good:
        return 'Well done - you\'re getting better!';
      case BattlePerformance.excellent:
        return 'Outstanding - you\'re a skilled warrior!';
      case BattlePerformance.legendary:
        return 'Unstoppable - you are truly legendary!';
    }
  }

  Future<void> _applyRewards() async {
    await BattleRewardsService.instance.applyRewards(
      rewards: rewards,
      characterProvider: characterProvider,
    );
  }
} 