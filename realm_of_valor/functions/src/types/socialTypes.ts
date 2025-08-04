// =============================================================================
// SOCIAL TYPES - Guild, Friends, Community, and Social Interaction Types
// =============================================================================

export interface GuildActivity {
  activityId: string;
  guildId: string;
  userId: string;
  type: 'quest_completed' | 'battle_won' | 'member_joined' | 'member_promoted' | 'achievement_unlocked' | 'donation' | 'event_participated' | 'challenge_completed';
  description: string;
  data: Record<string, any>;
  points: number;
  timestamp: string;
  visibility: 'public' | 'guild_only' | 'officers_only';
  reactions?: SocialReaction[];
  comments?: SocialComment[];
}

export interface Guild {
  guildId: string;
  name: string;
  description: string;
  tag: string; // 3-5 character guild tag
  type: 'casual' | 'competitive' | 'social' | 'hardcore' | 'educational';
  privacy: 'public' | 'invite_only' | 'application_required' | 'private';
  level: number;
  experience: number;
  members: GuildMember[];
  maxMembers: number;
  settings: GuildSettings;
  rules: GuildRule[];
  achievements: GuildAchievement[];
  stats: GuildStats;
  treasury: GuildTreasury;
  events: GuildEvent[];
  alliances: GuildAlliance[];
  createdBy: string;
  createdAt: string;
  lastActivity: string;
  metadata?: Record<string, any>;
}

export interface GuildMember {
  userId: string;
  displayName: string;
  role: GuildRole;
  joinedAt: string;
  lastActive: string;
  contribution: GuildContribution;
  permissions: GuildPermission[];
  notes?: string; // officer notes about the member
  status: 'active' | 'inactive' | 'on_leave' | 'kicked' | 'banned';
}

export interface GuildRole {
  id: string;
  name: string;
  level: number; // 0 = member, 1 = officer, 2 = leader
  permissions: GuildPermission[];
  color: string;
  badge?: string;
  canPromote: boolean;
  canKick: boolean;
  canInvite: boolean;
  canManageEvents: boolean;
  canManageTreasury: boolean;
}

export interface GuildPermission {
  id: string;
  name: string;
  description: string;
  category: 'management' | 'social' | 'events' | 'treasury' | 'warfare';
}

export interface GuildContribution {
  totalPoints: number;
  weeklyPoints: number;
  monthlyPoints: number;
  lastContribution: string;
  categories: Record<string, number>; // quest, battle, donation, etc.
  streak: number; // days of consecutive activity
  rank: number; // rank within guild
}

export interface GuildSettings {
  language: string;
  timezone: string;
  region: string;
  minimumLevel: number;
  activityRequirement: number; // days
  autoKickInactive: boolean;
  allowApplications: boolean;
  requireApproval: boolean;
  welcomeMessage?: string;
  discordLink?: string;
  chatModeration: ChatModerationSettings;
}

export interface ChatModerationSettings {
  enabled: boolean;
  autoModeration: boolean;
  profanityFilter: boolean;
  spamPrevention: boolean;
  rateLimiting: number; // messages per minute
  moderatorRole: string;
}

export interface GuildRule {
  id: string;
  title: string;
  description: string;
  priority: number;
  enforcementLevel: 'guideline' | 'warning' | 'kick' | 'ban';
  createdBy: string;
  createdAt: string;
}

export interface GuildAchievement {
  achievementId: string;
  name: string;
  description: string;
  category: 'growth' | 'activity' | 'competition' | 'cooperation' | 'special';
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
  progress: number;
  maxProgress: number;
  unlockedAt?: string;
  unlockedBy?: string;
  rewards: GuildReward[];
}

export interface GuildReward {
  type: 'experience' | 'treasury' | 'cosmetic' | 'perk' | 'title';
  amount?: number;
  itemId?: string;
  description: string;
}

export interface GuildStats {
  totalMembers: number;
  activeMembers: number; // active in last 7 days
  averageLevel: number;
  totalExperience: number;
  questsCompleted: number;
  battlesWon: number;
  tournamentsWon: number;
  achievementsUnlocked: number;
  treasury: number;
  weeklyActivity: number;
  monthlyActivity: number;
  ranking: GuildRanking;
}

export interface GuildRanking {
  globalRank: number;
  regionalRank: number;
  categoryRank: Record<string, number>;
  ratingPoints: number;
  tier: string;
}

export interface GuildTreasury {
  currentFunds: Record<string, number>; // currency type -> amount
  weeklyIncome: Record<string, number>;
  monthlyIncome: Record<string, number>;
  totalDonations: Record<string, number>;
  topDonors: TreasuryDonor[];
  expenditures: TreasuryExpenditure[];
}

export interface TreasuryDonor {
  userId: string;
  displayName: string;
  amount: number;
  currency: string;
  timestamp: string;
}

export interface TreasuryExpenditure {
  id: string;
  type: 'event' | 'upgrade' | 'reward' | 'maintenance';
  amount: number;
  currency: string;
  description: string;
  authorizedBy: string;
  timestamp: string;
}

export interface GuildEvent {
  eventId: string;
  name: string;
  description: string;
  type: 'raid' | 'tournament' | 'quest' | 'social' | 'competition' | 'training';
  status: 'planned' | 'registration_open' | 'in_progress' | 'completed' | 'cancelled';
  startTime: string;
  endTime?: string;
  maxParticipants?: number;
  requirements?: EventRequirement[];
  rewards: GuildReward[];
  participants: EventParticipant[];
  organizers: string[];
  location?: EventLocation;
}

export interface EventRequirement {
  type: 'level' | 'role' | 'contribution' | 'item' | 'achievement';
  value: any;
  description: string;
}

export interface EventParticipant {
  userId: string;
  displayName: string;
  status: 'registered' | 'confirmed' | 'attended' | 'no_show' | 'cancelled';
  registeredAt: string;
  performance?: EventPerformance;
}

export interface EventPerformance {
  score: number;
  rank: number;
  achievements: string[];
  contribution: number;
  feedback?: string;
}

export interface EventLocation {
  type: 'virtual' | 'real_world' | 'specific_area';
  coordinates?: { latitude: number; longitude: number };
  areaId?: string;
  description: string;
}

export interface GuildAlliance {
  allianceId: string;
  guildId: string;
  guildName: string;
  type: 'peace' | 'trade' | 'military' | 'full_alliance';
  status: 'proposed' | 'active' | 'expired' | 'broken';
  benefits: AllianceBenefit[];
  conditions: AllianceCondition[];
  startDate: string;
  endDate?: string;
  proposedBy: string;
  acceptedBy?: string;
}

export interface AllianceBenefit {
  type: 'trade_bonus' | 'shared_events' | 'mutual_defense' | 'resource_sharing';
  value: number;
  description: string;
}

export interface AllianceCondition {
  type: 'non_aggression' | 'minimum_level' | 'shared_objectives' | 'resource_quota';
  requirement: any;
  description: string;
}

// =============================================================================
// FRIENDS AND SOCIAL NETWORK TYPES
// =============================================================================

export interface SocialProfile {
  userId: string;
  displayName: string;
  realName?: string;
  bio?: string;
  avatar: string;
  level: number;
  title?: string;
  badges: SocialBadge[];
  stats: SocialStats;
  preferences: SocialPreferences;
  privacy: PrivacySettings;
  status: UserStatus;
  location?: UserLocation;
  joinedAt: string;
  lastSeen: string;
}

export interface SocialBadge {
  id: string;
  name: string;
  description: string;
  icon: string;
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
  category: 'achievement' | 'seasonal' | 'special' | 'social' | 'competitive';
  unlockedAt: string;
  visible: boolean;
}

export interface SocialStats {
  totalFriends: number;
  mutualFriends: number;
  guildMembers: number;
  battlesPlayed: number;
  questsCompleted: number;
  achievementsUnlocked: number;
  socialScore: number;
  reputation: number;
  helpfulVotes: number;
  commendations: SocialCommendation[];
}

export interface SocialCommendation {
  type: 'helpful' | 'friendly' | 'skilled' | 'leader' | 'mentor';
  count: number;
  recentFrom: string[];
}

export interface SocialPreferences {
  language: string;
  timezone: string;
  visibility: 'public' | 'friends_only' | 'private';
  allowFriendRequests: boolean;
  allowGuildInvites: boolean;
  allowPartyInvites: boolean;
  showOnlineStatus: boolean;
  showActivity: boolean;
  notificationSettings: NotificationSettings;
}

export interface NotificationSettings {
  friendRequests: boolean;
  guildInvites: boolean;
  partyInvites: boolean;
  battleChallenges: boolean;
  questInvites: boolean;
  achievements: boolean;
  guildActivity: boolean;
  friendActivity: boolean;
  directMessages: boolean;
}

export interface PrivacySettings {
  profileVisibility: 'public' | 'friends' | 'guild' | 'private';
  statsVisibility: 'public' | 'friends' | 'guild' | 'private';
  friendListVisibility: 'public' | 'friends' | 'private';
  guildVisibility: 'public' | 'friends' | 'private';
  locationSharing: 'always' | 'friends' | 'guild' | 'never';
  activityTracking: boolean;
  dataCollection: boolean;
}

export interface UserStatus {
  online: boolean;
  status: 'online' | 'away' | 'busy' | 'invisible' | 'offline';
  activity?: CurrentActivity;
  customMessage?: string;
  lastActivity: string;
}

export interface CurrentActivity {
  type: 'in_battle' | 'in_quest' | 'in_guild' | 'browsing' | 'idle';
  details?: string;
  startTime: string;
  joinable?: boolean;
}

export interface UserLocation {
  city?: string;
  region?: string;
  country: string;
  timezone: string;
  approximate: boolean; // whether location is approximated for privacy
}

export interface Friendship {
  friendshipId: string;
  userId1: string;
  userId2: string;
  status: 'pending' | 'accepted' | 'blocked' | 'removed';
  initiatedBy: string;
  createdAt: string;
  acceptedAt?: string;
  metadata?: FriendshipMetadata;
}

export interface FriendshipMetadata {
  source: 'search' | 'guild' | 'quest' | 'battle' | 'suggestion' | 'invite_code';
  mutualFriends: number;
  interactionCount: number;
  lastInteraction: string;
  favorited: boolean;
  notes?: string;
}

// =============================================================================
// SOCIAL EVENTS AND ACTIVITIES TYPES
// =============================================================================

export interface SocialEvent {
  eventId: string;
  type: 'friend_request' | 'guild_invite' | 'party_invite' | 'battle_challenge' | 'quest_invite' | 'achievement_share' | 'status_update' | 'location_checkin';
  sourceUserId: string;
  targetUserId?: string;
  targetGuildId?: string;
  data: Record<string, any>;
  message?: string;
  status: 'pending' | 'accepted' | 'declined' | 'expired' | 'cancelled';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  timestamp: string;
  expiresAt?: string;
  readAt?: string;
  respondedAt?: string;
}

export interface SocialFeed {
  feedId: string;
  userId: string;
  items: SocialFeedItem[];
  lastUpdated: string;
  preferences: FeedPreferences;
}

export interface SocialFeedItem {
  itemId: string;
  type: 'achievement' | 'level_up' | 'battle_victory' | 'quest_completion' | 'guild_activity' | 'friendship' | 'status_update';
  sourceUserId: string;
  sourceUserName: string;
  content: string;
  data: Record<string, any>;
  timestamp: string;
  reactions: SocialReaction[];
  comments: SocialComment[];
  visibility: 'public' | 'friends' | 'guild' | 'private';
  priority: number;
}

export interface FeedPreferences {
  showAchievements: boolean;
  showBattles: boolean;
  showQuests: boolean;
  showGuildActivity: boolean;
  showFriendActivity: boolean;
  showStatusUpdates: boolean;
  filterByRelevance: boolean;
  maxItemsPerDay: number;
}

export interface SocialReaction {
  reactionId: string;
  userId: string;
  type: 'like' | 'love' | 'wow' | 'laugh' | 'angry' | 'sad' | 'celebrate';
  timestamp: string;
}

export interface SocialComment {
  commentId: string;
  userId: string;
  userName: string;
  content: string;
  timestamp: string;
  editedAt?: string;
  reactions: SocialReaction[];
  replies: SocialComment[];
  reported: boolean;
  moderated: boolean;
}

// =============================================================================
// COMMUNITY AND GROUP TYPES
// =============================================================================

export interface Community {
  communityId: string;
  name: string;
  description: string;
  type: 'official' | 'regional' | 'topic' | 'guild_network' | 'fan_group';
  category: 'general' | 'strategy' | 'trading' | 'social' | 'competitive' | 'help';
  visibility: 'public' | 'invite_only' | 'private';
  members: CommunityMember[];
  maxMembers?: number;
  moderators: string[];
  rules: CommunityRule[];
  channels: CommunityChannel[];
  events: CommunityEvent[];
  stats: CommunityStats;
  settings: CommunitySettings;
  createdBy: string;
  createdAt: string;
  lastActivity: string;
}

export interface CommunityMember {
  userId: string;
  displayName: string;
  role: 'member' | 'moderator' | 'admin' | 'owner';
  joinedAt: string;
  lastActive: string;
  contributionScore: number;
  status: 'active' | 'inactive' | 'muted' | 'banned';
  permissions: string[];
}

export interface CommunityRule {
  id: string;
  title: string;
  description: string;
  severity: 'guideline' | 'warning' | 'temporary_ban' | 'permanent_ban';
  category: 'content' | 'behavior' | 'spam' | 'harassment' | 'general';
}

export interface CommunityChannel {
  channelId: string;
  name: string;
  description: string;
  type: 'text' | 'voice' | 'announcement' | 'event' | 'trading';
  permissions: ChannelPermission[];
  settings: ChannelSettings;
  messages: CommunityMessage[];
  pinnedMessages: string[];
  lastActivity: string;
}

export interface ChannelPermission {
  role: string;
  canRead: boolean;
  canWrite: boolean;
  canModerate: boolean;
  canPin: boolean;
  canInvite: boolean;
}

export interface ChannelSettings {
  slowMode: number; // seconds between messages
  maxMessageLength: number;
  allowAttachments: boolean;
  allowReactions: boolean;
  requireApproval: boolean;
  autoModeration: boolean;
}

export interface CommunityMessage {
  messageId: string;
  userId: string;
  userName: string;
  content: string;
  type: 'text' | 'image' | 'file' | 'embed' | 'system';
  timestamp: string;
  editedAt?: string;
  reactions: SocialReaction[];
  replies: CommunityMessage[];
  pinned: boolean;
  reported: boolean;
  moderated: boolean;
  attachments?: MessageAttachment[];
}

export interface MessageAttachment {
  id: string;
  name: string;
  type: 'image' | 'file' | 'video' | 'audio';
  url: string;
  size: number;
  mimeType: string;
}

export interface CommunityEvent {
  eventId: string;
  name: string;
  description: string;
  type: 'discussion' | 'tournament' | 'workshop' | 'social' | 'announcement';
  startTime: string;
  endTime?: string;
  organizer: string;
  participants: EventParticipant[];
  status: 'planned' | 'live' | 'completed' | 'cancelled';
  location?: EventLocation;
}

export interface CommunityStats {
  totalMembers: number;
  activeMembers: number;
  messagesPerDay: number;
  eventsPerMonth: number;
  topContributors: string[];
  growthRate: number;
  engagementScore: number;
}

export interface CommunitySettings {
  joinMethod: 'open' | 'approval' | 'invite_only';
  defaultRole: string;
  welcomeMessage?: string;
  guidelines?: string;
  moderationLevel: 'none' | 'basic' | 'strict' | 'automated';
  allowInvites: boolean;
  allowEvents: boolean;
  maxChannels: number;
}

// =============================================================================
// TRADING AND MARKETPLACE TYPES
// =============================================================================

export interface TradeOffer {
  offerId: string;
  fromUserId: string;
  toUserId: string;
  offerItems: TradeItem[];
  requestItems: TradeItem[];
  status: 'pending' | 'accepted' | 'declined' | 'cancelled' | 'expired' | 'completed';
  message?: string;
  createdAt: string;
  expiresAt: string;
  respondedAt?: string;
  completedAt?: string;
  fees: TradeFee[];
}

export interface TradeItem {
  type: 'card' | 'currency' | 'item' | 'cosmetic';
  id: string;
  quantity: number;
  metadata?: Record<string, any>;
  marketValue?: number;
}

export interface TradeFee {
  type: 'transaction' | 'premium' | 'insurance';
  amount: number;
  currency: string;
  description: string;
}

export interface MarketplaceListing {
  listingId: string;
  sellerId: string;
  item: TradeItem;
  price: number;
  currency: string;
  status: 'active' | 'sold' | 'cancelled' | 'expired';
  createdAt: string;
  expiresAt?: string;
  soldAt?: string;
  buyerId?: string;
  views: number;
  watchers: string[];
}

// =============================================================================
// MODERATION AND SAFETY TYPES
// =============================================================================

export interface ModerationAction {
  actionId: string;
  type: 'warning' | 'mute' | 'kick' | 'ban' | 'content_removal' | 'account_restriction';
  targetUserId: string;
  moderatorId: string;
  reason: string;
  details?: string;
  duration?: number; // minutes
  evidence?: ModerationEvidence[];
  appealable: boolean;
  appealDeadline?: string;
  status: 'active' | 'expired' | 'appealed' | 'overturned';
  timestamp: string;
}

export interface ModerationEvidence {
  type: 'message' | 'image' | 'video' | 'report' | 'system_log';
  content: string;
  url?: string;
  metadata?: Record<string, any>;
  timestamp: string;
}

export interface SafetyReport {
  reportId: string;
  reporterId: string;
  targetUserId?: string;
  targetContentId?: string;
  type: 'harassment' | 'spam' | 'inappropriate_content' | 'cheating' | 'hate_speech' | 'other';
  description: string;
  evidence?: ModerationEvidence[];
  priority: 'low' | 'medium' | 'high' | 'critical';
  status: 'pending' | 'investigating' | 'resolved' | 'dismissed';
  assignedTo?: string;
  resolution?: string;
  timestamp: string;
  resolvedAt?: string;
}

// =============================================================================
// EXPORTS
// =============================================================================

export * from './gameTypes';
export * from './competitiveTypes';