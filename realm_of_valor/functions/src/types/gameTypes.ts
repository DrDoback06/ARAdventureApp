// =============================================================================
// GAME TYPES - Core game data structures for Realm of Valor Cloud Functions
// =============================================================================

export interface GameState {
  battleId?: string;
  players: Player[];
  currentTurn: string;
  turnCount: number;
  startTime: string;
  status: 'waiting' | 'active' | 'paused' | 'completed' | 'cancelled';
  gameMode: 'pvp' | 'guild_raid' | 'tournament' | 'cooperative' | 'practice';
  environmentalEffects?: EnvironmentalEffect[];
  weatherCondition?: WeatherCondition;
  lastAction?: GameAction;
}

export interface Player {
  userId: string;
  displayName: string;
  level: number;
  health: number;
  maxHealth: number;
  energy: number;
  maxEnergy: number;
  position?: Position;
  equipment: EquippedCard[];
  activeEffects: StatusEffect[];
  isReady: boolean;
  isConnected: boolean;
  lastActionTime?: string;
}

export interface Position {
  x: number;
  y: number;
  z?: number;
  facing?: number; // degrees
}

export interface EquippedCard {
  cardId: string;
  slot: 'weapon' | 'armor' | 'accessory' | 'ability';
  bonuses: StatBonus[];
  durability?: number;
  enchantments?: Enchantment[];
}

export interface StatBonus {
  stat: 'attack' | 'defense' | 'speed' | 'health' | 'energy' | 'critical' | 'accuracy';
  value: number;
  type: 'flat' | 'percentage';
}

export interface Enchantment {
  id: string;
  name: string;
  effect: string;
  power: number;
  duration?: number; // turns
}

export interface StatusEffect {
  id: string;
  name: string;
  type: 'buff' | 'debuff' | 'neutral';
  duration: number; // turns remaining
  power: number;
  source: string; // what caused this effect
  stackable: boolean;
  stacks?: number;
}

export interface GameAction {
  actionId: string;
  playerId: string;
  type: 'attack' | 'defend' | 'move' | 'use_ability' | 'use_item' | 'end_turn' | 'surrender';
  timestamp: string;
  targetId?: string;
  targetPosition?: Position;
  abilityId?: string;
  itemId?: string;
  metadata?: Record<string, any>;
  cost?: ResourceCost;
  results?: ActionResult[];
}

export interface ResourceCost {
  energy?: number;
  health?: number;
  items?: { itemId: string; quantity: number }[];
}

export interface ActionResult {
  type: 'damage' | 'heal' | 'buff' | 'debuff' | 'move' | 'spawn' | 'destroy';
  targetId: string;
  value?: number;
  effectId?: string;
  position?: Position;
  success: boolean;
  critical?: boolean;
  blocked?: boolean;
  resisted?: boolean;
}

export interface EnvironmentalEffect {
  id: string;
  name: string;
  type: 'weather' | 'terrain' | 'magical' | 'temporal';
  description: string;
  effects: EffectModifier[];
  duration?: number; // turns
  area?: AreaOfEffect;
}

export interface EffectModifier {
  stat: string;
  modifier: number;
  type: 'flat' | 'percentage' | 'multiplier';
  condition?: string; // when this modifier applies
}

export interface AreaOfEffect {
  shape: 'circle' | 'square' | 'line' | 'cone' | 'global';
  size: number;
  center?: Position;
  direction?: number; // for cones and lines
}

export interface WeatherCondition {
  type: 'clear' | 'rain' | 'snow' | 'storm' | 'fog' | 'wind' | 'extreme';
  intensity: 'light' | 'moderate' | 'heavy' | 'severe';
  temperature: number; // Celsius
  visibility: number; // 0-100%
  effects: WeatherEffect[];
}

export interface WeatherEffect {
  affectedStat: string;
  modifier: number;
  description: string;
  elementalBonus?: { element: string; bonus: number }[];
}

// =============================================================================
// BATTLE TYPES
// =============================================================================

export interface BattleResult {
  battleId: string;
  winnerId: string;
  duration: number; // seconds
  turnCount: number;
  playerStats: Record<string, PlayerStats>;
  finalGameState: GameState;
  rewards?: BattleReward[];
  achievements?: string[];
  timestamp: string;
}

export interface PlayerStats {
  playerId: string;
  damageDealt: number;
  damageTaken: number;
  damageHealed: number;
  actionsPerformed: number;
  abilitiesUsed: number;
  itemsUsed: number;
  criticalHits: number;
  blockedAttacks: number;
  statusEffectsApplied: number;
  distanceMoved: number;
  survivalTime: number; // seconds
  perfectTurns: number; // turns with no damage taken
  comboCount: number; // highest combo achieved
  finalScore: number;
}

export interface BattleReward {
  type: 'experience' | 'currency' | 'item' | 'card' | 'achievement';
  amount?: number;
  itemId?: string;
  cardId?: string;
  achievementId?: string;
  rarity?: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
}

// =============================================================================
// QUEST TYPES
// =============================================================================

export interface QuestCompletion {
  questId: string;
  userId: string;
  completedObjectives: string[];
  completionScore: number; // 0-100
  completionTime: number; // seconds
  bonusObjectives?: string[];
  failedObjectives?: string[];
  teamMembers?: string[]; // for group quests
  guildId?: string; // for guild quests
  guildQuest?: boolean;
  timestamp: string;
  evidence?: QuestEvidence[];
}

export interface QuestEvidence {
  type: 'location' | 'photo' | 'scan' | 'fitness' | 'social' | 'battle';
  data: any;
  timestamp: string;
  verified: boolean;
  verificationMethod: 'automatic' | 'manual' | 'peer';
}

export interface QuestObjective {
  id: string;
  type: 'location' | 'battle' | 'collection' | 'social' | 'fitness' | 'scan' | 'survival';
  description: string;
  required: boolean;
  progress: number; // 0-100
  target: number;
  current: number;
  rewards?: QuestReward[];
  conditions?: ObjectiveCondition[];
}

export interface ObjectiveCondition {
  type: 'weather' | 'time' | 'location' | 'level' | 'equipment' | 'social';
  requirement: any;
  description: string;
}

export interface QuestReward {
  type: 'experience' | 'currency' | 'item' | 'card' | 'title' | 'unlock';
  amount?: number;
  itemId?: string;
  cardId?: string;
  titleId?: string;
  unlockId?: string;
  rarity?: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
}

// =============================================================================
// ACHIEVEMENT TYPES
// =============================================================================

export interface AchievementUnlock {
  id: string;
  name: string;
  description: string;
  category: 'battle' | 'quest' | 'social' | 'collection' | 'exploration' | 'fitness' | 'special';
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary' | 'mythic';
  points: number;
  requirements: AchievementRequirement[];
  rewards?: AchievementReward[];
  isSecret?: boolean;
  isPublic?: boolean;
  unlockedAt?: string;
  progress?: number;
  maxProgress?: number;
}

export interface AchievementRequirement {
  type: 'stat' | 'quest' | 'battle' | 'collection' | 'social' | 'time' | 'special';
  target: number;
  current?: number;
  description: string;
  metadata?: Record<string, any>;
}

export interface AchievementReward {
  type: 'experience' | 'currency' | 'item' | 'card' | 'title' | 'cosmetic' | 'unlock';
  amount?: number;
  itemId?: string;
  cardId?: string;
  titleId?: string;
  cosmeticId?: string;
  unlockId?: string;
}

// =============================================================================
// CARD TYPES
// =============================================================================

export interface GameCard {
  id: string;
  name: string;
  description: string;
  type: 'creature' | 'spell' | 'artifact' | 'weapon' | 'armor' | 'ability';
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary' | 'mythic';
  cost: ResourceCost;
  stats?: CardStats;
  abilities?: CardAbility[];
  tags: string[];
  artwork: string;
  flavor?: string;
  setId: string;
  collectible: boolean;
  tradeable: boolean;
}

export interface CardStats {
  attack?: number;
  defense?: number;
  health?: number;
  speed?: number;
  energy?: number;
  durability?: number;
  range?: number;
}

export interface CardAbility {
  id: string;
  name: string;
  description: string;
  type: 'passive' | 'active' | 'triggered' | 'continuous';
  cost?: ResourceCost;
  cooldown?: number; // turns
  range?: number;
  area?: AreaOfEffect;
  effects: AbilityEffect[];
  conditions?: AbilityCondition[];
}

export interface AbilityEffect {
  type: 'damage' | 'heal' | 'buff' | 'debuff' | 'summon' | 'transform' | 'special';
  value?: number;
  duration?: number;
  target: 'self' | 'ally' | 'enemy' | 'all' | 'area' | 'random';
  statusEffect?: StatusEffect;
  metadata?: Record<string, any>;
}

export interface AbilityCondition {
  type: 'health' | 'energy' | 'position' | 'weather' | 'time' | 'stat' | 'special';
  comparison: 'equal' | 'greater' | 'less' | 'greater_equal' | 'less_equal' | 'not_equal';
  value: number | string;
  description: string;
}

// =============================================================================
// INVENTORY TYPES
// =============================================================================

export interface InventoryItem {
  itemId: string;
  quantity: number;
  acquiredAt: string;
  durability?: number;
  enchantments?: Enchantment[];
  bound: boolean;
  tradeable: boolean;
  metadata?: Record<string, any>;
}

export interface CardInstance {
  instanceId: string;
  cardId: string;
  level: number;
  experience: number;
  foil: boolean;
  condition: 'mint' | 'near_mint' | 'excellent' | 'good' | 'played' | 'poor';
  acquiredAt: string;
  source: 'pack' | 'trade' | 'reward' | 'craft' | 'scan' | 'event';
  bound: boolean;
  tradeable: boolean;
  customizations?: CardCustomization[];
}

export interface CardCustomization {
  type: 'skin' | 'animation' | 'border' | 'signature' | 'effect';
  id: string;
  name: string;
  rarity: string;
  appliedAt: string;
}

// =============================================================================
// SOCIAL TYPES
// =============================================================================

export interface SocialAction {
  actionId: string;
  type: 'friend_request' | 'guild_invite' | 'battle_challenge' | 'quest_invite' | 'trade_offer';
  fromUserId: string;
  toUserId: string;
  status: 'pending' | 'accepted' | 'declined' | 'cancelled' | 'expired';
  data?: Record<string, any>;
  createdAt: string;
  expiresAt?: string;
  respondedAt?: string;
}

export interface SocialEvent {
  eventId: string;
  type: 'achievement' | 'level_up' | 'rare_find' | 'battle_victory' | 'quest_complete';
  userId: string;
  data: Record<string, any>;
  timestamp: string;
  visibility: 'public' | 'friends' | 'guild' | 'private';
  reactions?: SocialReaction[];
  comments?: SocialComment[];
}

export interface SocialReaction {
  userId: string;
  type: 'like' | 'love' | 'wow' | 'congratulations' | 'support';
  timestamp: string;
}

export interface SocialComment {
  commentId: string;
  userId: string;
  content: string;
  timestamp: string;
  edited?: boolean;
  editedAt?: string;
  replies?: SocialComment[];
}

// =============================================================================
// ANALYTICS TYPES
// =============================================================================

export interface AnalyticsEvent {
  eventId: string;
  userId?: string;
  sessionId: string;
  type: string;
  category: 'gameplay' | 'social' | 'monetization' | 'technical' | 'user_behavior';
  data: Record<string, any>;
  timestamp: string;
  deviceInfo?: DeviceInfo;
  locationInfo?: LocationInfo;
}

export interface DeviceInfo {
  platform: 'ios' | 'android' | 'web';
  version: string;
  model: string;
  osVersion: string;
  appVersion: string;
  deviceId: string;
}

export interface LocationInfo {
  latitude?: number;
  longitude?: number;
  accuracy?: number;
  country?: string;
  region?: string;
  city?: string;
  timezone: string;
}

// =============================================================================
// NOTIFICATION TYPES
// =============================================================================

export interface PushNotification {
  notificationId: string;
  userId: string;
  type: 'battle' | 'quest' | 'social' | 'achievement' | 'event' | 'system';
  title: string;
  body: string;
  data?: Record<string, any>;
  priority: 'low' | 'normal' | 'high' | 'critical';
  scheduledFor?: string;
  sentAt?: string;
  status: 'pending' | 'sent' | 'delivered' | 'failed' | 'cancelled';
  platforms: ('ios' | 'android' | 'web')[];
  actions?: NotificationAction[];
}

export interface NotificationAction {
  id: string;
  title: string;
  type: 'button' | 'input' | 'dismiss';
  action: string; // deep link or function to call
  icon?: string;
}

// =============================================================================
// LEADERBOARD TYPES
// =============================================================================

export interface LeaderboardEntry {
  userId: string;
  displayName: string;
  score: number;
  rank: number;
  change: number; // rank change since last update
  category: string;
  timeframe: 'daily' | 'weekly' | 'monthly' | 'all_time';
  metadata?: Record<string, any>;
  achievedAt: string;
}

export interface LeaderboardStats {
  totalEntries: number;
  averageScore: number;
  topScore: number;
  userRank?: number;
  userScore?: number;
  percentile?: number;
  lastUpdated: string;
}

// =============================================================================
// ERROR TYPES
// =============================================================================

export interface GameError {
  code: string;
  message: string;
  details?: Record<string, any>;
  timestamp: string;
  severity: 'info' | 'warning' | 'error' | 'critical';
  category: 'validation' | 'network' | 'database' | 'logic' | 'security' | 'system';
  userId?: string;
  sessionId?: string;
  stack?: string;
}

// =============================================================================
// VALIDATION TYPES
// =============================================================================

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
}

export interface ValidationError {
  field: string;
  code: string;
  message: string;
  value?: any;
}

export interface ValidationWarning {
  field: string;
  code: string;
  message: string;
  suggestion?: string;
}

// =============================================================================
// UTILITY TYPES
// =============================================================================

export type Timestamp = string; // ISO 8601 format
export type UUID = string;
export type UserId = string;
export type SessionId = string;

export interface PaginationOptions {
  limit: number;
  offset: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface SearchOptions {
  query: string;
  filters?: Record<string, any>;
  pagination: PaginationOptions;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: GameError;
  pagination?: {
    total: number;
    page: number;
    pages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
  timestamp: string;
}

// =============================================================================
// EXPORTS
// =============================================================================

export * from './competitiveTypes';
export * from './socialTypes';