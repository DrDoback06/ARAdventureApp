import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

// Initialize Firebase Admin
admin.initializeApp();

// Import services
import { MultiplayerService } from './services/multiplayerService';
import { TournamentService } from './services/tournamentService';
import { LeaderboardService } from './services/leaderboardService';
import { MatchmakingService } from './services/matchmakingService';
import { GuildService } from './services/guildService';
import { NotificationService } from './services/notificationService';
import { AnalyticsService } from './services/analyticsService';
import { AntiCheatService } from './services/antiCheatService';
import { ContentModerationService } from './services/contentModerationService';
import { WeatherService } from './services/weatherService';
import { AICompanionService } from './services/aiCompanionService';

// Import middleware
import { authMiddleware } from './middleware/auth';
import { rateLimitMiddleware } from './middleware/rateLimit';
import { validationMiddleware } from './middleware/validation';

// Import models and types
import { BattleResult, PlayerStats, QuestCompletion, AchievementUnlock } from './types/gameTypes';
import { TournamentEntry, LeaderboardEntry } from './types/competitiveTypes';
import { GuildActivity, SocialEvent } from './types/socialTypes';

// Create Express app
const app = express();

// Apply middleware
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Apply rate limiting
app.use(rateLimitMiddleware);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '2.0.0',
    services: ['multiplayer', 'tournaments', 'leaderboards', 'guilds', 'ai-companion']
  });
});

// =============================================================================
// MULTIPLAYER BATTLE FUNCTIONS
// =============================================================================

/**
 * Real-time multiplayer battle matchmaking
 */
export const findMultiplayerMatch = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { battleType, skillLevel, preferences } = data;
  const userId = context.auth.uid;

  try {
    const matchResult = await MatchmakingService.findMatch(userId, {
      battleType,
      skillLevel,
      preferences,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log matchmaking analytics
    await AnalyticsService.trackEvent('multiplayer_match_requested', {
      userId,
      battleType,
      skillLevel,
      matchFound: !!matchResult.matchId
    });

    return matchResult;
  } catch (error) {
    console.error('Multiplayer matchmaking error:', error);
    throw new functions.https.HttpsError('internal', 'Matchmaking failed');
  }
});

/**
 * Process multiplayer battle results
 */
export const processMultiplayerBattle = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { battleId, battleResult } = data as { battleId: string; battleResult: BattleResult };
  const userId = context.auth.uid;

  try {
    // Validate battle result with anti-cheat
    const isValid = await AntiCheatService.validateBattleResult(userId, battleResult);
    if (!isValid) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid battle result detected');
    }

    // Process the battle
    const result = await MultiplayerService.processBattleResult(battleId, userId, battleResult);

    // Update leaderboards
    await LeaderboardService.updatePlayerRanking(userId, result.rating);

    // Award achievements
    if (result.achievements?.length > 0) {
      for (const achievement of result.achievements) {
        await processAchievementUnlock.call({ data: { userId, achievement } });
      }
    }

    // Send notifications to players
    await NotificationService.sendBattleResultNotification(battleId, result);

    return result;
  } catch (error) {
    console.error('Battle processing error:', error);
    throw new functions.https.HttpsError('internal', 'Battle processing failed');
  }
});

/**
 * Real-time battle state synchronization
 */
export const syncBattleState = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { battleId, gameState, actionType } = data;
  const userId = context.auth.uid;

  try {
    const syncResult = await MultiplayerService.syncBattleState(battleId, userId, {
      gameState,
      actionType,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    return syncResult;
  } catch (error) {
    console.error('Battle sync error:', error);
    throw new functions.https.HttpsError('internal', 'Battle synchronization failed');
  }
});

// =============================================================================
// TOURNAMENT SYSTEM FUNCTIONS
// =============================================================================

/**
 * Create a new tournament
 */
export const createTournament = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const tournamentData = data as TournamentEntry;
  
  try {
    const tournament = await TournamentService.createTournament(tournamentData);
    
    // Schedule tournament notifications
    await NotificationService.scheduleTournamentNotifications(tournament.id);
    
    return tournament;
  } catch (error) {
    console.error('Tournament creation error:', error);
    throw new functions.https.HttpsError('internal', 'Tournament creation failed');
  }
});

/**
 * Join a tournament
 */
export const joinTournament = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { tournamentId } = data;
  const userId = context.auth.uid;

  try {
    const result = await TournamentService.joinTournament(tournamentId, userId);
    
    // Send confirmation notification
    await NotificationService.sendTournamentJoinConfirmation(userId, tournamentId);
    
    return result;
  } catch (error) {
    console.error('Tournament join error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to join tournament');
  }
});

/**
 * Process tournament bracket advancement
 */
export const advanceTournamentBracket = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { tournamentId, matchId, winnerId } = data;
  
  try {
    const result = await TournamentService.advanceBracket(tournamentId, matchId, winnerId);
    
    // Update tournament leaderboards
    await LeaderboardService.updateTournamentRankings(tournamentId);
    
    return result;
  } catch (error) {
    console.error('Tournament bracket error:', error);
    throw new functions.https.HttpsError('internal', 'Tournament advancement failed');
  }
});

// =============================================================================
// GUILD SYSTEM FUNCTIONS
// =============================================================================

/**
 * Create a new guild
 */
export const createGuild = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { name, description, tags, isPublic } = data;
  const creatorId = context.auth.uid;

  try {
    const guild = await GuildService.createGuild(creatorId, {
      name,
      description,
      tags,
      isPublic,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Award guild founder achievement
    await processAchievementUnlock.call({ 
      data: { 
        userId: creatorId, 
        achievement: { id: 'guild_founder', name: 'Guild Founder' } 
      } 
    });

    return guild;
  } catch (error) {
    console.error('Guild creation error:', error);
    throw new functions.https.HttpsError('internal', 'Guild creation failed');
  }
});

/**
 * Process guild activities and rewards
 */
export const processGuildActivity = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const activity = data as GuildActivity;
  const userId = context.auth.uid;

  try {
    const result = await GuildService.processActivity(userId, activity);
    
    // Update guild leaderboards
    await LeaderboardService.updateGuildRankings(activity.guildId);
    
    return result;
  } catch (error) {
    console.error('Guild activity error:', error);
    throw new functions.https.HttpsError('internal', 'Guild activity processing failed');
  }
});

// =============================================================================
// LEADERBOARD FUNCTIONS
// =============================================================================

/**
 * Get global leaderboards with pagination
 */
export const getGlobalLeaderboards = functions.https.onCall(async (data, context) => {
  const { category, timeframe, limit = 50, offset = 0 } = data;

  try {
    const leaderboards = await LeaderboardService.getGlobalLeaderboards({
      category,
      timeframe,
      limit,
      offset
    });

    return leaderboards;
  } catch (error) {
    console.error('Leaderboard fetch error:', error);
    throw new functions.https.HttpsError('internal', 'Leaderboard fetch failed');
  }
});

/**
 * Get player rankings and nearby competitors
 */
export const getPlayerRankings = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const userId = context.auth.uid;
  const { categories } = data;

  try {
    const rankings = await LeaderboardService.getPlayerRankings(userId, categories);
    return rankings;
  } catch (error) {
    console.error('Player rankings error:', error);
    throw new functions.https.HttpsError('internal', 'Rankings fetch failed');
  }
});

// =============================================================================
// AI COMPANION FUNCTIONS
// =============================================================================

/**
 * Process AI companion interactions
 */
export const processCompanionInteraction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { message, context: conversationContext } = data;
  const userId = context.auth.uid;

  try {
    const response = await AICompanionService.processInteraction(userId, {
      message,
      context: conversationContext,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Track AI interaction analytics
    await AnalyticsService.trackEvent('ai_companion_interaction', {
      userId,
      messageLength: message.length,
      responseType: response.type
    });

    return response;
  } catch (error) {
    console.error('AI companion error:', error);
    throw new functions.https.HttpsError('internal', 'AI companion interaction failed');
  }
});

/**
 * Get personalized AI recommendations
 */
export const getAIRecommendations = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const userId = context.auth.uid;
  const { category, playerData } = data;

  try {
    const recommendations = await AICompanionService.generateRecommendations(userId, {
      category,
      playerData,
      timestamp: new Date()
    });

    return recommendations;
  } catch (error) {
    console.error('AI recommendations error:', error);
    throw new functions.https.HttpsError('internal', 'AI recommendations failed');
  }
});

// =============================================================================
// QUEST AND ACHIEVEMENT FUNCTIONS
// =============================================================================

/**
 * Process quest completion with multiplayer validation
 */
export const processQuestCompletion = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const completion = data as QuestCompletion;
  const userId = context.auth.uid;

  try {
    // Validate quest completion
    const isValid = await AntiCheatService.validateQuestCompletion(userId, completion);
    if (!isValid) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid quest completion');
    }

    // Process quest rewards
    const result = await MultiplayerService.processQuestCompletion(userId, completion);

    // Update achievements
    if (result.triggeredAchievements?.length > 0) {
      for (const achievement of result.triggeredAchievements) {
        await processAchievementUnlock.call({ data: { userId, achievement } });
      }
    }

    // Update guild progress if applicable
    if (completion.guildQuest) {
      await GuildService.updateQuestProgress(completion.guildId!, completion);
    }

    return result;
  } catch (error) {
    console.error('Quest completion error:', error);
    throw new functions.https.HttpsError('internal', 'Quest completion failed');
  }
});

/**
 * Process achievement unlock with social features
 */
export const processAchievementUnlock = functions.https.onCall(async (data, context) => {
  const { userId, achievement } = data as { userId: string; achievement: AchievementUnlock };

  try {
    // Process achievement unlock
    const result = await MultiplayerService.processAchievementUnlock(userId, achievement);

    // Send notifications to friends
    await NotificationService.sendAchievementNotification(userId, achievement);

    // Update leaderboards
    await LeaderboardService.updateAchievementProgress(userId, achievement);

    // Track achievement analytics
    await AnalyticsService.trackEvent('achievement_unlocked', {
      userId,
      achievementId: achievement.id,
      rarity: achievement.rarity,
      timestamp: new Date()
    });

    return result;
  } catch (error) {
    console.error('Achievement unlock error:', error);
    throw new functions.https.HttpsError('internal', 'Achievement processing failed');
  }
});

// =============================================================================
// WEATHER AND ENVIRONMENTAL FUNCTIONS
// =============================================================================

/**
 * Get enhanced weather data for gameplay
 */
export const getGameplayWeather = functions.https.onCall(async (data, context) => {
  const { latitude, longitude, includeEffects = true } = data;

  try {
    const weatherData = await WeatherService.getEnhancedWeatherData(latitude, longitude);
    
    if (includeEffects) {
      weatherData.gameplayEffects = await WeatherService.calculateGameplayEffects(weatherData);
    }

    return weatherData;
  } catch (error) {
    console.error('Weather data error:', error);
    throw new functions.https.HttpsError('internal', 'Weather data fetch failed');
  }
});

// =============================================================================
// FIRESTORE TRIGGERS
// =============================================================================

/**
 * Handle user profile updates
 */
export const onUserProfileUpdate = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    try {
      // Update leaderboards if ranking-relevant data changed
      if (beforeData.totalXP !== afterData.totalXP || 
          beforeData.battleRating !== afterData.battleRating) {
        await LeaderboardService.updatePlayerRanking(userId, afterData);
      }

      // Update guild member data if guild-relevant data changed
      if (beforeData.guildId && 
          (beforeData.level !== afterData.level || beforeData.achievements !== afterData.achievements)) {
        await GuildService.updateMemberData(beforeData.guildId, userId, afterData);
      }

      // Track profile update analytics
      await AnalyticsService.trackEvent('profile_updated', {
        userId,
        changedFields: Object.keys(afterData).filter(key => beforeData[key] !== afterData[key])
      });
    } catch (error) {
      console.error('Profile update processing error:', error);
    }
  });

/**
 * Handle new battle creation
 */
export const onBattleCreated = functions.firestore
  .document('battles/{battleId}')
  .onCreate(async (snapshot, context) => {
    const battleId = context.params.battleId;
    const battleData = snapshot.data();

    try {
      // Set up real-time battle listeners
      await MultiplayerService.initializeBattleListeners(battleId, battleData);

      // Send battle start notifications
      await NotificationService.sendBattleStartNotification(battleId, battleData);

      // Track battle analytics
      await AnalyticsService.trackEvent('battle_created', {
        battleId,
        battleType: battleData.type,
        playerCount: battleData.players?.length || 0
      });
    } catch (error) {
      console.error('Battle creation processing error:', error);
    }
  });

/**
 * Handle guild activity updates
 */
export const onGuildActivityUpdate = functions.firestore
  .document('guilds/{guildId}/activities/{activityId}')
  .onCreate(async (snapshot, context) => {
    const guildId = context.params.guildId;
    const activityData = snapshot.data();

    try {
      // Update guild statistics
      await GuildService.updateGuildStats(guildId, activityData);

      // Send guild notifications
      await NotificationService.sendGuildActivityNotification(guildId, activityData);

      // Update guild leaderboards
      await LeaderboardService.updateGuildRankings(guildId);
    } catch (error) {
      console.error('Guild activity processing error:', error);
    }
  });

// =============================================================================
// SCHEDULED FUNCTIONS
// =============================================================================

/**
 * Daily leaderboard updates and rewards
 */
export const dailyLeaderboardUpdate = functions.pubsub
  .schedule('0 0 * * *') // Run daily at midnight UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      console.log('Starting daily leaderboard update...');
      
      // Update all leaderboard categories
      await LeaderboardService.performDailyUpdate();
      
      // Distribute daily rewards
      await LeaderboardService.distributeDailyRewards();
      
      // Generate analytics reports
      await AnalyticsService.generateDailyReports();
      
      console.log('Daily leaderboard update completed');
    } catch (error) {
      console.error('Daily leaderboard update error:', error);
    }
  });

/**
 * Weekly tournament cleanup and archival
 */
export const weeklyTournamentCleanup = functions.pubsub
  .schedule('0 2 * * 0') // Run weekly on Sunday at 2 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      console.log('Starting weekly tournament cleanup...');
      
      // Archive completed tournaments
      await TournamentService.archiveCompletedTournaments();
      
      // Clean up old battle data
      await MultiplayerService.cleanupOldBattles();
      
      // Generate weekly analytics
      await AnalyticsService.generateWeeklyReports();
      
      console.log('Weekly tournament cleanup completed');
    } catch (error) {
      console.error('Weekly tournament cleanup error:', error);
    }
  });

/**
 * Hourly weather updates for all active regions
 */
export const hourlyWeatherUpdate = functions.pubsub
  .schedule('0 * * * *') // Run every hour
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      console.log('Starting hourly weather update...');
      
      // Update weather data for all active regions
      await WeatherService.updateActiveRegions();
      
      // Process weather-based events and bonuses
      await WeatherService.processWeatherEvents();
      
      console.log('Hourly weather update completed');
    } catch (error) {
      console.error('Hourly weather update error:', error);
    }
  });

// =============================================================================
// ANALYTICS AND MONITORING FUNCTIONS
// =============================================================================

/**
 * Process real-time analytics events
 */
export const processAnalyticsEvent = functions.https.onCall(async (data, context) => {
  const { eventType, eventData, userId } = data;

  try {
    await AnalyticsService.processRealtimeEvent(eventType, eventData, userId);
    return { success: true };
  } catch (error) {
    console.error('Analytics processing error:', error);
    throw new functions.https.HttpsError('internal', 'Analytics processing failed');
  }
});

/**
 * Get player analytics dashboard
 */
export const getPlayerAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const userId = context.auth.uid;
  const { timeframe = '7d' } = data;

  try {
    const analytics = await AnalyticsService.getPlayerDashboard(userId, timeframe);
    return analytics;
  } catch (error) {
    console.error('Player analytics error:', error);
    throw new functions.https.HttpsError('internal', 'Analytics fetch failed');
  }
});

// =============================================================================
// CONTENT MODERATION FUNCTIONS
// =============================================================================

/**
 * Moderate user-generated content
 */
export const moderateContent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { content, contentType } = data;

  try {
    const moderationResult = await ContentModerationService.moderateContent(content, contentType);
    return moderationResult;
  } catch (error) {
    console.error('Content moderation error:', error);
    throw new functions.https.HttpsError('internal', 'Content moderation failed');
  }
});

// =============================================================================
// EXPORT EXPRESS APP
// =============================================================================

/**
 * Main API endpoint
 */
export const api = functions.https.onRequest(app);

// Export individual functions for testing
export {
  MultiplayerService,
  TournamentService,
  LeaderboardService,
  MatchmakingService,
  GuildService,
  NotificationService,
  AnalyticsService,
  AntiCheatService,
  ContentModerationService,
  WeatherService,
  AICompanionService
};