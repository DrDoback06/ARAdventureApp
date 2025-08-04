// =============================================================================
// COMPETITIVE TYPES - Tournament, Leaderboard, and Ranking System Types
// =============================================================================

export interface TournamentEntry {
  tournamentId: string;
  name: string;
  description: string;
  type: 'elimination' | 'round_robin' | 'swiss' | 'ladder' | 'battle_royale';
  format: 'solo' | 'team' | 'guild';
  maxParticipants: number;
  currentParticipants: number;
  entryFee?: TournamentFee;
  prizes: TournamentPrize[];
  rules: TournamentRule[];
  schedule: TournamentSchedule;
  status: 'upcoming' | 'registration_open' | 'in_progress' | 'completed' | 'cancelled';
  visibility: 'public' | 'private' | 'guild_only' | 'invite_only';
  requirements: TournamentRequirement[];
  bracket?: TournamentBracket;
  settings: TournamentSettings;
  createdBy: string;
  createdAt: string;
  startTime: string;
  endTime?: string;
  metadata?: Record<string, any>;
}

export interface TournamentFee {
  type: 'currency' | 'item' | 'card' | 'free';
  amount?: number;
  currency?: string;
  itemId?: string;
  cardId?: string;
}

export interface TournamentPrize {
  position: number; // 1st, 2nd, 3rd, etc. Use 0 for participation prize
  type: 'currency' | 'item' | 'card' | 'title' | 'cosmetic' | 'achievement';
  amount?: number;
  currency?: string;
  itemId?: string;
  cardId?: string;
  titleId?: string;
  cosmeticId?: string;
  achievementId?: string;
  rarity?: string;
  description: string;
}

export interface TournamentRule {
  id: string;
  title: string;
  description: string;
  type: 'gameplay' | 'conduct' | 'technical' | 'format';
  enforced: boolean;
  penalty?: 'warning' | 'point_deduction' | 'disqualification';
}

export interface TournamentSchedule {
  registrationStart: string;
  registrationEnd: string;
  tournamentStart: string;
  estimatedEnd: string;
  actualEnd?: string;
  timezone: string;
  rounds?: TournamentRound[];
}

export interface TournamentRound {
  roundNumber: number;
  name: string;
  format: string;
  startTime: string;
  endTime?: string;
  status: 'pending' | 'in_progress' | 'completed';
  matches: TournamentMatch[];
}

export interface TournamentMatch {
  matchId: string;
  roundNumber: number;
  participants: TournamentParticipant[];
  status: 'scheduled' | 'in_progress' | 'completed' | 'forfeit' | 'cancelled';
  winner?: string;
  scores?: Record<string, number>;
  startTime?: string;
  endTime?: string;
  gameSettings?: Record<string, any>;
  replay?: string; // URL or identifier for match replay
}

export interface TournamentParticipant {
  userId: string;
  displayName: string;
  teamId?: string;
  guildId?: string;
  seed?: number;
  registeredAt: string;
  status: 'registered' | 'checked_in' | 'active' | 'eliminated' | 'forfeit' | 'disqualified';
  currentRound?: number;
  wins: number;
  losses: number;
  score: number;
  tiebreakers?: Record<string, number>;
}

export interface TournamentRequirement {
  type: 'level' | 'rating' | 'achievement' | 'item' | 'guild' | 'region' | 'custom';
  operator: 'equal' | 'greater' | 'less' | 'greater_equal' | 'less_equal' | 'not_equal';
  value: any;
  description: string;
}

export interface TournamentSettings {
  allowSpectators: boolean;
  allowReconnects: boolean;
  maxReconnectTime: number; // minutes
  pauseAllowed: boolean;
  maxPauseDuration: number; // minutes
  chatEnabled: boolean;
  randomSeed?: number;
  weatherLocked?: boolean;
  timeOfDayLocked?: boolean;
  customRules?: Record<string, any>;
}

export interface TournamentBracket {
  type: 'single_elimination' | 'double_elimination' | 'round_robin' | 'swiss';
  rounds: TournamentRound[];
  advancementRules: AdvancementRule[];
  tiebreakers: TiebreakerRule[];
}

export interface AdvancementRule {
  fromRound: number;
  toRound: number;
  condition: 'win' | 'top_n' | 'points' | 'ratio';
  parameter?: number;
  description: string;
}

export interface TiebreakerRule {
  priority: number;
  type: 'head_to_head' | 'points' | 'ratio' | 'time' | 'seeding' | 'random';
  description: string;
}

// =============================================================================
// LEADERBOARD TYPES
// =============================================================================

export interface LeaderboardCategory {
  id: string;
  name: string;
  description: string;
  type: 'individual' | 'team' | 'guild';
  metric: LeaderboardMetric;
  timeframe: LeaderboardTimeframe;
  eligibility: LeaderboardEligibility[];
  rewards?: LeaderboardReward[];
  settings: LeaderboardSettings;
  status: 'active' | 'paused' | 'ended' | 'archived';
  createdAt: string;
  updatedAt: string;
}

export interface LeaderboardMetric {
  type: 'total' | 'average' | 'best' | 'count' | 'ratio' | 'custom';
  field: string; // e.g., 'totalXP', 'battleRating', 'questsCompleted'
  aggregation?: 'sum' | 'avg' | 'max' | 'min' | 'count';
  formula?: string; // for custom metrics
  weight?: number;
  multiplier?: number;
}

export interface LeaderboardTimeframe {
  type: 'realtime' | 'daily' | 'weekly' | 'monthly' | 'seasonal' | 'all_time' | 'custom';
  startDate?: string;
  endDate?: string;
  resetSchedule?: ResetSchedule;
}

export interface ResetSchedule {
  frequency: 'daily' | 'weekly' | 'monthly' | 'custom';
  time: string; // HH:MM format
  timezone: string;
  dayOfWeek?: number; // 0-6 for weekly
  dayOfMonth?: number; // 1-31 for monthly
  customSchedule?: string; // cron expression
}

export interface LeaderboardEligibility {
  type: 'level' | 'region' | 'guild' | 'achievement' | 'activity' | 'custom';
  requirement: any;
  description: string;
}

export interface LeaderboardReward {
  rankStart: number;
  rankEnd: number;
  type: 'currency' | 'item' | 'card' | 'title' | 'cosmetic' | 'achievement';
  amount?: number;
  currency?: string;
  itemId?: string;
  cardId?: string;
  titleId?: string;
  cosmeticId?: string;
  achievementId?: string;
  description: string;
}

export interface LeaderboardSettings {
  maxEntries: number;
  updateFrequency: number; // minutes
  showRealNames: boolean;
  allowTies: boolean;
  minimumScore?: number;
  minimumActivity?: number; // minimum activity level to appear
  hiddenRanks?: number[]; // ranks to hide from public view
  seasonalDecay?: DecaySettings;
}

export interface DecaySettings {
  enabled: boolean;
  rate: number; // percentage per period
  period: 'daily' | 'weekly' | 'monthly';
  minimumScore?: number; // score below which decay stops
}

export interface LeaderboardSnapshot {
  leaderboardId: string;
  snapshotAt: string;
  entries: LeaderboardEntry[];
  totalEntries: number;
  averageScore: number;
  topScore: number;
  metadata?: Record<string, any>;
}

// =============================================================================
// RANKING SYSTEM TYPES
// =============================================================================

export interface RankingSystem {
  id: string;
  name: string;
  type: 'elo' | 'glicko' | 'trueskill' | 'ladder' | 'points' | 'custom';
  parameters: RankingParameters;
  tiers: RankingTier[];
  seasons: RankingSeason[];
  decay?: RankingDecay;
  placements?: PlacementSettings;
}

export interface RankingParameters {
  // ELO parameters
  kFactor?: number;
  initialRating?: number;
  
  // Glicko parameters
  initialDeviation?: number;
  volatility?: number;
  tau?: number;
  
  // TrueSkill parameters
  beta?: number;
  epsilon?: number;
  
  // Custom parameters
  customParams?: Record<string, number>;
}

export interface RankingTier {
  id: string;
  name: string;
  minRating: number;
  maxRating?: number;
  divisions?: RankingDivision[];
  color: string;
  icon: string;
  rewards?: TierReward[];
}

export interface RankingDivision {
  id: string;
  name: string;
  minRating: number;
  maxRating: number;
  promotionThreshold?: number;
  demotionThreshold?: number;
}

export interface TierReward {
  type: 'season_end' | 'promotion' | 'milestone' | 'daily';
  items: LeaderboardReward[];
}

export interface RankingSeason {
  id: string;
  name: string;
  startDate: string;
  endDate: string;
  status: 'upcoming' | 'active' | 'ended';
  rewards: SeasonReward[];
  changes?: SeasonChange[];
}

export interface SeasonReward {
  tier: string;
  division?: string;
  minGames?: number;
  rewards: LeaderboardReward[];
}

export interface SeasonChange {
  type: 'rating_reset' | 'soft_reset' | 'parameter_change' | 'tier_change';
  description: string;
  parameters?: Record<string, any>;
}

export interface RankingDecay {
  enabled: boolean;
  threshold: number; // days of inactivity before decay starts
  rate: number; // rating lost per day after threshold
  minimumRating: number; // rating floor
  maxDecay: number; // maximum rating that can be lost to decay
}

export interface PlacementSettings {
  gamesRequired: number;
  uncertaintyMultiplier: number;
  maxInitialRating: number;
  minInitialRating: number;
  carryOverPercentage?: number; // percentage of previous season rating
}

// =============================================================================
// MATCHMAKING TYPES
// =============================================================================

export interface MatchmakingRequest {
  userId: string;
  gameMode: string;
  preferences: MatchmakingPreferences;
  rating: number;
  uncertainty?: number;
  queueTime: number;
  region?: string;
  language?: string;
  timestamp: string;
}

export interface MatchmakingPreferences {
  maxWaitTime: number; // seconds
  skillRange: number; // +/- rating points
  regionPreference: 'strict' | 'preferred' | 'any';
  languagePreference: 'strict' | 'preferred' | 'any';
  avoidRecentOpponents: boolean;
  avoidBlockedPlayers: boolean;
  preferFriends: boolean;
  customSettings?: Record<string, any>;
}

export interface MatchmakingResult {
  matchId?: string;
  status: 'matched' | 'searching' | 'timeout' | 'cancelled' | 'error';
  estimatedWaitTime?: number; // seconds
  averageRating?: number;
  ratingSpread?: number;
  participants?: MatchParticipant[];
  timestamp: string;
  error?: string;
}

export interface MatchParticipant {
  userId: string;
  displayName: string;
  rating: number;
  uncertainty?: number;
  team?: number;
  role?: string;
  region: string;
  language: string;
}

// =============================================================================
// MATCH HISTORY TYPES
// =============================================================================

export interface MatchHistory {
  matchId: string;
  gameMode: string;
  format: string;
  participants: MatchParticipant[];
  result: MatchResult;
  duration: number; // seconds
  startTime: string;
  endTime: string;
  server: string;
  version: string;
  replay?: string;
  metadata?: Record<string, any>;
}

export interface MatchResult {
  winner?: string; // userId or team identifier
  scores: Record<string, number>;
  statistics: Record<string, MatchStatistic>;
  ratingChanges: Record<string, RatingChange>;
  achievements?: Record<string, string[]>;
  penalties?: Record<string, MatchPenalty>;
}

export interface MatchStatistic {
  userId: string;
  stats: Record<string, number>;
  performance: PerformanceMetric[];
  milestones?: string[];
}

export interface PerformanceMetric {
  name: string;
  value: number;
  percentile?: number;
  trend?: 'improving' | 'declining' | 'stable';
}

export interface RatingChange {
  userId: string;
  oldRating: number;
  newRating: number;
  change: number;
  reason: 'win' | 'loss' | 'draw' | 'forfeit' | 'penalty';
  confidence?: number;
}

export interface MatchPenalty {
  type: 'warning' | 'time_penalty' | 'rating_penalty' | 'suspension';
  reason: string;
  duration?: number; // minutes for suspensions
  ratingLoss?: number;
  appealable: boolean;
}

// =============================================================================
// EXPORTS
// =============================================================================

export * from './gameTypes';
export * from './socialTypes';