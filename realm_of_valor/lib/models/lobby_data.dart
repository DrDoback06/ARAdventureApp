class LobbyData {
  final String id;
  final String name;
  final String hostName;
  final int playerCount;
  final int maxPlayers;
  final bool isPrivate;
  final DateTime createdAt;

  const LobbyData({
    required this.id,
    required this.name,
    required this.hostName,
    required this.playerCount,
    required this.maxPlayers,
    required this.isPrivate,
    required this.createdAt,
  });
} 