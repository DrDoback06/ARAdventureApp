import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/adventure_map_model.dart';

class LeaderboardWidget extends StatelessWidget {
  const LeaderboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: RealmOfValorTheme.accentGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: RealmOfValorTheme.accentGold,
                    labelColor: RealmOfValorTheme.accentGold,
                    unselectedLabelColor: RealmOfValorTheme.textSecondary,
                    tabs: const [
                      Tab(text: 'Global'),
                      Tab(text: 'Friends'),
                      Tab(text: 'Events'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildGlobalLeaderboard(),
                        _buildFriendsLeaderboard(),
                        _buildEventsLeaderboard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    // Mock data - replace with real data from service
    final entries = [
      LeaderboardEntry(
        userId: 'user1',
        questId: 'quest1',
        username: 'AdventureMaster',
        score: 1500.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LeaderboardEntry(
        userId: 'user2',
        questId: 'quest1',
        username: 'ExplorerPro',
        score: 1420.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      LeaderboardEntry(
        userId: 'user3',
        questId: 'quest1',
        username: 'QuestHunter',
        score: 1380.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      LeaderboardEntry(
        userId: 'user4',
        questId: 'quest1',
        username: 'MapWanderer',
        score: 1350.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      LeaderboardEntry(
        userId: 'user5',
        questId: 'quest1',
        username: 'TrailBlazer',
        score: 1320.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    return _buildLeaderboardList(entries);
  }

  Widget _buildFriendsLeaderboard() {
    // Mock data - replace with real data from service
    final entries = [
      LeaderboardEntry(
        userId: 'friend1',
        questId: 'quest1',
        username: 'YourFriend1',
        score: 1200.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      LeaderboardEntry(
        userId: 'friend2',
        questId: 'quest1',
        username: 'YourFriend2',
        score: 1150.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LeaderboardEntry(
        userId: 'friend3',
        questId: 'quest1',
        username: 'YourFriend3',
        score: 1100.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];

    return _buildLeaderboardList(entries);
  }

  Widget _buildEventsLeaderboard() {
    // Mock data - replace with real data from service
    final entries = [
      LeaderboardEntry(
        userId: 'event1',
        questId: 'event_quest1',
        username: 'EventWinner',
        score: 2000.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      LeaderboardEntry(
        userId: 'event2',
        questId: 'event_quest1',
        username: 'EventRunner',
        score: 1950.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LeaderboardEntry(
        userId: 'event3',
        questId: 'event_quest1',
        username: 'EventParticipant',
        score: 1900.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];

    return _buildLeaderboardList(entries);
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final rank = index + 1;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getRankColor(rank).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: TextStyle(
                        color: RealmOfValorTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Score: ${entry.score.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: RealmOfValorTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    _getRankIcon(rank),
                    color: _getRankColor(rank),
                    size: 20,
                  ),
                  Text(
                    _formatTimestamp(entry.timestamp),
                    style: TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey; // Silver
      case 3:
        return Colors.orange; // Bronze
      default:
        return RealmOfValorTheme.accentGold;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.emoji_events;
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 