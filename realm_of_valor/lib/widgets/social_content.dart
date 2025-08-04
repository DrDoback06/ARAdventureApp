import 'package:flutter/material.dart';
import '../constants/theme.dart';

class SocialContent extends StatefulWidget {
  const SocialContent({super.key});

  @override
  State<SocialContent> createState() => _SocialContentState();
}

class _SocialContentState extends State<SocialContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _postController = TextEditingController();
  final List<SocialPost> _posts = [];
  bool _isCreatingPost = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSamplePosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  void _loadSamplePosts() {
    _posts.addAll([
      SocialPost(
        id: '1',
        author: 'DragonSlayer',
        authorLevel: 15,
        content: 'Just completed the Ancient Ruins quest! Found some epic loot! 🗡️⚔️',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 24,
        comments: 8,
        type: PostType.quest,
        questName: 'Ancient Ruins',
        questReward: 'Epic Sword + 500 XP',
        imageUrl: null,
      ),
      SocialPost(
        id: '2',
        author: 'MageMaster',
        authorLevel: 22,
        content: 'Looking for a party to tackle the Dragon\'s Lair raid! Need 2 more players. DM me if interested! 🐉',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        likes: 12,
        comments: 15,
        type: PostType.raidCall,
        questName: 'Dragon\'s Lair Raid',
        questReward: 'Legendary Items + 1000 XP',
        imageUrl: null,
      ),
      SocialPost(
        id: '3',
        author: 'FitnessWarrior',
        authorLevel: 8,
        content: 'Completed my daily fitness challenge! 10km run while hunting monsters. #FitnessGaming 💪',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 31,
        comments: 12,
        type: PostType.fitness,
        questName: 'Daily Fitness Challenge',
        questReward: 'Health Potion + 200 XP',
        imageUrl: null,
      ),
      SocialPost(
        id: '4',
        author: 'GuildLeader',
        authorLevel: 30,
        content: 'Guild meeting tonight at 8 PM! Discussing our strategy for the upcoming world boss event. All members welcome! 🏰',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: 45,
        comments: 23,
        type: PostType.guild,
        questName: 'Guild Meeting',
        questReward: 'Guild Experience + 300 XP',
        imageUrl: null,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building Social Content');
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            border: Border(
              bottom: BorderSide(color: RealmOfValorTheme.primaryLight),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Social Feed',
                style: TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showCreatePostDialog(),
                icon: Icon(
                  Icons.add,
                  color: RealmOfValorTheme.accentGold,
                ),
              ),
            ],
          ),
        ),
        
        // Tab Bar
        Container(
          decoration: const BoxDecoration(
            color: RealmOfValorTheme.surfaceDark,
            border: Border(
              bottom: BorderSide(color: RealmOfValorTheme.primaryLight),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: RealmOfValorTheme.accentGold,
            labelColor: RealmOfValorTheme.accentGold,
            unselectedLabelColor: RealmOfValorTheme.textSecondary,
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Guilds'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFeedTab(),
              _buildGuildsTab(),
              _buildActivityTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildGuildsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGuildCard(
          'Dragon Slayers',
          'Elite guild focused on boss raids and PvP',
          45,
          15,
          true,
        ),
        _buildGuildCard(
          'Mage Circle',
          'Guild for magic users and support players',
          32,
          8,
          false,
        ),
        _buildGuildCard(
          'Fitness Warriors',
          'Guild combining gaming with real fitness',
          28,
          12,
          false,
        ),
        _buildGuildCard(
          'Explorers Guild',
          'Focus on exploration and discovery quests',
          19,
          6,
          false,
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActivityCard(
          'Quest Completed',
          'Ancient Ruins',
          'You earned 500 XP and Epic Sword',
          Icons.emoji_events,
          Colors.amber,
        ),
        _buildActivityCard(
          'Level Up!',
          'Level 15 Reached',
          'New abilities unlocked!',
          Icons.trending_up,
          Colors.green,
        ),
        _buildActivityCard(
          'Achievement Unlocked',
          'First Blood',
          'Defeated your first boss',
          Icons.star,
          Colors.orange,
        ),
        _buildActivityCard(
          'Guild Activity',
          'Dragon Slayers',
          'Guild completed a raid together',
          Icons.group,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildPostCard(SocialPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: RealmOfValorTheme.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: RealmOfValorTheme.accentGold,
                  child: Text(
                    post.author[0].toUpperCase(),
                    style: const TextStyle(
                      color: RealmOfValorTheme.surfaceDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          color: RealmOfValorTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level ${post.authorLevel} • ${_formatTimestamp(post.timestamp)}',
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPostTypeIcon(post.type),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Post Content
            Text(
              post.content,
              style: const TextStyle(
                color: RealmOfValorTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            
            if (post.type != PostType.fitness) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: RealmOfValorTheme.accentGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.questName,
                            style: const TextStyle(
                              color: RealmOfValorTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            post.questReward,
                            style: const TextStyle(
                              color: RealmOfValorTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Post Actions
            Row(
              children: [
                _buildActionButton(
                  Icons.favorite_border,
                  '${post.likes}',
                  () => _likePost(post),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  Icons.comment,
                  '${post.comments}',
                  () => _commentOnPost(post),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  Icons.share,
                  'Share',
                  () => _sharePost(post),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showPostOptions(post),
                  icon: const Icon(
                    Icons.more_vert,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuildCard(String name, String description, int members, int level, bool isMember) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: RealmOfValorTheme.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: RealmOfValorTheme.accentGold,
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: RealmOfValorTheme.surfaceDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: RealmOfValorTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                          color: RealmOfValorTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMember)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Member',
                      style: TextStyle(
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
                Icon(
                  Icons.people,
                  color: RealmOfValorTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$members members',
                  style: const TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.trending_up,
                  color: RealmOfValorTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Level $level',
                  style: const TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _joinGuild(name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RealmOfValorTheme.accentGold,
                      foregroundColor: RealmOfValorTheme.surfaceDark,
                    ),
                    child: Text(isMember ? 'View Guild' : 'Join Guild'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showGuildDetails(name),
                  icon: const Icon(
                    Icons.info_outline,
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(String type, String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: RealmOfValorTheme.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: RealmOfValorTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: RealmOfValorTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '2h ago',
              style: const TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeIcon(PostType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case PostType.quest:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case PostType.raidCall:
        icon = Icons.group;
        color = Colors.blue;
        break;
      case PostType.fitness:
        icon = Icons.fitness_center;
        color = Colors.green;
        break;
      case PostType.guild:
        icon = Icons.castle;
        color = Colors.purple;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: RealmOfValorTheme.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: RealmOfValorTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showCreatePostDialog() {
    setState(() {
      _isCreatingPost = true;
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RealmOfValorTheme.surfaceDark,
        title: const Text(
          'Create Post',
          style: TextStyle(color: RealmOfValorTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _postController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: RealmOfValorTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createPost(PostType.quest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: const Text('Quest'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createPost(PostType.raidCall),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Raid Call'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createPost(PostType.fitness),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Fitness'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createPost(PostType.guild),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Guild'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isCreatingPost = false;
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _createPost(PostType type) {
    if (_postController.text.trim().isEmpty) return;
    
    final newPost = SocialPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: 'YourCharacter',
      authorLevel: 15,
      content: _postController.text.trim(),
      timestamp: DateTime.now(),
      likes: 0,
      comments: 0,
      type: type,
      questName: type == PostType.quest ? 'Your Quest' : '',
      questReward: type == PostType.quest ? 'Rewards' : '',
      imageUrl: null,
    );
    
    setState(() {
      _posts.insert(0, newPost);
      _isCreatingPost = false;
    });
    
    _postController.clear();
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _likePost(SocialPost post) {
    setState(() {
      post.likes++;
    });
  }

  void _commentOnPost(SocialPost post) {
    // TODO: Implement comment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _sharePost(SocialPost post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showPostOptions(SocialPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RealmOfValorTheme.surfaceDark,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: const Text('Report Post'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement report functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.orange),
            title: const Text('Block User'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement block functionality
            },
          ),
        ],
      ),
    );
  }

  void _joinGuild(String guildName) {
    // TODO: Implement guild joining functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining $guildName...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showGuildDetails(String guildName) {
    // TODO: Implement guild details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing details for $guildName'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

enum PostType {
  quest,
  raidCall,
  fitness,
  guild,
}

class SocialPost {
  final String id;
  final String author;
  final int authorLevel;
  final String content;
  final DateTime timestamp;
  int likes;
  int comments;
  final PostType type;
  final String questName;
  final String questReward;
  final String? imageUrl;

  SocialPost({
    required this.id,
    required this.author,
    required this.authorLevel,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.type,
    required this.questName,
    required this.questReward,
    this.imageUrl,
  });
} 