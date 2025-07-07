import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'quest_model.g.dart';

enum QuestType {
  walking,
  running,
  climbing,
  location,
  exploration,
  collection,
  battle,
  social,
  fitness,
}

enum QuestStatus {
  available,
  active,
  completed,
  failed,
  locked,
}

enum QuestDifficulty {
  easy,
  medium,
  hard,
  expert,
  legendary,
}

@JsonSerializable()
class QuestLocation {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double? radius;
  final String? imageUrl;
  final Map<String, dynamic> properties;

  QuestLocation({
    String? id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.radius,
    this.imageUrl,
    Map<String, dynamic>? properties,
  })  : id = id ?? const Uuid().v4(),
        properties = properties ?? <String, dynamic>{};

  factory QuestLocation.fromJson(Map<String, dynamic> json) =>
      _$QuestLocationFromJson(json);
  Map<String, dynamic> toJson() => _$QuestLocationToJson(this);
}

@JsonSerializable()
class QuestObjective {
  final String id;
  final String description;
  final String type;
  final int targetValue;
  final int currentValue;
  final bool isCompleted;
  final Map<String, dynamic> properties;

  QuestObjective({
    String? id,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.isCompleted = false,
    Map<String, dynamic>? properties,
  })  : id = id ?? const Uuid().v4(),
        properties = properties ?? <String, dynamic>{};

  factory QuestObjective.fromJson(Map<String, dynamic> json) =>
      _$QuestObjectiveFromJson(json);
  Map<String, dynamic> toJson() => _$QuestObjectiveToJson(this);

  QuestObjective copyWith({
    String? id,
    String? description,
    String? type,
    int? targetValue,
    int? currentValue,
    bool? isCompleted,
    Map<String, dynamic>? properties,
  }) {
    return QuestObjective(
      id: id ?? this.id,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      properties: properties ?? this.properties,
    );
  }
}

@JsonSerializable()
class QuestReward {
  final String type;
  final String name;
  final int value;
  final String? cardId;
  final Map<String, dynamic> properties;

  QuestReward({
    required this.type,
    required this.name,
    required this.value,
    this.cardId,
    Map<String, dynamic>? properties,
  }) : properties = properties ?? <String, dynamic>{};

  factory QuestReward.fromJson(Map<String, dynamic> json) =>
      _$QuestRewardFromJson(json);
  Map<String, dynamic> toJson() => _$QuestRewardToJson(this);
}

@JsonSerializable()
class Quest {
  final String id;
  final String name;
  final String description;
  final String story;
  final QuestType type;
  final QuestStatus status;
  final QuestDifficulty difficulty;
  final List<QuestObjective> objectives;
  final List<QuestReward> rewards;
  final QuestLocation? location;
  final List<QuestLocation> waypoints;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? deadline;
  final int experienceReward;
  final int goldReward;
  final List<String> prerequisites;
  final Map<String, dynamic> metadata;

  Quest({
    String? id,
    required this.name,
    required this.description,
    required this.story,
    required this.type,
    this.status = QuestStatus.available,
    this.difficulty = QuestDifficulty.medium,
    List<QuestObjective>? objectives,
    List<QuestReward>? rewards,
    this.location,
    List<QuestLocation>? waypoints,
    this.startTime,
    this.endTime,
    this.deadline,
    this.experienceReward = 100,
    this.goldReward = 50,
    List<String>? prerequisites,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        objectives = objectives ?? <QuestObjective>[],
        rewards = rewards ?? <QuestReward>[],
        waypoints = waypoints ?? <QuestLocation>[],
        prerequisites = prerequisites ?? <String>[],
        metadata = metadata ?? <String, dynamic>{};

  factory Quest.fromJson(Map<String, dynamic> json) => _$QuestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestToJson(this);

  Quest copyWith({
    String? id,
    String? name,
    String? description,
    String? story,
    QuestType? type,
    QuestStatus? status,
    QuestDifficulty? difficulty,
    List<QuestObjective>? objectives,
    List<QuestReward>? rewards,
    QuestLocation? location,
    List<QuestLocation>? waypoints,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? deadline,
    int? experienceReward,
    int? goldReward,
    List<String>? prerequisites,
    Map<String, dynamic>? metadata,
  }) {
    return Quest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      story: story ?? this.story,
      type: type ?? this.type,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      objectives: objectives ?? this.objectives,
      rewards: rewards ?? this.rewards,
      location: location ?? this.location,
      waypoints: waypoints ?? this.waypoints,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      deadline: deadline ?? this.deadline,
      experienceReward: experienceReward ?? this.experienceReward,
      goldReward: goldReward ?? this.goldReward,
      prerequisites: prerequisites ?? this.prerequisites,
      metadata: metadata ?? this.metadata,
    );
  }

  double get completionProgress {
    if (objectives.isEmpty) return 0.0;
    final completed = objectives.where((obj) => obj.isCompleted).length;
    return completed / objectives.length;
  }

  bool get isCompleted => objectives.isNotEmpty && objectives.every((obj) => obj.isCompleted);

  // Predefined quest templates
  static List<Quest> getDefaultQuests() {
    return [
      Quest(
        name: 'Morning Mile',
        description: 'Walk or run 1 mile to start your day',
        story: 'The town needs a messenger to deliver important news. Will you take on this vital task?',
        type: QuestType.walking,
        difficulty: QuestDifficulty.easy,
        objectives: [
          QuestObjective(
            description: 'Walk 1 mile',
            type: 'distance',
            targetValue: 1609, // meters
          ),
        ],
        rewards: [
          QuestReward(
            type: 'stat_boost',
            name: 'Endurance Boost',
            value: 5,
          ),
        ],
        experienceReward: 150,
        goldReward: 25,
      ),
      Quest(
        name: 'Mountain Climber',
        description: 'Climb a mountain or hill for epic rewards',
        story: 'Ancient treasures are said to be hidden at the peaks of mountains. Are you brave enough to seek them?',
        type: QuestType.climbing,
        difficulty: QuestDifficulty.hard,
        objectives: [
          QuestObjective(
            description: 'Gain 100 meters elevation',
            type: 'elevation',
            targetValue: 100,
          ),
          QuestObjective(
            description: 'Maintain heart rate above 140 BPM for 10 minutes',
            type: 'heart_rate',
            targetValue: 600, // seconds
          ),
        ],
        rewards: [
          QuestReward(
            type: 'item',
            name: 'Mountain Climber\'s Boots',
            value: 1,
          ),
        ],
        experienceReward: 500,
        goldReward: 200,
      ),
      Quest(
        name: 'Urban Explorer',
        description: 'Visit 5 different locations in your city',
        story: 'The city holds many secrets. Explore different districts to uncover hidden knowledge.',
        type: QuestType.exploration,
        difficulty: QuestDifficulty.medium,
        objectives: [
          QuestObjective(
            description: 'Visit 5 different locations',
            type: 'location_visits',
            targetValue: 5,
          ),
        ],
        rewards: [
          QuestReward(
            type: 'skill',
            name: 'Navigation',
            value: 1,
          ),
        ],
        experienceReward: 300,
        goldReward: 100,
      ),
      Quest(
        name: 'Fitness Warrior',
        description: 'Complete a full workout routine',
        story: 'The guild master challenges you to prove your physical prowess through rigorous training.',
        type: QuestType.fitness,
        difficulty: QuestDifficulty.medium,
        objectives: [
          QuestObjective(
            description: 'Perform 50 push-ups',
            type: 'push_ups',
            targetValue: 50,
          ),
          QuestObjective(
            description: 'Hold plank for 2 minutes',
            type: 'plank',
            targetValue: 120,
          ),
          QuestObjective(
            description: 'Do 100 squats',
            type: 'squats',
            targetValue: 100,
          ),
        ],
        rewards: [
          QuestReward(
            type: 'stat_boost',
            name: 'Strength Surge',
            value: 10,
          ),
        ],
        experienceReward: 400,
        goldReward: 150,
      ),
    ];
  }
}

@JsonSerializable()
class QuestProgress {
  final String questId;
  final String playerId;
  final DateTime startTime;
  final DateTime? lastUpdateTime;
  final Map<String, dynamic> progressData;
  final List<String> completedObjectives;

  QuestProgress({
    required this.questId,
    required this.playerId,
    DateTime? startTime,
    this.lastUpdateTime,
    Map<String, dynamic>? progressData,
    List<String>? completedObjectives,
  })  : startTime = startTime ?? DateTime.now(),
        progressData = progressData ?? <String, dynamic>{},
        completedObjectives = completedObjectives ?? <String>[];

  factory QuestProgress.fromJson(Map<String, dynamic> json) =>
      _$QuestProgressFromJson(json);
  Map<String, dynamic> toJson() => _$QuestProgressToJson(this);
}