import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/social_service.dart';
import '../services/audio_service.dart';

class SocialFeaturesWidget extends StatefulWidget {
  const SocialFeaturesWidget({super.key});

  @override
  State<SocialFeaturesWidget> createState() => _SocialFeaturesWidgetState();
}

class _SocialFeaturesWidgetState extends State<SocialFeaturesWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Social Features'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Guilds'),
            Tab(text: 'Trading'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildGuildsTab(),
          _buildTradingTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<SocialService>(
      builder: (context, socialService, child) {
        final friends = socialService.getFriends();
        final rivals = socialService.getRivals();
        final stats = socialService.getSocialStatistics();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social Network',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSocialStats(stats),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildRelationshipSection('Friends', friends, Colors.green),
                    const SizedBox(height: 16),
                    _buildRelationshipSection('Rivals', rivals, Colors.red),
                    const SizedBox(height: 16),
                    _buildAddFriendSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuildsTab() {
    return Consumer<SocialService>(
      builder: (context, socialService, child) {
        final currentGuild = socialService.getCurrentGuild();
        final guilds = socialService.guilds;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guild System',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (currentGuild != null) ...[
                _buildCurrentGuildCard(currentGuild),
                const SizedBox(height: 16),
              ] else ...[
                _buildNoGuildCard(),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Available Guilds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...guilds.map((guild) => _buildGuildCard(guild, currentGuild?.id == guild.id)),
                    const SizedBox(height: 16),
                    _buildCreateGuildSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradingTab() {
    return Consumer<SocialService>(
      builder: (context, socialService, child) {
        final pendingOffers = socialService.getPendingTradeOffers();
        final sentOffers = socialService.getSentTradeOffers();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trading System',
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
                    if (pendingOffers.isNotEmpty) ...[
                      Text(
                        'Pending Offers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...pendingOffers.map((offer) => _buildTradeOfferCard(offer, true)),
                      const SizedBox(height: 16),
                    ],
                    if (sentOffers.isNotEmpty) ...[
                      Text(
                        'Sent Offers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...sentOffers.map((offer) => _buildTradeOfferCard(offer, false)),
                      const SizedBox(height: 16),
                    ],
                    _buildCreateTradeSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return Consumer<SocialService>(
      builder: (context, socialService, child) {
        final guildEvents = socialService.getCurrentGuildEvents();
        final allEvents = socialService.guildEvents;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guild Events',
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
                    if (guildEvents.isNotEmpty) ...[
                      Text(
                        'Your Guild Events',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: RealmOfValorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...guildEvents.map((event) => _buildGuildEventCard(event, true)),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'All Guild Events',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...allEvents.map((event) => _buildGuildEventCard(event, false)),
                    const SizedBox(height: 16),
                    _buildCreateEventSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildStatItem('Friends', '${stats['friendsCount']}', Icons.people, Colors.green),
          const SizedBox(width: 16),
          _buildStatItem('Rivals', '${stats['rivalsCount']}', Icons.sports_esports, Colors.red),
          const SizedBox(width: 16),
          _buildStatItem('Guild', stats['guildMembership'] ? 'Yes' : 'No', Icons.group, Colors.blue),
          const SizedBox(width: 16),
          _buildStatItem('Trades', '${stats['pendingTrades']}', Icons.swap_horiz, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipSection(String title, List<dynamic> relationships, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          if (relationships.isEmpty)
            Text(
              'No $title yet',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary,
              ),
            )
          else
            ...relationships.map((rel) => _buildRelationshipCard(rel, color)),
        ],
      ),
    );
  }

  Widget _buildRelationshipCard(dynamic relationship, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.person, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relationship.friendId,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
                Text(
                  'Interactions: ${relationship.interactionCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              AudioService.instance.playSound(AudioType.buttonClick);
              // Remove relationship logic
            },
            icon: Icon(Icons.remove_circle, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendSection() {
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
          Text(
            'Add Friend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter player ID',
                    hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  AudioService.instance.playSound(AudioType.buttonClick);
                  // Add friend logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RealmOfValorTheme.accentGold,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGuildCard(Guild guild) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: RealmOfValorTheme.accentGold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  guild.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.accentGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level ${guild.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            guild.description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Members: ${guild.members.length}',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'XP: ${guild.experience}',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoGuildCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.textSecondary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_outlined,
            size: 48,
            color: RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Not in a Guild',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join or create a guild to participate in guild activities',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildCard(Guild guild, bool isCurrentGuild) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentGuild 
              ? RealmOfValorTheme.accentGold 
              : RealmOfValorTheme.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  guild.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ),
              if (isCurrentGuild)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RealmOfValorTheme.accentGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            guild.description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Level ${guild.level}',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${guild.members.length} members',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isCurrentGuild)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playSound(AudioType.buttonClick);
                      // Join guild logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RealmOfValorTheme.accentGold,
                    ),
                    child: const Text('Join Guild'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCreateGuildSection() {
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
          Text(
            'Create Guild',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Guild Name',
              hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Guild Description',
              hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              AudioService.instance.playSound(AudioType.buttonClick);
              // Create guild logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
            ),
            child: const Text('Create Guild'),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeOfferCard(TradeOffer offer, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending 
              ? Colors.orange 
              : RealmOfValorTheme.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: isPending ? Colors.orange : RealmOfValorTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Trade Offer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTradeStatusColor(offer.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  offer.status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offering:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text('${offer.offeredItems.length} items'),
                    Text('${offer.offeredGold} gold'),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: RealmOfValorTheme.textSecondary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Requesting:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text('${offer.requestedItems.length} items'),
                    Text('${offer.requestedGold} gold'),
                  ],
                ),
              ),
            ],
          ),
          if (isPending && offer.status == TradeStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playSound(AudioType.buttonClick);
                      // Accept trade logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playSound(AudioType.buttonClick);
                      // Decline trade logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateTradeSection() {
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
          Text(
            'Create Trade Offer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Player ID to trade with',
              hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Offering gold',
                    hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Requesting gold',
                    hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              AudioService.instance.playSound(AudioType.buttonClick);
              // Create trade logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
            ),
            child: const Text('Create Trade Offer'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildEventCard(dynamic event, bool isCurrentGuild) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentGuild 
              ? RealmOfValorTheme.accentGold 
              : RealmOfValorTheme.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEventTypeIcon(event.type),
                color: _getEventTypeColor(event.type),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: RealmOfValorTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.type.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${event.participants.length} participants',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_formatDateTime(event.startTime)}',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (!event.participants.contains('current_player')) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                AudioService.instance.playSound(AudioType.buttonClick);
                // Join event logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.accentGold,
              ),
              child: const Text('Join Event'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateEventSection() {
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
          Text(
            'Create Guild Event',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Event Title',
              hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Event Description',
              hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              AudioService.instance.playSound(AudioType.buttonClick);
              // Create event logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RealmOfValorTheme.accentGold,
            ),
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  Color _getTradeStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.pending:
        return Colors.orange;
      case TradeStatus.accepted:
        return Colors.green;
      case TradeStatus.declined:
        return Colors.red;
      case TradeStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(GuildEventType type) {
    switch (type) {
      case GuildEventType.battle:
        return Icons.sports_esports;
      case GuildEventType.quest:
        return Icons.assignment;
      case GuildEventType.raid:
        return Icons.group_work;
      case GuildEventType.social:
        return Icons.people;
    }
  }

  Color _getEventTypeColor(GuildEventType type) {
    switch (type) {
      case GuildEventType.battle:
        return Colors.red;
      case GuildEventType.quest:
        return Colors.blue;
      case GuildEventType.raid:
        return Colors.purple;
      case GuildEventType.social:
        return Colors.green;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 