import 'package:flutter/material.dart';
import '../models/battle_replay_system.dart';

class BattleReplayViewer extends StatefulWidget {
  final BattleReplay replay;
  final VoidCallback? onClose;

  const BattleReplayViewer({
    super.key,
    required this.replay,
    this.onClose,
  });

  @override
  State<BattleReplayViewer> createState() => _BattleReplayViewerState();
}

class _BattleReplayViewerState extends State<BattleReplayViewer> {
  int _currentActionIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  final List<String> _actionLog = [];

  @override
  void initState() {
    super.initState();
    _initializeReplay();
  }

  void _initializeReplay() {
    _actionLog.clear();
    _actionLog.add('🎬 Battle Replay: ${widget.replay.battleName}');
    _actionLog.add('📅 ${_formatDateTime(widget.replay.battleStartTime)}');
    _actionLog.add('⏱️ Duration: ${_formatDuration(widget.replay.battleDuration)}');
    _actionLog.add('👥 Players: ${widget.replay.playerNames.join(' vs ')}');
    _actionLog.add('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe94560)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),
          
          // Battle Info
          _buildBattleInfo(),
          const SizedBox(height: 20),
          
          // Action Log
          Expanded(
            child: _buildActionLog(),
          ),
          const SizedBox(height: 20),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.play_circle_outline,
          color: const Color(0xFFe94560),
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Battle Replay',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.replay.battleName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBattleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Duration', _formatDuration(widget.replay.battleDuration)),
              _buildInfoItem('Actions', '${widget.replay.totalActions}'),
              _buildInfoItem('Winner', widget.replay.winnerId ?? 'Draw'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Start', _formatDateTime(widget.replay.battleStartTime)),
              _buildInfoItem('End', _formatDateTime(widget.replay.battleEndTime)),
              _buildInfoItem('Players', '${widget.replay.playerIds.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionLog() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Action Log',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentActionIndex + 1}/${widget.replay.actions.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _actionLog.length,
              itemBuilder: (context, index) {
                final logEntry = _actionLog[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    logEntry,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Progress Bar
        Slider(
          value: widget.replay.actions.isEmpty ? 0.0 : _currentActionIndex / widget.replay.actions.length,
          onChanged: (value) {
            final newIndex = (value * widget.replay.actions.length).round();
            _seekToAction(newIndex);
          },
          activeColor: const Color(0xFFe94560),
          inactiveColor: Colors.grey.withOpacity(0.3),
        ),
        
        // Control Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: _currentActionIndex > 0 ? _previousAction : null,
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              tooltip: 'Previous Action',
            ),
            IconButton(
              onPressed: _isPlaying ? _pauseReplay : _playReplay,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
            IconButton(
              onPressed: _currentActionIndex < widget.replay.actions.length - 1 ? _nextAction : null,
              icon: const Icon(Icons.skip_next, color: Colors.white),
              tooltip: 'Next Action',
            ),
            IconButton(
              onPressed: _resetReplay,
              icon: const Icon(Icons.replay, color: Colors.white),
              tooltip: 'Reset',
            ),
          ],
        ),
        
        // Speed Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Speed: ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            ...['0.5x', '1x', '2x', '4x'].map((speed) => 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _setPlaybackSpeed(speed),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSpeedColor(speed),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      speed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getSpeedColor(String speed) {
    final currentSpeed = '${_playbackSpeed}x';
    return currentSpeed == speed ? const Color(0xFFe94560) : Colors.grey.withOpacity(0.3);
  }

  void _playReplay() {
    setState(() {
      _isPlaying = true;
    });
    _playNextAction();
  }

  void _pauseReplay() {
    setState(() {
      _isPlaying = false;
    });
  }

  void _playNextAction() {
    if (!_isPlaying || _currentActionIndex >= widget.replay.actions.length) {
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    final action = widget.replay.actions[_currentActionIndex];
    _addActionToLog(action);

    setState(() {
      _currentActionIndex++;
    });

    // Schedule next action based on playback speed
    final delay = Duration(milliseconds: (1000 / _playbackSpeed).round());
    Future.delayed(delay, _playNextAction);
  }

  void _addActionToLog(ReplayAction action) {
    final playerName = widget.replay.playerNames.isNotEmpty 
        ? widget.replay.playerNames.first 
        : 'Player ${action.playerId}';
    
    String logEntry = '';
    switch (action.type) {
      case ReplayActionType.turnStart:
        logEntry = '🔄 $playerName\'s turn begins';
        break;
      case ReplayActionType.cardPlayed:
        final cardName = action.data['cardName'] ?? 'Unknown Card';
        logEntry = '🎴 $playerName plays $cardName';
        break;
      case ReplayActionType.skillUsed:
        final skillName = action.data['skillName'] ?? 'Unknown Skill';
        logEntry = '⚡ $playerName uses $skillName';
        break;
      case ReplayActionType.damageDealt:
        final damage = action.data['damage'] ?? 0;
        final isCritical = action.data['isCritical'] ?? false;
        final criticalIcon = isCritical ? '⚡ ' : '';
        logEntry = '$criticalIcon💥 $playerName deals $damage damage';
        break;
      case ReplayActionType.healingReceived:
        final healing = action.data['healing'] ?? 0;
        logEntry = '✨ $playerName heals for $healing';
        break;
      case ReplayActionType.playerDefeated:
        final defeatedPlayer = action.data['defeatedPlayer'] ?? 'Unknown';
        logEntry = '💀 $defeatedPlayer has been defeated!';
        break;
      case ReplayActionType.battleEnd:
        logEntry = '🏆 Battle ends!';
        break;
      default:
        logEntry = '📝 Action: ${action.type}';
    }

    setState(() {
      _actionLog.add(logEntry);
    });
  }

  void _nextAction() {
    if (_currentActionIndex < widget.replay.actions.length) {
      setState(() {
        _currentActionIndex++;
      });
      final action = widget.replay.actions[_currentActionIndex - 1];
      _addActionToLog(action);
    }
  }

  void _previousAction() {
    if (_currentActionIndex > 0) {
      setState(() {
        _currentActionIndex--;
      });
      // Remove the last log entry
      if (_actionLog.isNotEmpty) {
        setState(() {
          _actionLog.removeLast();
        });
      }
    }
  }

  void _seekToAction(int index) {
    setState(() {
      _currentActionIndex = index.clamp(0, widget.replay.actions.length);
    });
    _rebuildActionLog();
  }

  void _resetReplay() {
    setState(() {
      _currentActionIndex = 0;
      _isPlaying = false;
    });
    _rebuildActionLog();
  }

  void _rebuildActionLog() {
    setState(() {
      _actionLog.clear();
      _initializeReplay();
      
      for (int i = 0; i < _currentActionIndex && i < widget.replay.actions.length; i++) {
        _addActionToLog(widget.replay.actions[i]);
      }
    });
  }

  void _setPlaybackSpeed(String speed) {
    setState(() {
      _playbackSpeed = double.parse(speed.replaceAll('x', ''));
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
} 