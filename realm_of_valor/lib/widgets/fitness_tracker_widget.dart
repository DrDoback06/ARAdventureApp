import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/fitness_tracker_service.dart';
import '../services/audio_service.dart';

class FitnessTrackerWidget extends StatefulWidget {
  const FitnessTrackerWidget({super.key});

  @override
  State<FitnessTrackerWidget> createState() => _FitnessTrackerWidgetState();
}

class _FitnessTrackerWidgetState extends State<FitnessTrackerWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  WorkoutSession? _currentSession;
  bool _isWorkoutActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          tabs: const [
            Tab(text: 'Workouts'),
            Tab(text: 'Progress'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkoutsTab(),
          _buildProgressTab(),
          _buildGoalsTab(),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    return Consumer<FitnessTrackerService>(
      builder: (context, fitnessService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a Workout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (_isWorkoutActive) ...[
                _buildActiveWorkoutCard(fitnessService),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: FitnessActivityType.values.length,
                  itemBuilder: (context, index) {
                    final activityType = FitnessActivityType.values[index];
                    return _buildWorkoutCard(activityType, fitnessService);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkoutCard(FitnessActivityType activityType, FitnessTrackerService fitnessService) {
    return GestureDetector(
      onTap: () => _startWorkout(activityType, fitnessService),
      child: Container(
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getActivityIcon(activityType),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              _getActivityName(activityType),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: RealmOfValorTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${_getCaloriesPerMinute(activityType).toStringAsFixed(1)} cal/min',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWorkoutCard(FitnessTrackerService fitnessService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Workout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _endWorkout(fitnessService),
                icon: const Icon(Icons.stop, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWorkoutStat('Duration', '${_currentSession?.duration.inMinutes ?? 0} min'),
              ),
              Expanded(
                child: _buildWorkoutStat('Calories', '${_currentSession?.caloriesBurned ?? 0}'),
              ),
              Expanded(
                child: _buildWorkoutStat('Distance', '${(_currentSession?.distance ?? 0).toStringAsFixed(1)} km'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    return Consumer<FitnessTrackerService>(
      builder: (context, fitnessService, child) {
        final stats = fitnessService.getFitnessStatistics();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fitness Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildProgressCard('Today', '${stats['todayActivities']} activities', Icons.today),
                    const SizedBox(height: 12),
                    _buildProgressCard('This Week', '${stats['weekActivities']} activities', Icons.view_week),
                    const SizedBox(height: 12),
                    _buildProgressCard('This Month', '${stats['monthActivities']} activities', Icons.calendar_month),
                    const SizedBox(height: 12),
                    _buildProgressCard('Total', '${stats['totalActivities']} activities', Icons.fitness_center),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: RealmOfValorTheme.accentGold,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitness Goals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildGoalCard('Daily Steps', '10,000 steps', 0.7, Icons.directions_walk),
                const SizedBox(height: 12),
                _buildGoalCard('Weekly Workouts', '5 workouts', 0.6, Icons.fitness_center),
                const SizedBox(height: 12),
                _buildGoalCard('Monthly Distance', '100 km', 0.4, Icons.timeline),
                const SizedBox(height: 12),
                _buildGoalCard('Calories Burned', '2,000 calories', 0.8, Icons.local_fire_department),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, String target, double progress, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text(
                      target,
                      style: TextStyle(
                        fontSize: 12,
                        color: RealmOfValorTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: RealmOfValorTheme.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
          ),
        ],
      ),
    );
  }

  void _startWorkout(FitnessActivityType activityType, FitnessTrackerService fitnessService) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    fitnessService.startWorkoutSession(activityType);
    
    setState(() {
      _isWorkoutActive = true;
      _currentSession = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        activityType: activityType,
        startTime: DateTime.now(),
      );
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started ${_getActivityName(activityType)} workout'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _endWorkout(FitnessTrackerService fitnessService) {
    AudioService.instance.playSound(AudioType.buttonClick);
    
    fitnessService.endWorkoutSession();
    
    setState(() {
      _isWorkoutActive = false;
      _currentSession = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout completed! Stats and rewards applied.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getActivityIcon(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.walking:
        return '🚶';
      case FitnessActivityType.running:
        return '🏃';
      case FitnessActivityType.cycling:
        return '🚴';
      case FitnessActivityType.swimming:
        return '🏊';
      case FitnessActivityType.yoga:
        return '🧘';
      case FitnessActivityType.steps:
        return '👣';
      case FitnessActivityType.weightlifting:
        return '🏋️';
      case FitnessActivityType.hiking:
        return '🏔️';
      case FitnessActivityType.dancing:
        return '💃';
      case FitnessActivityType.tennis:
        return '🎾';
      case FitnessActivityType.basketball:
        return '🏀';
    }
  }

  String _getActivityName(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.walking:
        return 'Walking';
      case FitnessActivityType.running:
        return 'Running';
      case FitnessActivityType.cycling:
        return 'Cycling';
      case FitnessActivityType.swimming:
        return 'Swimming';
      case FitnessActivityType.yoga:
        return 'Yoga';
      case FitnessActivityType.steps:
        return 'Steps';
      case FitnessActivityType.weightlifting:
        return 'Weightlifting';
      case FitnessActivityType.hiking:
        return 'Hiking';
      case FitnessActivityType.dancing:
        return 'Dancing';
      case FitnessActivityType.tennis:
        return 'Tennis';
      case FitnessActivityType.basketball:
        return 'Basketball';
    }
  }

  double _getCaloriesPerMinute(FitnessActivityType activityType) {
    switch (activityType) {
      case FitnessActivityType.steps:
        return 2.0;
      case FitnessActivityType.walking:
        return 4.0;
      case FitnessActivityType.running:
        return 10.0;
      case FitnessActivityType.cycling:
        return 8.0;
      case FitnessActivityType.swimming:
        return 9.0;
      case FitnessActivityType.weightlifting:
        return 6.0;
      case FitnessActivityType.yoga:
        return 3.0;
      case FitnessActivityType.hiking:
        return 7.0;
      case FitnessActivityType.dancing:
        return 5.0;
      case FitnessActivityType.tennis:
        return 8.5;
      case FitnessActivityType.basketball:
        return 9.5;
    }
  }
} 