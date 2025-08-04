enum QuestType {
  exploration,
  fitness,
  battle,
  collection,
  social,
  creative,
  learning,
  adventure,
  challenge,
  daily,
  weekly,
  event,
}

enum QuestDifficulty {
  easy,
  medium,
  hard,
  epic,
  legendary,
}

enum QuestStatus {
  available,
  active,
  completed,
  failed,
  expired,
}

class QuestTypeHelper {
  static String getDisplayName(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return 'Exploration';
      case QuestType.fitness:
        return 'Fitness';
      case QuestType.battle:
        return 'Battle';
      case QuestType.collection:
        return 'Collection';
      case QuestType.social:
        return 'Social';
      case QuestType.creative:
        return 'Creative';
      case QuestType.learning:
        return 'Learning';
      case QuestType.adventure:
        return 'Adventure';
      case QuestType.challenge:
        return 'Challenge';
      case QuestType.daily:
        return 'Daily';
      case QuestType.weekly:
        return 'Weekly';
      case QuestType.event:
        return 'Event';
    }
  }

  static String getDescription(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return 'Explore new locations and discover hidden treasures';
      case QuestType.fitness:
        return 'Complete fitness activities and challenges';
      case QuestType.battle:
        return 'Engage in combat with enemies and bosses';
      case QuestType.collection:
        return 'Collect items and resources';
      case QuestType.social:
        return 'Interact with other players and NPCs';
      case QuestType.creative:
        return 'Create and customize your character and items';
      case QuestType.learning:
        return 'Learn new skills and abilities';
      case QuestType.adventure:
        return 'Embark on epic adventures and journeys';
      case QuestType.challenge:
        return 'Complete difficult challenges and trials';
      case QuestType.daily:
        return 'Complete daily tasks and objectives';
      case QuestType.weekly:
        return 'Complete weekly challenges and goals';
      case QuestType.event:
        return 'Participate in special events and activities';
    }
  }

  static int getBaseExperience(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return 50;
      case QuestType.fitness:
        return 75;
      case QuestType.battle:
        return 100;
      case QuestType.collection:
        return 60;
      case QuestType.social:
        return 40;
      case QuestType.creative:
        return 30;
      case QuestType.learning:
        return 80;
      case QuestType.adventure:
        return 120;
      case QuestType.challenge:
        return 150;
      case QuestType.daily:
        return 25;
      case QuestType.weekly:
        return 200;
      case QuestType.event:
        return 300;
    }
  }

  static int getBaseGold(QuestType type) {
    switch (type) {
      case QuestType.exploration:
        return 10;
      case QuestType.fitness:
        return 15;
      case QuestType.battle:
        return 25;
      case QuestType.collection:
        return 12;
      case QuestType.social:
        return 8;
      case QuestType.creative:
        return 5;
      case QuestType.learning:
        return 20;
      case QuestType.adventure:
        return 30;
      case QuestType.challenge:
        return 40;
      case QuestType.daily:
        return 5;
      case QuestType.weekly:
        return 50;
      case QuestType.event:
        return 75;
    }
  }
} 