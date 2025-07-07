import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fitness_tracker_service.dart';
import '../models/physical_activity_model.dart';

class FitnessTrackerWidget extends StatefulWidget {
  final bool showCompact;
  final VoidCallback? onTap;

  const FitnessTrackerWidget({
    Key? key,
    this.showCompact = false,
    this.onTap,
  }) : super(key: key);

  @override
  _FitnessTrackerWidgetState createState() => _FitnessTrackerWidgetState();
}

class _FitnessTrackerWidgetState extends State<FitnessTrackerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  FitnessTrackerService? _fitnessService;
  RealTimeMetrics? _currentMetrics;
  FitnessStatBoosts? _currentBoosts;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fitnessService = Provider.of<FitnessTrackerService>(context, listen: false);
    _setupStreams();
  }

  void _setupStreams() {
    _fitnessService?.metricsStream?.listen((metrics) {
      setState(() {
        _currentMetrics = metrics;
      });
      
      // Pulse animation based on heart rate
      if (metrics.heartRate != null && metrics.heartRate! > 100) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    });
    
    _fitnessService?.boostsStream?.listen((boosts) {
      setState(() {
        _currentBoosts = boosts;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showCompact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.withOpacity(0.1), Colors.orange.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(
                    Icons.favorite,
                    color: _getHeartRateColor(),
                    size: 20,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentMetrics?.heartRate ?? "--"} BPM',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getZoneText(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getHeartRateColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            if (_getTotalActiveBoosts() > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${_getTotalActiveBoosts()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Fitness Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildConnectionStatus(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Real-time metrics
            _buildRealTimeMetrics(),
            const SizedBox(height: 16),
            
            // Heart rate zone
            _buildHeartRateZone(),
            const SizedBox(height: 16),
            
            // Active boosts
            _buildActiveBoosts(),
            const SizedBox(height: 16),
            
            // Energy and stress levels
            _buildEnergyStress(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final trackers = _fitnessService?.connectedTrackers ?? {};
    
    return Row(
      children: [
        Icon(
          trackers.isNotEmpty ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: trackers.isNotEmpty ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${trackers.length} device${trackers.length != 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRealTimeMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Heart Rate',
            '${_currentMetrics?.heartRate ?? "--"}',
            'BPM',
            Icons.favorite,
            _getHeartRateColor(),
            showPulse: _currentMetrics?.heartRate != null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Steps',
            '${_currentMetrics?.steps ?? "--"}',
            'today',
            Icons.directions_walk,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Calories',
            '${_currentMetrics?.calories.toStringAsFixed(1) ?? "--"}',
            'burned',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color, {
    bool showPulse = false,
  }) {
    Widget iconWidget = Icon(icon, color: color, size: 20);
    
    if (showPulse && _currentMetrics?.heartRate != null) {
      iconWidget = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Icon(icon, color: color, size: 20),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateZone() {
    final zone = _currentMetrics?.heartRateZone;
    if (zone == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.grey),
            SizedBox(width: 8),
            Text('Heart Rate Zone: Not Available'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getZoneColor(zone).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getZoneColor(zone).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: _getZoneColor(zone)),
          const SizedBox(width: 8),
          Text(
            'Zone: ${_getZoneDisplayName(zone)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getZoneColor(zone),
            ),
          ),
          const Spacer(),
          if (_currentMetrics?.isWorkingOut == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ACTIVE WORKOUT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveBoosts() {
    final allBoosts = [
      ...(_currentBoosts?.realTimeBoosts ?? []),
      ...(_currentBoosts?.dailyBoosts ?? []),
      ...(_currentBoosts?.weeklyBoosts ?? []),
    ].where((boost) => !boost.isExpired).toList();

    if (allBoosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.grey),
            SizedBox(width: 8),
            Text('No Active Fitness Boosts'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Text(
              'Active Boosts (${allBoosts.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...allBoosts.take(3).map((boost) => _buildBoostCard(boost)),
        if (allBoosts.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... and ${allBoosts.length - 3} more',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildBoostCard(StatBoost boost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getBoostIcon(boost.statType),
            size: 16,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boost.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  boost.description,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '+${boost.bonusValue}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyStress() {
    return Row(
      children: [
        Expanded(
          child: _buildLevelBar(
            'Energy',
            _currentMetrics?.energyLevel ?? 0.7,
            Colors.green,
            Icons.battery_charging_full,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildLevelBar(
            'Stress',
            _currentMetrics?.stressLevel ?? 0.5,
            Colors.red,
            Icons.psychology,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelBar(String label, double value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 2),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Color _getHeartRateColor() {
    final hr = _currentMetrics?.heartRate;
    if (hr == null) return Colors.grey;
    
    if (hr < 60) return Colors.blue;
    if (hr < 100) return Colors.green;
    if (hr < 140) return Colors.orange;
    return Colors.red;
  }

  Color _getZoneColor(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.resting:
        return Colors.blue;
      case HeartRateZone.fatBurn:
        return Colors.green;
      case HeartRateZone.aerobic:
        return Colors.orange;
      case HeartRateZone.anaerobic:
        return Colors.red;
      case HeartRateZone.peak:
        return Colors.purple;
    }
  }

  String _getZoneDisplayName(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.resting:
        return 'Resting';
      case HeartRateZone.fatBurn:
        return 'Fat Burn';
      case HeartRateZone.aerobic:
        return 'Aerobic';
      case HeartRateZone.anaerobic:
        return 'Anaerobic';
      case HeartRateZone.peak:
        return 'Peak';
    }
  }

  String _getZoneText() {
    final zone = _currentMetrics?.heartRateZone;
    if (zone == null) return 'No Zone';
    return _getZoneDisplayName(zone);
  }

  IconData _getBoostIcon(String statType) {
    switch (statType) {
      case 'strength':
        return Icons.fitness_center;
      case 'dexterity':
        return Icons.speed;
      case 'vitality':
        return Icons.favorite;
      case 'intelligence':
        return Icons.psychology;
      case 'all':
        return Icons.star;
      default:
        return Icons.trending_up;
    }
  }

  int _getTotalActiveBoosts() {
    return (_currentBoosts?.realTimeBoosts.length ?? 0) +
           (_currentBoosts?.dailyBoosts.length ?? 0) +
           (_currentBoosts?.weeklyBoosts.length ?? 0);
  }
}

class FitnessTrackerDialog extends StatelessWidget {
  const FitnessTrackerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center),
                  const SizedBox(width: 8),
                  const Text(
                    'Fitness Tracker Dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: FitnessTrackerWidget(showCompact: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 