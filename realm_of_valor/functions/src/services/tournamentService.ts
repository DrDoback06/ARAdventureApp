import * as admin from 'firebase-admin';
import { v4 as uuidv4 } from 'uuid';
import { TournamentEntry, TournamentParticipant, TournamentMatch, TournamentBracket } from '../types/competitiveTypes';

const firestore = admin.firestore();

export class TournamentService {
  /**
   * Create a new tournament
   */
  static async createTournament(tournamentData: Partial<TournamentEntry>): Promise<TournamentEntry> {
    try {
      const tournamentId = uuidv4();
      const now = new Date().toISOString();

      const tournament: TournamentEntry = {
        tournamentId,
        name: tournamentData.name || '',
        description: tournamentData.description || '',
        type: tournamentData.type || 'elimination',
        format: tournamentData.format || 'solo',
        maxParticipants: tournamentData.maxParticipants || 64,
        currentParticipants: 0,
        prizes: tournamentData.prizes || [],
        rules: tournamentData.rules || [],
        schedule: {
          registrationStart: tournamentData.schedule?.registrationStart || now,
          registrationEnd: tournamentData.schedule?.registrationEnd || 
            new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          tournamentStart: tournamentData.schedule?.tournamentStart || 
            new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
          estimatedEnd: tournamentData.schedule?.estimatedEnd || 
            new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString(),
          timezone: tournamentData.schedule?.timezone || 'UTC'
        },
        status: 'upcoming',
        visibility: tournamentData.visibility || 'public',
        requirements: tournamentData.requirements || [],
        settings: {
          allowSpectators: true,
          allowReconnects: true,
          maxReconnectTime: 5,
          pauseAllowed: false,
          maxPauseDuration: 2,
          chatEnabled: true,
          ...tournamentData.settings
        },
        createdBy: tournamentData.createdBy || '',
        createdAt: now,
        startTime: tournamentData.schedule?.tournamentStart || 
          new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString()
      };

      await firestore.collection('tournaments').doc(tournamentId).set(tournament);

      console.log(`Tournament ${tournamentId} created successfully`);
      return tournament;

    } catch (error) {
      console.error('Error creating tournament:', error);
      throw error;
    }
  }

  /**
   * Join a tournament
   */
  static async joinTournament(tournamentId: string, userId: string): Promise<{ success: boolean; message?: string }> {
    try {
      const tournamentRef = firestore.collection('tournaments').doc(tournamentId);
      
      return await firestore.runTransaction(async (transaction) => {
        const tournamentDoc = await transaction.get(tournamentRef);
        
        if (!tournamentDoc.exists) {
          throw new Error('Tournament not found');
        }

        const tournament = tournamentDoc.data() as TournamentEntry;

        // Validate tournament status
        if (tournament.status !== 'registration_open' && tournament.status !== 'upcoming') {
          return { success: false, message: 'Registration is not open for this tournament' };
        }

        // Check if tournament is full
        if (tournament.currentParticipants >= tournament.maxParticipants) {
          return { success: false, message: 'Tournament is full' };
        }

        // Check if user is already registered
        const existingParticipant = await this.getParticipant(tournamentId, userId);
        if (existingParticipant) {
          return { success: false, message: 'Already registered for this tournament' };
        }

        // Validate requirements
        const meetsRequirements = await this.validateRequirements(userId, tournament.requirements);
        if (!meetsRequirements) {
          return { success: false, message: 'Does not meet tournament requirements' };
        }

        // Create participant
        const participant: TournamentParticipant = {
          userId,
          displayName: await this.getUserDisplayName(userId),
          registeredAt: new Date().toISOString(),
          status: 'registered',
          wins: 0,
          losses: 0,
          score: 0
        };

        // Add participant to tournament
        await transaction.update(tournamentRef, {
          currentParticipants: admin.firestore.FieldValue.increment(1)
        });

        await transaction.set(
          tournamentRef.collection('participants').doc(userId),
          participant
        );

        console.log(`User ${userId} joined tournament ${tournamentId}`);
        return { success: true };
      });

    } catch (error) {
      console.error('Error joining tournament:', error);
      throw error;
    }
  }

  /**
   * Advance tournament bracket
   */
  static async advanceBracket(
    tournamentId: string, 
    matchId: string, 
    winnerId: string
  ): Promise<{ success: boolean; nextMatch?: string }> {
    try {
      const tournamentRef = firestore.collection('tournaments').doc(tournamentId);
      const matchRef = tournamentRef.collection('matches').doc(matchId);

      return await firestore.runTransaction(async (transaction) => {
        const matchDoc = await transaction.get(matchRef);
        const tournamentDoc = await transaction.get(tournamentRef);

        if (!matchDoc.exists || !tournamentDoc.exists) {
          throw new Error('Match or tournament not found');
        }

        const match = matchDoc.data() as TournamentMatch;
        const tournament = tournamentDoc.data() as TournamentEntry;

        // Validate match status
        if (match.status !== 'in_progress') {
          throw new Error('Match is not in progress');
        }

        // Validate winner is a participant
        const isValidWinner = match.participants.some(p => p.userId === winnerId);
        if (!isValidWinner) {
          throw new Error('Invalid winner - not a match participant');
        }

        // Update match with winner
        transaction.update(matchRef, {
          status: 'completed',
          winner: winnerId,
          endTime: new Date().toISOString()
        });

        // Update participant records
        for (const participant of match.participants) {
          const participantRef = tournamentRef.collection('participants').doc(participant.userId);
          if (participant.userId === winnerId) {
            transaction.update(participantRef, {
              wins: admin.firestore.FieldValue.increment(1),
              score: admin.firestore.FieldValue.increment(3) // 3 points for win
            });
          } else {
            transaction.update(participantRef, {
              losses: admin.firestore.FieldValue.increment(1),
              score: admin.firestore.FieldValue.increment(1) // 1 point for participation
            });
          }
        }

        // Check if this creates a next match
        const nextMatch = await this.createNextMatch(tournament, match, winnerId);
        let nextMatchId: string | undefined;

        if (nextMatch) {
          const nextMatchRef = tournamentRef.collection('matches').doc();
          nextMatchId = nextMatchRef.id;
          transaction.set(nextMatchRef, { ...nextMatch, matchId: nextMatchId });
        }

        // Check if tournament is complete
        await this.checkTournamentCompletion(tournament, transaction, tournamentRef);

        console.log(`Match ${matchId} completed, winner: ${winnerId}`);
        return { success: true, nextMatch: nextMatchId };
      });

    } catch (error) {
      console.error('Error advancing tournament bracket:', error);
      throw error;
    }
  }

  /**
   * Generate tournament bracket
   */
  static async generateBracket(tournamentId: string): Promise<TournamentBracket> {
    try {
      const tournamentRef = firestore.collection('tournaments').doc(tournamentId);
      const tournamentDoc = await tournamentRef.get();
      
      if (!tournamentDoc.exists) {
        throw new Error('Tournament not found');
      }

      const tournament = tournamentDoc.data() as TournamentEntry;
      
      // Get all participants
      const participantsSnapshot = await tournamentRef.collection('participants').get();
      const participants: TournamentParticipant[] = participantsSnapshot.docs.map(doc => doc.data() as TournamentParticipant);

      // Shuffle participants for random seeding
      const shuffledParticipants = this.shuffleArray([...participants]);

      // Generate bracket based on tournament type
      let bracket: TournamentBracket;

      switch (tournament.type) {
        case 'elimination':
          bracket = this.generateEliminationBracket(shuffledParticipants);
          break;
        case 'round_robin':
          bracket = this.generateRoundRobinBracket(shuffledParticipants);
          break;
        case 'swiss':
          bracket = this.generateSwissBracket(shuffledParticipants);
          break;
        default:
          bracket = this.generateEliminationBracket(shuffledParticipants);
      }

      // Save bracket to tournament
      await tournamentRef.update({
        bracket,
        status: 'in_progress'
      });

      // Create initial matches
      await this.createInitialMatches(tournamentId, bracket);

      console.log(`Bracket generated for tournament ${tournamentId}`);
      return bracket;

    } catch (error) {
      console.error('Error generating bracket:', error);
      throw error;
    }
  }

  /**
   * Archive completed tournaments
   */
  static async archiveCompletedTournaments(): Promise<void> {
    try {
      const oneWeekAgo = new Date();
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

      const completedTournamentsQuery = firestore
        .collection('tournaments')
        .where('status', '==', 'completed')
        .where('endTime', '<', admin.firestore.Timestamp.fromDate(oneWeekAgo))
        .limit(50);

      const snapshot = await completedTournamentsQuery.get();

      const archivePromises = snapshot.docs.map(async (doc) => {
        const tournament = doc.data();
        
        // Archive to cold storage
        await firestore.collection('tournamentArchive').doc(doc.id).set({
          ...tournament,
          archivedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Archive participants and matches
        await this.archiveTournamentData(doc.id);
        
        return doc.ref.delete();
      });

      await Promise.all(archivePromises);
      
      console.log(`Archived ${snapshot.size} completed tournaments`);
    } catch (error) {
      console.error('Error archiving tournaments:', error);
    }
  }

  // ===== PRIVATE HELPER METHODS =====

  private static async getParticipant(tournamentId: string, userId: string): Promise<TournamentParticipant | null> {
    const participantDoc = await firestore
      .collection('tournaments')
      .doc(tournamentId)
      .collection('participants')
      .doc(userId)
      .get();

    return participantDoc.exists ? participantDoc.data() as TournamentParticipant : null;
  }

  private static async getUserDisplayName(userId: string): Promise<string> {
    try {
      const userDoc = await firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data()?.displayName || 'Unknown Player' : 'Unknown Player';
    } catch (error) {
      return 'Unknown Player';
    }
  }

  private static async validateRequirements(userId: string, requirements: any[]): Promise<boolean> {
    // Simplified requirement validation - would implement full logic
    for (const requirement of requirements) {
      switch (requirement.type) {
        case 'level':
          const userLevel = await this.getUserLevel(userId);
          if (!this.compareValues(userLevel, requirement.operator, requirement.value)) {
            return false;
          }
          break;
        case 'rating':
          const userRating = await this.getUserRating(userId);
          if (!this.compareValues(userRating, requirement.operator, requirement.value)) {
            return false;
          }
          break;
        // Add more requirement types as needed
      }
    }
    return true;
  }

  private static async getUserLevel(userId: string): Promise<number> {
    try {
      const userDoc = await firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data()?.level || 1 : 1;
    } catch (error) {
      return 1;
    }
  }

  private static async getUserRating(userId: string): Promise<number> {
    try {
      const userDoc = await firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data()?.battleRating || 1000 : 1000;
    } catch (error) {
      return 1000;
    }
  }

  private static compareValues(actual: number, operator: string, target: number): boolean {
    switch (operator) {
      case 'equal': return actual === target;
      case 'greater': return actual > target;
      case 'less': return actual < target;
      case 'greater_equal': return actual >= target;
      case 'less_equal': return actual <= target;
      case 'not_equal': return actual !== target;
      default: return false;
    }
  }

  private static shuffleArray<T>(array: T[]): T[] {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
  }

  private static generateEliminationBracket(participants: TournamentParticipant[]): TournamentBracket {
    // Simple single elimination bracket generation
    const rounds = Math.ceil(Math.log2(participants.length));
    
    return {
      type: 'single_elimination',
      rounds: [], // Would populate with actual round data
      advancementRules: [{
        fromRound: 1,
        toRound: 2,
        condition: 'win',
        description: 'Winners advance to next round'
      }],
      tiebreakers: [{
        priority: 1,
        type: 'seeding',
        description: 'Higher seed wins ties'
      }]
    };
  }

  private static generateRoundRobinBracket(participants: TournamentParticipant[]): TournamentBracket {
    // Round robin where everyone plays everyone
    return {
      type: 'round_robin',
      rounds: [], // Would populate with actual round data
      advancementRules: [{
        fromRound: 1,
        toRound: 1,
        condition: 'points',
        description: 'Ranked by total points'
      }],
      tiebreakers: [{
        priority: 1,
        type: 'head_to_head',
        description: 'Head-to-head record breaks ties'
      }]
    };
  }

  private static generateSwissBracket(participants: TournamentParticipant[]): TournamentBracket {
    // Swiss system pairing
    return {
      type: 'swiss',
      rounds: [], // Would populate with actual round data
      advancementRules: [{
        fromRound: 1,
        toRound: 2,
        condition: 'points',
        description: 'Paired by current score'
      }],
      tiebreakers: [{
        priority: 1,
        type: 'points',
        description: 'Higher points ranked first'
      }]
    };
  }

  private static async createInitialMatches(tournamentId: string, bracket: TournamentBracket): Promise<void> {
    // Would create the initial round matches based on bracket
    console.log(`Creating initial matches for tournament ${tournamentId}`);
  }

  private static async createNextMatch(
    tournament: TournamentEntry, 
    completedMatch: TournamentMatch, 
    winnerId: string
  ): Promise<TournamentMatch | null> {
    // Logic to determine and create next match in bracket
    // This would depend on the tournament type and bracket structure
    return null; // Simplified for now
  }

  private static async checkTournamentCompletion(
    tournament: TournamentEntry,
    transaction: FirebaseFirestore.Transaction,
    tournamentRef: FirebaseFirestore.DocumentReference
  ): Promise<void> {
    // Check if all matches are complete and determine final standings
    // Update tournament status to 'completed' if done
  }

  private static async archiveTournamentData(tournamentId: string): Promise<void> {
    try {
      const tournamentRef = firestore.collection('tournaments').doc(tournamentId);
      
      // Archive participants
      const participantsSnapshot = await tournamentRef.collection('participants').get();
      const participantPromises = participantsSnapshot.docs.map(doc => 
        firestore.collection('tournamentArchive').doc(tournamentId)
          .collection('participants').doc(doc.id).set(doc.data())
      );

      // Archive matches
      const matchesSnapshot = await tournamentRef.collection('matches').get();
      const matchPromises = matchesSnapshot.docs.map(doc => 
        firestore.collection('tournamentArchive').doc(tournamentId)
          .collection('matches').doc(doc.id).set(doc.data())
      );

      await Promise.all([...participantPromises, ...matchPromises]);
      
      // Delete original subcollections
      const deleteParticipantPromises = participantsSnapshot.docs.map(doc => doc.ref.delete());
      const deleteMatchPromises = matchesSnapshot.docs.map(doc => doc.ref.delete());
      
      await Promise.all([...deleteParticipantPromises, ...deleteMatchPromises]);

      console.log(`Archived data for tournament ${tournamentId}`);
    } catch (error) {
      console.error(`Error archiving tournament data for ${tournamentId}:`, error);
    }
  }
}