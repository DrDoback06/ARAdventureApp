import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/lobby_data.dart';

class LobbyWidget extends StatelessWidget {
  final List<LobbyData> lobbies;
  final Function(LobbyData) onJoinLobby;

  const LobbyWidget({
    super.key,
    required this.lobbies,
    required this.onJoinLobby,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Lobbies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: lobbies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 64,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active lobbies',
                        style: TextStyle(
                          fontSize: 16,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a lobby or wait for others to join',
                        style: TextStyle(
                          fontSize: 12,
                          color: RealmOfValorTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: lobbies.length,
                  itemBuilder: (context, index) {
                    final lobby = lobbies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: RealmOfValorTheme.surfaceMedium,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: RealmOfValorTheme.accentGold,
                          child: Text(
                            lobby.hostName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          lobby.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: RealmOfValorTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${lobby.playerCount}/${lobby.maxPlayers} players • ${lobby.isPrivate ? 'Private' : 'Public'}',
                          style: TextStyle(
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => onJoinLobby(lobby),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RealmOfValorTheme.accentGold,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Join'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
} 