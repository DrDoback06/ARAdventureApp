import 'package:flutter/material.dart';
import '../models/battle_model.dart';

class BattleLogWidget extends StatelessWidget {
  final List<BattleLog> battleLog;

  const BattleLogWidget({
    Key? key,
    required this.battleLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0f3460),
        border: Border(
          right: BorderSide(color: Color(0xFFe94560), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFe94560), width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Battle Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Log Content
          Expanded(
            child: battleLog.isEmpty
                ? const Center(
                    child: Text(
                      'Battle has not started yet...',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    reverse: true, // Show newest entries at the bottom
                    padding: const EdgeInsets.all(8),
                    itemCount: battleLog.length,
                    itemBuilder: (context, index) {
                      final log = battleLog[battleLog.length - 1 - index];
                      return _buildLogEntry(log, index == 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(BattleLog log, bool isLatest) {
    final isSystemMessage = log.playerId == 'system';
    final timeString = _formatTime(log.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isLatest 
            ? const Color(0xFFe94560).withOpacity(0.2)
            : const Color(0xFF16213e).withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: isLatest
            ? Border.all(color: const Color(0xFFe94560), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with timestamp and action type
          Row(
            children: [
              // Action Type Icon
              Icon(
                _getActionIcon(log.action),
                color: _getActionColor(log.action, isSystemMessage),
                size: 14,
              ),
              
              const SizedBox(width: 6),
              
              // Timestamp
              Text(
                timeString,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const Spacer(),
              
              // Player indicator
              if (!isSystemMessage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPlayerColor(log.playerId),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPlayerName(log),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Log Description
          Text(
            log.description,
            style: TextStyle(
              color: isSystemMessage 
                  ? Colors.yellow.withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: isLatest ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          
          // Additional Data (if any)
          if (log.data.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildLogData(log.data),
            ),
        ],
      ),
    );
  }

  Widget _buildLogData(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'attack':
        return Icons.flash_on;
      case 'card_played':
        return Icons.style;
      case 'skill_used':
        return Icons.auto_fix_high;
      case 'damage':
        return Icons.remove_circle;
      case 'heal':
        return Icons.healing;
      case 'turn_start':
        return Icons.play_arrow;
      case 'turn_end':
        return Icons.stop;
      case 'log':
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action, bool isSystemMessage) {
    if (isSystemMessage) {
      return Colors.yellow;
    }
    
    switch (action.toLowerCase()) {
      case 'attack':
        return Colors.red;
      case 'card_played':
        return Colors.blue;
      case 'skill_used':
        return Colors.purple;
      case 'damage':
        return Colors.orange;
      case 'heal':
        return Colors.green;
      case 'turn_start':
        return Colors.lightGreen;
      case 'turn_end':
        return Colors.grey;
      case 'log':
      default:
        return Colors.white;
    }
  }

  Color _getPlayerColor(String playerId) {
    // Generate a consistent color based on player ID
    final hash = playerId.hashCode;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    return colors[hash.abs() % colors.length];
  }

  String _getPlayerName(BattleLog log) {
    // Extract player name from the description or use a shortened player ID
    if (log.description.contains(' ')) {
      final words = log.description.split(' ');
      if (words.isNotEmpty) {
        return words.first;
      }
    }
    
    // Fallback to shortened player ID
    return log.playerId.length > 6 
        ? log.playerId.substring(0, 6) 
        : log.playerId;
  }
}