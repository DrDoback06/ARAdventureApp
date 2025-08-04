import * as admin from 'firebase-admin';
import { LeaderboardEntry, LeaderboardStats } from '../types/gameTypes';

const firestore = admin.firestore();

export class LeaderboardService {
  /**
   * Get global leaderboards with pagination
   */
  static async getGlobalLeaderboards(options: {
    category: string;
    timeframe: string;
    limit: number;
    offset: number;
  }): Promise<{ entries: LeaderboardEntry[]; stats: LeaderboardStats }> {
    try {
      const { category, timeframe, limit, offset } = options;
      
      const leaderboardRef = firestore
        .collection('leaderboards')
        .doc(category)
        .collection(timeframe)
        .orderBy('score', 'desc')
        .limit(limit)
        .offset(offset);

      const snapshot = await leaderboardRef.get();
      const entries: LeaderboardEntry[] = snapshot.docs.map((doc, index) => ({
        ...doc.data() as LeaderboardEntry,
        rank: offset + index + 1
      }));

      // Get stats
      const statsDoc = await firestore
        .collection('leaderboardStats')
        .doc(`${category}_${timeframe}`)
        .get();

      const stats: LeaderboardStats = statsDoc.exists ? 
        statsDoc.data() as LeaderboardStats : 
        {
          totalEntries: 0,
          averageScore: 0,
          topScore: 0,
          lastUpdated: new Date().toISOString()
        };

      return { entries, stats };
    } catch (error) {
      console.error('Error fetching global leaderboards:', error);
      throw error;
    }
  }

  /**
   * Update player ranking
   */
  static async updatePlayerRanking(userId: string, newRating: any): Promise<void> {
    try {
      const userRef = firestore.collection('users').doc(userId);
      const userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const userData = userDoc.data();
      const categories = ['totalXP', 'battleRating', 'questsCompleted', 'achievementPoints'];

      // Update multiple leaderboard categories
      const updatePromises = categories.map(async (category) => {
        const score = userData?.[category] || 0;
        if (score > 0) {
          await this.updateCategoryRanking(userId, category, score, userData?.displayName || 'Unknown');
        }
      });

      await Promise.all(updatePromises);
      console.log(`Updated rankings for user ${userId}`);
    } catch (error) {
      console.error('Error updating player ranking:', error);
      throw error;
    }
  }

  /**
   * Get player rankings across categories
   */
  static async getPlayerRankings(userId: string, categories: string[]): Promise<Record<string, any>> {
    try {
      const rankings: Record<string, any> = {};

      for (const category of categories) {
        const timeframes = ['daily', 'weekly', 'monthly', 'all_time'];
        
        for (const timeframe of timeframes) {
          const entryDoc = await firestore
            .collection('leaderboards')
            .doc(category)
            .collection(timeframe)
            .doc(userId)
            .get();

          if (entryDoc.exists) {
            const entry = entryDoc.data() as LeaderboardEntry;
            rankings[`${category}_${timeframe}`] = {
              rank: entry.rank,
              score: entry.score,
              change: entry.change || 0
            };
          }
        }
      }

      return rankings;
    } catch (error) {
      console.error('Error getting player rankings:', error);
      throw error;
    }
  }

  /**
   * Update tournament rankings
   */
  static async updateTournamentRankings(tournamentId: string): Promise<void> {
    try {
      const tournamentRef = firestore.collection('tournaments').doc(tournamentId);
      const participantsSnapshot = await tournamentRef.collection('participants').get();

      const participants = participantsSnapshot.docs.map(doc => ({
        userId: doc.id,
        ...doc.data()
      }));

      // Sort by score (or wins/losses)
      participants.sort((a, b) => {
        if (a.score !== b.score) return b.score - a.score;
        if (a.wins !== b.wins) return b.wins - a.wins;
        return a.losses - b.losses;
      });

      // Update ranks
      const updatePromises = participants.map((participant, index) => {
        return tournamentRef.collection('participants').doc(participant.userId).update({
          tournamentRank: index + 1
        });
      });

      await Promise.all(updatePromises);
      console.log(`Updated tournament rankings for ${tournamentId}`);
    } catch (error) {
      console.error('Error updating tournament rankings:', error);
      throw error;
    }
  }

  /**
   * Update guild rankings
   */
  static async updateGuildRankings(guildId: string): Promise<void> {
    try {
      const guildRef = firestore.collection('guilds').doc(guildId);
      const guildDoc = await guildRef.get();

      if (!guildDoc.exists) {
        throw new Error('Guild not found');
      }

      const guildData = guildDoc.data();
      const guildStats = guildData?.stats || {};

      // Update guild in various leaderboard categories
      const categories = ['totalExperience', 'weeklyActivity', 'tournamentsWon', 'questsCompleted'];
      
      const updatePromises = categories.map(async (category) => {
        const score = guildStats[category] || 0;
        if (score > 0) {
          await this.updateGuildCategoryRanking(guildId, category, score, guildData?.name || 'Unknown Guild');
        }
      });

      await Promise.all(updatePromises);
      console.log(`Updated guild rankings for ${guildId}`);
    } catch (error) {
      console.error('Error updating guild rankings:', error);
      throw error;
    }
  }

  /**
   * Update achievement progress in leaderboards
   */
  static async updateAchievementProgress(userId: string, achievement: any): Promise<void> {
    try {
      const userRef = firestore.collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const userData = userDoc.data();
      const achievementPoints = userData?.achievementPoints || 0;

      // Update achievement leaderboards
      await this.updateCategoryRanking(
        userId, 
        'achievementPoints', 
        achievementPoints, 
        userData?.displayName || 'Unknown'
      );

      // Update category-specific achievement leaderboards
      if (achievement.category) {
        const categoryKey = `achievements_${achievement.category}`;
        const categoryAchievements = userData?.categoryAchievements?.[achievement.category] || 0;
        
        await this.updateCategoryRanking(
          userId, 
          categoryKey, 
          categoryAchievements, 
          userData?.displayName || 'Unknown'
        );
      }

      console.log(`Updated achievement progress for user ${userId}`);
    } catch (error) {
      console.error('Error updating achievement progress:', error);
      throw error;
    }
  }

  /**
   * Perform daily leaderboard updates
   */
  static async performDailyUpdate(): Promise<void> {
    try {
      console.log('Starting daily leaderboard update...');

      // Reset daily leaderboards
      await this.resetTimeframedLeaderboards('daily');

      // Update weekly and monthly rankings
      await this.updateTimeframedLeaderboards(['weekly', 'monthly']);

      // Calculate and update statistics
      await this.updateLeaderboardStatistics();

      console.log('Daily leaderboard update completed');
    } catch (error) {
      console.error('Error in daily leaderboard update:', error);
      throw error;
    }
  }

  /**
   * Distribute daily rewards
   */
  static async distributeDailyRewards(): Promise<void> {
    try {
      console.log('Starting daily reward distribution...');

      const categories = ['totalXP', 'battleRating', 'questsCompleted'];
      
      for (const category of categories) {
        await this.distributeRewardsForCategory(category, 'daily');
      }

      console.log('Daily reward distribution completed');
    } catch (error) {
      console.error('Error distributing daily rewards:', error);
      throw error;
    }
  }

  // ===== PRIVATE HELPER METHODS =====

  private static async updateCategoryRanking(
    userId: string, 
    category: string, 
    score: number, 
    displayName: string
  ): Promise<void> {
    const timeframes = ['daily', 'weekly', 'monthly', 'all_time'];
    
    const updatePromises = timeframes.map(async (timeframe) => {
      const entryRef = firestore
        .collection('leaderboards')
        .doc(category)
        .collection(timeframe)
        .doc(userId);

      const entry: LeaderboardEntry = {
        userId,
        displayName,
        score,
        rank: 0, // Will be calculated later
        change: 0, // Will be calculated later
        category,
        timeframe: timeframe as any,
        achievedAt: new Date().toISOString()
      };

      await entryRef.set(entry, { merge: true });
    });

    await Promise.all(updatePromises);
  }

  private static async updateGuildCategoryRanking(
    guildId: string, 
    category: string, 
    score: number, 
    guildName: string
  ): Promise<void> {
    const timeframes = ['weekly', 'monthly', 'all_time'];
    
    const updatePromises = timeframes.map(async (timeframe) => {
      const entryRef = firestore
        .collection('guildLeaderboards')
        .doc(category)
        .collection(timeframe)
        .doc(guildId);

      const entry = {
        guildId,
        guildName,
        score,
        rank: 0,
        change: 0,
        category,
        timeframe,
        achievedAt: new Date().toISOString()
      };

      await entryRef.set(entry, { merge: true });
    });

    await Promise.all(updatePromises);
  }

  private static async resetTimeframedLeaderboards(timeframe: string): Promise<void> {
    // Implementation would depend on specific reset logic
    console.log(`Resetting ${timeframe} leaderboards`);
  }

  private static async updateTimeframedLeaderboards(timeframes: string[]): Promise<void> {
    // Implementation would update rankings for specific timeframes
    console.log(`Updating timeframed leaderboards: ${timeframes.join(', ')}`);
  }

  private static async updateLeaderboardStatistics(): Promise<void> {
    // Implementation would calculate and update leaderboard statistics
    console.log('Updating leaderboard statistics');
  }

  private static async distributeRewardsForCategory(category: string, timeframe: string): Promise<void> {
    try {
      const topPlayersSnapshot = await firestore
        .collection('leaderboards')
        .doc(category)
        .collection(timeframe)
        .orderBy('score', 'desc')
        .limit(10)
        .get();

      const rewardPromises = topPlayersSnapshot.docs.map(async (doc, index) => {
        const rank = index + 1;
        const userId = doc.id;
        
        // Calculate rewards based on rank
        const rewards = this.calculateRankRewards(rank);
        
        if (rewards.length > 0) {
          await this.giveRewardsToUser(userId, rewards);
        }
      });

      await Promise.all(rewardPromises);
      console.log(`Distributed rewards for ${category} ${timeframe}`);
    } catch (error) {
      console.error(`Error distributing rewards for ${category} ${timeframe}:`, error);
    }
  }

  private static calculateRankRewards(rank: number): any[] {
    const rewards = [];
    
    if (rank === 1) {
      rewards.push({ type: 'currency', amount: 1000, currency: 'gold' });
      rewards.push({ type: 'title', titleId: 'daily_champion' });
    } else if (rank <= 3) {
      rewards.push({ type: 'currency', amount: 500, currency: 'gold' });
    } else if (rank <= 10) {
      rewards.push({ type: 'currency', amount: 250, currency: 'gold' });
    }

    return rewards;
  }

  private static async giveRewardsToUser(userId: string, rewards: any[]): Promise<void> {
    try {
      const userRef = firestore.collection('users').doc(userId);
      
      const updateData: any = {};
      
      for (const reward of rewards) {
        switch (reward.type) {
          case 'currency':
            updateData[reward.currency] = admin.firestore.FieldValue.increment(reward.amount);
            break;
          case 'title':
            updateData.titles = admin.firestore.FieldValue.arrayUnion(reward.titleId);
            break;
          // Add more reward types as needed
        }
      }

      if (Object.keys(updateData).length > 0) {
        await userRef.update(updateData);
      }

      console.log(`Gave rewards to user ${userId}:`, rewards);
    } catch (error) {
      console.error(`Error giving rewards to user ${userId}:`, error);
    }
  }
}