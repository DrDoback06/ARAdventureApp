import * as admin from 'firebase-admin';
import { v4 as uuidv4 } from 'uuid';
import { BattleResult, PlayerStats, QuestCompletion, AchievementUnlock, GameState } from '../types/gameTypes';

const firestore = admin.firestore();

export interface BattleState {
  battleId: string;
  players: string[];
  currentTurn: string;
  gameState: GameState;
  startedAt: admin.firestore.Timestamp;
  lastAction: admin.firestore.Timestamp;
  isActive: boolean;
  battleType: 'pvp' | 'guild_raid' | 'tournament' | 'cooperative';
  weatherEffects?: any;
  environmentalBonuses?: Record<string, number>;
}

export interface BattleSyncData {
  gameState: GameState;
  actionType: string;
  timestamp: admin.firestore.FieldValue;
  metadata?: Record<string, any>;
}

export interface ProcessedBattleResult {
  battleId: string;
  winner: string;
  finalStats: Record<string, PlayerStats>;
  rewards: Record<string, any>;
  ratingChanges: Record<string, number>;
  achievements?: AchievementUnlock[];
  experienceGained: Record<string, number>;
  rating: number;
}

export interface QuestResult {
  questId: string;
  completed: boolean;
  rewards: any[];
  experienceGained: number;
  triggeredAchievements?: AchievementUnlock[];
  nextObjectives?: string[];
}

export class MultiplayerService {
  /**
   * Initialize real-time battle listeners for synchronization
   */
  static async initializeBattleListeners(battleId: string, battleData: any): Promise<void> {
    try {
      const battleRef = firestore.collection('battles').doc(battleId);
      
      // Set up battle state tracking
      await battleRef.set({
        ...battleData,
        isActive: true,
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
        listeners: battleData.players || [],
        syncHistory: [],
        actionQueue: []
      }, { merge: true });

      // Initialize player readiness tracking
      const readinessPromises = battleData.players?.map((playerId: string) => 
        battleRef.collection('playerStates').doc(playerId).set({
          isReady: false,
          isConnected: true,
          lastHeartbeat: admin.firestore.FieldValue.serverTimestamp(),
          gameState: null
        })
      ) || [];

      await Promise.all(readinessPromises);

      console.log(`Battle listeners initialized for battle ${battleId}`);
    } catch (error) {
      console.error(`Error initializing battle listeners for ${battleId}:`, error);
      throw error;
    }
  }

  /**
   * Synchronize battle state in real-time
   */
  static async syncBattleState(
    battleId: string, 
    userId: string, 
    syncData: BattleSyncData
  ): Promise<{ success: boolean; currentState?: any; conflicts?: string[] }> {
    try {
      const battleRef = firestore.collection('battles').doc(battleId);
      const playerStateRef = battleRef.collection('playerStates').doc(userId);

      // Validate user is part of this battle
      const battleDoc = await battleRef.get();
      if (!battleDoc.exists) {
        throw new Error('Battle not found');
      }

      const battleData = battleDoc.data() as BattleState;
      if (!battleData.players.includes(userId)) {
        throw new Error('User not authorized for this battle');
      }

      // Check for state conflicts
      const conflicts: string[] = [];
      if (battleData.currentTurn && battleData.currentTurn !== userId) {
        conflicts.push('not_your_turn');
      }

      // Update player state
      await playerStateRef.update({
        gameState: syncData.gameState,
        lastAction: syncData.timestamp,
        actionType: syncData.actionType,
        lastHeartbeat: admin.firestore.FieldValue.serverTimestamp()
      });

      // Add to action queue for processing
      await battleRef.collection('actionQueue').add({
        playerId: userId,
        actionType: syncData.actionType,
        gameState: syncData.gameState,
        timestamp: syncData.timestamp,
        processed: false
      });

      // Update battle's last activity
      await battleRef.update({
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
        [`lastActions.${userId}`]: {
          actionType: syncData.actionType,
          timestamp: syncData.timestamp
        }
      });

      // Process turn-based logic if applicable
      if (battleData.battleType === 'pvp' || battleData.battleType === 'tournament') {
        await this.processTurnBasedAction(battleId, userId, syncData);
      }

      // Get current synchronized state
      const updatedBattle = await battleRef.get();
      const currentState = updatedBattle.data();

      return {
        success: true,
        currentState,
        conflicts: conflicts.length > 0 ? conflicts : undefined
      };

    } catch (error) {
      console.error(`Error syncing battle state for ${battleId}:`, error);
      return { 
        success: false, 
        conflicts: ['sync_error'] 
      };
    }
  }

  /**
   * Process turn-based battle actions
   */
  private static async processTurnBasedAction(
    battleId: string, 
    userId: string, 
    syncData: BattleSyncData
  ): Promise<void> {
    const battleRef = firestore.collection('battles').doc(battleId);
    
    await firestore.runTransaction(async (transaction) => {
      const battleDoc = await transaction.get(battleRef);
      const battleData = battleDoc.data() as BattleState;

      // Validate turn
      if (battleData.currentTurn !== userId) {
        throw new Error('Not player\'s turn');
      }

      // Process the action based on type
      let nextTurn = userId;
      let gameStateUpdate: any = {};

      switch (syncData.actionType) {
        case 'attack':
          gameStateUpdate = await this.processAttackAction(battleData, userId, syncData);
          nextTurn = this.getNextPlayer(battleData, userId);
          break;
        
        case 'defend':
          gameStateUpdate = await this.processDefendAction(battleData, userId, syncData);
          nextTurn = this.getNextPlayer(battleData, userId);
          break;
        
        case 'use_ability':
          gameStateUpdate = await this.processAbilityAction(battleData, userId, syncData);
          nextTurn = this.getNextPlayer(battleData, userId);
          break;
        
        case 'end_turn':
          nextTurn = this.getNextPlayer(battleData, userId);
          break;
      }

      // Update battle state
      transaction.update(battleRef, {
        currentTurn: nextTurn,
        gameState: { ...battleData.gameState, ...gameStateUpdate },
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
        turnCount: admin.firestore.FieldValue.increment(1)
      });
    });
  }

  /**
   * Process battle result and update all related systems
   */
  static async processBattleResult(
    battleId: string, 
    userId: string, 
    battleResult: BattleResult
  ): Promise<ProcessedBattleResult> {
    try {
      const battleRef = firestore.collection('battles').doc(battleId);
      const battleDoc = await battleRef.get();
      
      if (!battleDoc.exists) {
        throw new Error('Battle not found');
      }

      const battleData = battleDoc.data() as BattleState;
      
      // Calculate results for all players
      const processedResult: ProcessedBattleResult = {
        battleId,
        winner: battleResult.winnerId,
        finalStats: {},
        rewards: {},
        ratingChanges: {},
        experienceGained: {},
        rating: 0
      };

      // Process each player's results
      for (const playerId of battleData.players) {
        const playerResult = await this.calculatePlayerBattleResult(
          playerId, 
          battleResult, 
          battleData
        );
        
        processedResult.finalStats[playerId] = playerResult.stats;
        processedResult.rewards[playerId] = playerResult.rewards;
        processedResult.ratingChanges[playerId] = playerResult.ratingChange;
        processedResult.experienceGained[playerId] = playerResult.experience;

        // Update player profile
        await this.updatePlayerProfile(playerId, playerResult);
      }

      // Set rating for the requesting user
      processedResult.rating = processedResult.ratingChanges[userId] || 0;

      // Check for achievements
      const achievements = await this.checkBattleAchievements(userId, battleResult, battleData);
      if (achievements.length > 0) {
        processedResult.achievements = achievements;
      }

      // Mark battle as completed
      await battleRef.update({
        isActive: false,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        finalResult: processedResult,
        status: 'completed'
      });

      // Clean up battle listeners
      await this.cleanupBattleListeners(battleId);

      console.log(`Battle ${battleId} processed successfully`);
      return processedResult;

    } catch (error) {
      console.error(`Error processing battle result for ${battleId}:`, error);
      throw error;
    }
  }

  /**
   * Process quest completion with multiplayer validation
   */
  static async processQuestCompletion(
    userId: string, 
    completion: QuestCompletion
  ): Promise<QuestResult> {
    try {
      const questRef = firestore.collection('quests').doc(completion.questId);
      const userRef = firestore.collection('users').doc(userId);

      const result: QuestResult = {
        questId: completion.questId,
        completed: false,
        rewards: [],
        experienceGained: 0
      };

      await firestore.runTransaction(async (transaction) => {
        const questDoc = await transaction.get(questRef);
        const userDoc = await transaction.get(userRef);

        if (!questDoc.exists || !userDoc.exists) {
          throw new Error('Quest or user not found');
        }

        const questData = questDoc.data();
        const userData = userDoc.data();

        // Validate quest completion requirements
        const isValid = await this.validateQuestCompletion(userId, completion, questData);
        if (!isValid) {
          throw new Error('Quest completion validation failed');
        }

        // Calculate rewards based on completion quality
        const rewards = this.calculateQuestRewards(completion, questData);
        const experience = this.calculateQuestExperience(completion, questData);

        // Update user progress
        const updatedProgress = { ...userData.questProgress };
        updatedProgress[completion.questId] = {
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          score: completion.completionScore || 100,
          objectives: completion.completedObjectives
        };

        transaction.update(userRef, {
          questProgress: updatedProgress,
          totalXP: admin.firestore.FieldValue.increment(experience),
          questsCompleted: admin.firestore.FieldValue.increment(1),
          lastQuestCompletion: admin.firestore.FieldValue.serverTimestamp()
        });

        // Check for triggered achievements
        const achievements = await this.checkQuestAchievements(userId, completion, userData);
        
        result.completed = true;
        result.rewards = rewards;
        result.experienceGained = experience;
        result.triggeredAchievements = achievements;

        // Set next objectives if this is part of a quest chain
        if (questData.nextQuestId) {
          result.nextObjectives = [questData.nextQuestId];
        }
      });

      console.log(`Quest ${completion.questId} completed by user ${userId}`);
      return result;

    } catch (error) {
      console.error(`Error processing quest completion:`, error);
      throw error;
    }
  }

  /**
   * Process achievement unlock with social integration
   */
  static async processAchievementUnlock(
    userId: string, 
    achievement: AchievementUnlock
  ): Promise<{ success: boolean; socialShares?: number; rewards?: any[] }> {
    try {
      const userRef = firestore.collection('users').doc(userId);
      const achievementRef = firestore.collection('achievements').doc(achievement.id);

      const result = {
        success: false,
        socialShares: 0,
        rewards: []
      };

      await firestore.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        const achievementDoc = await transaction.get(achievementRef);

        if (!userDoc.exists) {
          throw new Error('User not found');
        }

        const userData = userDoc.data();
        const achievementData = achievementDoc.exists ? achievementDoc.data() : null;

        // Check if already unlocked
        const userAchievements = userData.achievements || [];
        if (userAchievements.some((a: any) => a.id === achievement.id)) {
          throw new Error('Achievement already unlocked');
        }

        // Add achievement to user profile
        const newAchievement = {
          ...achievement,
          unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
          progress: 100
        };

        transaction.update(userRef, {
          achievements: admin.firestore.FieldValue.arrayUnion(newAchievement),
          achievementPoints: admin.firestore.FieldValue.increment(achievement.points || 10),
          lastAchievement: newAchievement
        });

        // Calculate rewards
        if (achievementData?.rewards) {
          result.rewards = achievementData.rewards;
        }

        // Share with friends if public achievement
        if (achievement.isPublic !== false) {
          await this.shareAchievementWithFriends(userId, achievement);
          result.socialShares = userData.friends?.length || 0;
        }

        result.success = true;
      });

      console.log(`Achievement ${achievement.id} unlocked for user ${userId}`);
      return result;

    } catch (error) {
      console.error(`Error processing achievement unlock:`, error);
      throw error;
    }
  }

  /**
   * Calculate player-specific battle results
   */
  private static async calculatePlayerBattleResult(
    playerId: string, 
    battleResult: BattleResult, 
    battleData: BattleState
  ): Promise<{
    stats: PlayerStats;
    rewards: any[];
    ratingChange: number;
    experience: number;
  }> {
    const isWinner = battleResult.winnerId === playerId;
    const playerStats = battleResult.playerStats[playerId] || {};

    // Calculate rating change using ELO-like system
    const ratingChange = this.calculateRatingChange(playerId, isWinner, battleData);

    // Calculate experience based on performance
    const experience = this.calculateBattleExperience(playerStats, isWinner, battleData);

    // Calculate rewards
    const rewards = this.calculateBattleRewards(playerId, isWinner, battleData, playerStats);

    return {
      stats: playerStats,
      rewards,
      ratingChange,
      experience
    };
  }

  /**
   * Update player profile with battle results
   */
  private static async updatePlayerProfile(
    playerId: string, 
    battleResult: any
  ): Promise<void> {
    const userRef = firestore.collection('users').doc(playerId);
    
    await userRef.update({
      totalXP: admin.firestore.FieldValue.increment(battleResult.experience),
      battleRating: admin.firestore.FieldValue.increment(battleResult.ratingChange),
      battlesPlayed: admin.firestore.FieldValue.increment(1),
      lastBattle: admin.firestore.FieldValue.serverTimestamp(),
      ...(battleResult.ratingChange > 0 && { 
        battlesWon: admin.firestore.FieldValue.increment(1) 
      })
    });
  }

  /**
   * Calculate rating change using ELO system
   */
  private static calculateRatingChange(
    playerId: string, 
    isWinner: boolean, 
    battleData: BattleState
  ): number {
    // Simplified ELO calculation
    const baseChange = 30;
    const multiplier = isWinner ? 1 : -0.5;
    
    // Adjust based on battle type
    let typeMultiplier = 1;
    switch (battleData.battleType) {
      case 'tournament':
        typeMultiplier = 1.5;
        break;
      case 'guild_raid':
        typeMultiplier = 1.2;
        break;
      case 'pvp':
        typeMultiplier = 1.0;
        break;
      case 'cooperative':
        typeMultiplier = 0.8;
        break;
    }

    return Math.round(baseChange * multiplier * typeMultiplier);
  }

  /**
   * Calculate battle experience
   */
  private static calculateBattleExperience(
    playerStats: PlayerStats, 
    isWinner: boolean, 
    battleData: BattleState
  ): number {
    let baseXP = 100;
    
    // Bonus for winning
    if (isWinner) {
      baseXP += 50;
    }

    // Performance bonuses
    if (playerStats.damageDealt) {
      baseXP += Math.floor(playerStats.damageDealt / 10);
    }
    
    if (playerStats.actionsPerformed) {
      baseXP += playerStats.actionsPerformed * 5;
    }

    // Battle type multipliers
    switch (battleData.battleType) {
      case 'tournament':
        baseXP *= 2;
        break;
      case 'guild_raid':
        baseXP *= 1.5;
        break;
      case 'cooperative':
        baseXP *= 1.3;
        break;
    }

    return Math.round(baseXP);
  }

  /**
   * Calculate battle rewards
   */
  private static calculateBattleRewards(
    playerId: string, 
    isWinner: boolean, 
    battleData: BattleState,
    playerStats: PlayerStats
  ): any[] {
    const rewards = [];

    // Basic participation rewards
    rewards.push({
      type: 'currency',
      amount: isWinner ? 100 : 50,
      currency: 'gold'
    });

    // Winner bonuses
    if (isWinner) {
      rewards.push({
        type: 'card_pack',
        rarity: 'common',
        count: 1
      });

      // Rare rewards for tournament wins
      if (battleData.battleType === 'tournament') {
        rewards.push({
          type: 'card_pack',
          rarity: 'rare',
          count: 1
        });
      }
    }

    // Performance-based rewards
    if (playerStats.damageDealt && playerStats.damageDealt > 500) {
      rewards.push({
        type: 'achievement_progress',
        achievementId: 'high_damage_dealer',
        progress: 1
      });
    }

    return rewards;
  }

  /**
   * Check for battle-specific achievements
   */
  private static async checkBattleAchievements(
    userId: string, 
    battleResult: BattleResult, 
    battleData: BattleState
  ): Promise<AchievementUnlock[]> {
    const achievements: AchievementUnlock[] = [];
    const userStats = battleResult.playerStats[userId];
    const isWinner = battleResult.winnerId === userId;

    // Perfect victory (no damage taken)
    if (isWinner && userStats?.damageTaken === 0) {
      achievements.push({
        id: 'perfect_victory',
        name: 'Perfect Victory',
        description: 'Win a battle without taking damage',
        rarity: 'rare',
        points: 25
      });
    }

    // High damage achievement
    if (userStats?.damageDealt && userStats.damageDealt > 1000) {
      achievements.push({
        id: 'devastator',
        name: 'Devastator',
        description: 'Deal over 1000 damage in a single battle',
        rarity: 'epic',
        points: 30
      });
    }

    // Tournament winner
    if (isWinner && battleData.battleType === 'tournament') {
      achievements.push({
        id: 'tournament_champion',
        name: 'Tournament Champion',
        description: 'Win a tournament battle',
        rarity: 'legendary',
        points: 50
      });
    }

    return achievements;
  }

  /**
   * Check for quest-specific achievements
   */
  private static async checkQuestAchievements(
    userId: string, 
    completion: QuestCompletion, 
    userData: any
  ): Promise<AchievementUnlock[]> {
    const achievements: AchievementUnlock[] = [];
    const questsCompleted = (userData.questsCompleted || 0) + 1;

    // Quest completion milestones
    if (questsCompleted === 10) {
      achievements.push({
        id: 'quest_novice',
        name: 'Quest Novice',
        description: 'Complete 10 quests',
        rarity: 'common',
        points: 15
      });
    } else if (questsCompleted === 50) {
      achievements.push({
        id: 'quest_veteran',
        name: 'Quest Veteran',
        description: 'Complete 50 quests',
        rarity: 'rare',
        points: 30
      });
    } else if (questsCompleted === 100) {
      achievements.push({
        id: 'quest_master',
        name: 'Quest Master',
        description: 'Complete 100 quests',
        rarity: 'epic',
        points: 50
      });
    }

    // Perfect completion
    if (completion.completionScore && completion.completionScore >= 100) {
      achievements.push({
        id: 'perfectionist',
        name: 'Perfectionist',
        description: 'Complete a quest with perfect score',
        rarity: 'rare',
        points: 20
      });
    }

    return achievements;
  }

  /**
   * Share achievement with friends
   */
  private static async shareAchievementWithFriends(
    userId: string, 
    achievement: AchievementUnlock
  ): Promise<void> {
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (userData?.friends) {
      const sharePromises = userData.friends.map((friendId: string) =>
        firestore.collection('users').doc(friendId).collection('socialFeed').add({
          type: 'achievement_unlock',
          fromUserId: userId,
          fromUserName: userData.displayName || 'Friend',
          achievement,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        })
      );

      await Promise.all(sharePromises);
    }
  }

  /**
   * Validate quest completion
   */
  private static async validateQuestCompletion(
    userId: string, 
    completion: QuestCompletion, 
    questData: any
  ): Promise<boolean> {
    // Basic validation
    if (!completion.completedObjectives || completion.completedObjectives.length === 0) {
      return false;
    }

    // Check if all required objectives are completed
    const requiredObjectives = questData.objectives?.filter((obj: any) => obj.required) || [];
    const completedRequired = completion.completedObjectives.filter(objId => 
      requiredObjectives.some((req: any) => req.id === objId)
    );

    return completedRequired.length >= requiredObjectives.length;
  }

  /**
   * Calculate quest rewards
   */
  private static calculateQuestRewards(completion: QuestCompletion, questData: any): any[] {
    const baseRewards = questData.rewards || [];
    const bonusMultiplier = (completion.completionScore || 100) / 100;

    return baseRewards.map((reward: any) => ({
      ...reward,
      amount: Math.round(reward.amount * bonusMultiplier)
    }));
  }

  /**
   * Calculate quest experience
   */
  private static calculateQuestExperience(completion: QuestCompletion, questData: any): number {
    const baseXP = questData.experienceReward || 100;
    const bonusMultiplier = (completion.completionScore || 100) / 100;
    const difficultyMultiplier = questData.difficulty === 'hard' ? 1.5 : 
                               questData.difficulty === 'medium' ? 1.2 : 1.0;

    return Math.round(baseXP * bonusMultiplier * difficultyMultiplier);
  }

  /**
   * Process attack action in turn-based combat
   */
  private static async processAttackAction(
    battleData: BattleState, 
    userId: string, 
    syncData: BattleSyncData
  ): Promise<any> {
    const attackData = syncData.metadata?.attackData;
    if (!attackData) return {};

    // Calculate damage with weather and environmental effects
    let damage = attackData.baseDamage || 0;
    
    // Apply weather bonuses
    if (battleData.weatherEffects) {
      damage *= (battleData.weatherEffects.damageMultiplier || 1);
    }

    // Apply environmental bonuses
    if (battleData.environmentalBonuses) {
      damage += (battleData.environmentalBonuses[userId] || 0);
    }

    return {
      lastAttack: {
        attacker: userId,
        damage: Math.round(damage),
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      }
    };
  }

  /**
   * Process defend action in turn-based combat
   */
  private static async processDefendAction(
    battleData: BattleState, 
    userId: string, 
    syncData: BattleSyncData
  ): Promise<any> {
    return {
      defenseActions: {
        [userId]: {
          isDefending: true,
          defenseBonus: 0.5,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        }
      }
    };
  }

  /**
   * Process ability action in turn-based combat
   */
  private static async processAbilityAction(
    battleData: BattleState, 
    userId: string, 
    syncData: BattleSyncData
  ): Promise<any> {
    const abilityData = syncData.metadata?.abilityData;
    if (!abilityData) return {};

    return {
      lastAbility: {
        user: userId,
        abilityId: abilityData.id,
        effects: abilityData.effects,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      }
    };
  }

  /**
   * Get next player in turn order
   */
  private static getNextPlayer(battleData: BattleState, currentPlayer: string): string {
    const players = battleData.players;
    const currentIndex = players.indexOf(currentPlayer);
    const nextIndex = (currentIndex + 1) % players.length;
    return players[nextIndex];
  }

  /**
   * Clean up battle listeners and temporary data
   */
  private static async cleanupBattleListeners(battleId: string): Promise<void> {
    try {
      const battleRef = firestore.collection('battles').doc(battleId);
      
      // Archive player states
      const playerStatesSnapshot = await battleRef.collection('playerStates').get();
      const archivePromises = playerStatesSnapshot.docs.map(doc => 
        battleRef.collection('archivedPlayerStates').doc(doc.id).set(doc.data())
      );
      
      await Promise.all(archivePromises);
      
      // Delete active player states
      const deletePromises = playerStatesSnapshot.docs.map(doc => doc.ref.delete());
      await Promise.all(deletePromises);
      
      // Clean up action queue
      const actionQueueSnapshot = await battleRef.collection('actionQueue').get();
      const actionDeletePromises = actionQueueSnapshot.docs.map(doc => doc.ref.delete());
      await Promise.all(actionDeletePromises);

      console.log(`Battle listeners cleaned up for battle ${battleId}`);
    } catch (error) {
      console.error(`Error cleaning up battle listeners for ${battleId}:`, error);
    }
  }

  /**
   * Clean up old battle data (called by scheduled function)
   */
  static async cleanupOldBattles(): Promise<void> {
    try {
      const oneWeekAgo = new Date();
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

      const oldBattlesQuery = firestore
        .collection('battles')
        .where('completedAt', '<', admin.firestore.Timestamp.fromDate(oneWeekAgo))
        .limit(100);

      const oldBattlesSnapshot = await oldBattlesQuery.get();
      
      const deletePromises = oldBattlesSnapshot.docs.map(async (doc) => {
        // Archive to cold storage before deletion
        await firestore.collection('battleArchive').doc(doc.id).set({
          ...doc.data(),
          archivedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        return doc.ref.delete();
      });

      await Promise.all(deletePromises);
      
      console.log(`Cleaned up ${oldBattlesSnapshot.size} old battles`);
    } catch (error) {
      console.error('Error cleaning up old battles:', error);
    }
  }
}