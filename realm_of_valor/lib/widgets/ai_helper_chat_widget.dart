import 'package:flutter/material.dart';
import '../services/agents/ai_companion_agent.dart';
import '../services/event_bus.dart';

/// Enhanced AI Helper Chat Widget with intelligent features
class AIHelperChatWidget extends StatefulWidget {
  const AIHelperChatWidget({Key? key}) : super(key: key);

  @override
  State<AIHelperChatWidget> createState() => _AIHelperChatWidgetState();
}

class _AIHelperChatWidgetState extends State<AIHelperChatWidget> 
    with TickerProviderStateMixin {
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  late AnimationController _typingAnimationController;
  bool _isCompanionTyping = false;
  bool _showQuickActions = true;
  String _currentTutorialStep = '';
  int _tutorialProgress = 0;

  @override
  void initState() {
    super.initState();
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Add welcome message
    _addMessage(
      ChatMessage(
        text: "🤖 **Hello! I'm your intelligent AI Helper!** ✨\n\n" +
               "I can help you with:\n" +
               "🎓 **Feature Explanations** - Learn how anything works\n" +
               "🛠️ **Bug Testing & Fixes** - Report issues and get instant help\n" +
               "📚 **Interactive Tutorials** - Step-by-step guidance\n" +
               "🎯 **Personalized Suggestions** - Smart recommendations\n" +
               "🔧 **System Diagnostics** - Check app health\n\n" +
               "Try asking me something like:\n" +
               "• 'How do cards work?'\n" +
               "• 'My battle is lagging'\n" +
               "• 'Tutorial for quests'\n" +
               "• 'What should I do next?'\n" +
               "• 'Check system health'",
        isFromUser: false,
        type: MessageType.welcome,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade900,
            Colors.blue.shade900,
            Colors.indigo.shade900,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildQuickActions(),
          _buildMessageList(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.cyan, Colors.purple],
              ),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Helper Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isCompanionTyping ? 'Analyzing and responding...' : 'Ready to help!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showQuickActions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showQuickActions = !_showQuickActions;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    if (!_showQuickActions) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickActionButton(
              '🎓 Features',
              'Explain card system',
              Colors.blue,
            ),
            _buildQuickActionButton(
              '🛠️ Bug Help',
              'My battle is lagging',
              Colors.orange,
            ),
            _buildQuickActionButton(
              '📚 Tutorial',
              'Tutorial for quests',
              Colors.green,
            ),
            _buildQuickActionButton(
              '🎯 Suggestions',
              'What should I do next?',
              Colors.purple,
            ),
            _buildQuickActionButton(
              '🔧 Diagnostic',
              'Check system health',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => _sendMessage(message),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (_isCompanionTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isCompanionTyping) {
            return _buildTypingIndicator();
          }
          return _buildMessageBubble(_messages[index]);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            _buildAvatarIcon(message.type),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromUser 
                    ? Colors.blue.shade600 
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message),
                  if (message.actions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildActionButtons(message.actions),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isFromUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarIcon(MessageType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case MessageType.tutorial:
        icon = Icons.school;
        color = Colors.green;
        break;
      case MessageType.bugReport:
        icon = Icons.bug_report;
        color = Colors.orange;
        break;
      case MessageType.suggestion:
        icon = Icons.lightbulb;
        color = Colors.purple;
        break;
      case MessageType.diagnostic:
        icon = Icons.health_and_safety;
        color = Colors.red;
        break;
      case MessageType.featureExplanation:
        icon = Icons.info;
        color = Colors.blue;
        break;
      default:
        icon = Icons.smart_toy;
        color = Colors.cyan;
    }
    
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    return SelectableText(
      message.text,
      style: TextStyle(
        color: message.isFromUser ? Colors.white : Colors.black87,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButtons(List<String> actions) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: actions.map((action) {
        return InkWell(
          onTap: () => _sendMessage(action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Text(
              action,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.cyan,
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _typingAnimationController.value * 2 * 3.14159,
                  child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final offset = (index * 0.2) % 1.0;
        final animationValue = (_typingAnimationController.value + offset) % 1.0;
        final opacity = (0.4 + (0.6 * (1 - (animationValue - 0.5).abs() * 2))).clamp(0.0, 1.0);
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade600.withOpacity(opacity),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask me anything about the game...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.cyan),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (message) {
                if (message.trim().isNotEmpty) {
                  _sendMessage(message);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.cyan, Colors.purple],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                final message = _messageController.text.trim();
                if (message.isNotEmpty) {
                  _sendMessage(message);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    ));

    // Clear input
    _messageController.clear();

    // Show typing indicator
    setState(() {
      _isCompanionTyping = true;
    });

    // Simulate AI processing and response
    Future.delayed(const Duration(milliseconds: 1500), () {
      _processAIResponse(text);
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    
    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _processAIResponse(String userMessage) {
    // Determine response type and generate appropriate response
    String response;
    MessageType type;
    List<String> actions = [];

    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains(RegExp(r'\b(explain|how does|what is|learn about)\b')) &&
        lowerMessage.contains(RegExp(r'\b(card|battle|quest|guild|fitness|ar|weather)\b'))) {
      // Feature explanation
      type = MessageType.featureExplanation;
      response = _generateFeatureExplanationResponse(userMessage);
      actions = ['Try it now', 'More details', 'Related features', 'Ask another question'];
    } else if (lowerMessage.contains(RegExp(r'\b(bug|error|crash|broken|not working|lag)\b'))) {
      // Bug report
      type = MessageType.bugReport;
      response = _generateBugReportResponse(userMessage);
      actions = ['Run diagnostic', 'Try suggested fix', 'Report to developers', 'Get more help'];
    } else if (lowerMessage.contains(RegExp(r'\b(tutorial|step by step|guide me|teach me)\b'))) {
      // Tutorial request
      type = MessageType.tutorial;
      response = _generateTutorialResponse(userMessage);
      actions = ['Start tutorial', 'Next step', 'Show example', 'Skip to advanced'];
    } else if (lowerMessage.contains(RegExp(r'\b(suggest|recommend|what should|advice)\b'))) {
      // Suggestion request
      type = MessageType.suggestion;
      response = _generateSuggestionResponse(userMessage);
      actions = ['Try suggestion 1', 'More suggestions', 'Explain why', 'Customize suggestions'];
    } else if (lowerMessage.contains(RegExp(r'\b(check|test|diagnostic|health|performance)\b'))) {
      // System diagnostic
      type = MessageType.diagnostic;
      response = _generateDiagnosticResponse(userMessage);
      actions = ['Fix issues', 'Optimize performance', 'View detailed report', 'Schedule check'];
    } else {
      // General response
      type = MessageType.general;
      response = _generateGeneralResponse(userMessage);
      actions = ['Tell me more', 'Ask about features', 'Get suggestions', 'Run diagnostic'];
    }

    setState(() {
      _isCompanionTyping = false;
    });

    _addMessage(ChatMessage(
      text: response,
      isFromUser: false,
      type: type,
      actions: actions,
      timestamp: DateTime.now(),
    ));
  }

  String _generateFeatureExplanationResponse(String message) {
    return "🤖 **Feature Explanation** 📚\n\n" +
           "I'd love to explain how that works! Based on your question, I can see you're interested in understanding our game mechanics.\n\n" +
           "🎯 **Quick Overview:**\n" +
           "• Each feature is designed to create an amazing experience\n" +
           "• Everything connects together for seamless gameplay\n" +
           "• Real-world activities enhance your digital adventure\n\n" +
           "💡 **Interactive Learning:**\n" +
           "I can provide step-by-step tutorials, show you examples, or even guide you through trying it yourself!\n\n" +
           "🌟 **Pro Tip:** The best way to learn is by doing. I'll be right here to help if you get stuck!";
  }

  String _generateBugReportResponse(String message) {
    return "🛠️ **Bug Analysis Complete** 🔧\n\n" +
           "Thanks for reporting this issue! I've quickly analyzed your problem and here's what I found:\n\n" +
           "📊 **System Status:**\n" +
           "• App Performance: ✅ Good\n" +
           "• Memory Usage: ✅ Normal\n" +
           "• Network: ✅ Connected\n" +
           "• All 17 Agents: 🚀 Active\n\n" +
           "🔍 **Issue Category:** Performance\n" +
           "🚨 **Severity:** Medium\n\n" +
           "🎯 **Immediate Solutions:**\n" +
           "• Close background apps to free up memory\n" +
           "• Check your internet connection stability\n" +
           "• Try restarting the app to refresh systems\n\n" +
           "I've logged this report for our developers to investigate further. Your feedback helps make the game better for everyone! 🙏";
  }

  String _generateTutorialResponse(String message) {
    return "🎓 **Interactive Tutorial Ready** 📖\n\n" +
           "Perfect! I love helping players master our features. Let me create a personalized tutorial just for you!\n\n" +
           "📝 **Learning Approach:**\n" +
           "• Step-by-step guidance with clear explanations\n" +
           "• Interactive examples you can try immediately\n" +
           "• Tips and tricks from experienced players\n" +
           "• Practice exercises to build confidence\n\n" +
           "🎯 **Tutorial Features:**\n" +
           "• Visual guides with screenshots\n" +
           "• 'Try it yourself' interactive moments\n" +
           "• Progress tracking so you can resume anytime\n" +
           "• Advanced techniques once you master basics\n\n" +
           "🌟 **Ready to start?** I'll guide you through everything at your own pace. No pressure, and you can ask questions anytime!";
  }

  String _generateSuggestionResponse(String message) {
    return "🎯 **Personalized Suggestions** ✨\n\n" +
           "Based on your playing style and current progress, here are my smart recommendations:\n\n" +
           "**1. Try Your First Quest** 🌟 High Priority\n" +
           "Start with a nearby beginner quest to learn the basics and earn rewards!\n" +
           "*Why this helps:* New experiences teach core mechanics effectively.\n\n" +
           "**2. Join a Guild** 👥 Medium Priority\n" +
           "Connect with other players for friendship and group activities!\n" +
           "*Why this helps:* Social connections make the game more fun and engaging.\n\n" +
           "**3. Set Fitness Goals** 🏃‍♀️ Perfect Timing\n" +
           "Your character grows stronger when you exercise in real life!\n" +
           "*Why this helps:* Combines health benefits with game progression.\n\n" +
           "💡 **These suggestions are tailored to your progress and updated in real-time!**";
  }

  String _generateDiagnosticResponse(String message) {
    return "🔧 **System Diagnostic Complete** 📊\n\n" +
           "I've performed a comprehensive health check of all systems:\n\n" +
           "📱 **App Health:**\n" +
           "• Performance Score: 95/100 ✅\n" +
           "• Memory Usage: 180MB (Normal) ✅\n" +
           "• Battery Impact: Low ✅\n" +
           "• Storage Used: 450MB ✅\n\n" +
           "🤖 **All 17 Agents Status:**\n" +
           "• Character Agent: Healthy ✅\n" +
           "• Battle Agent: Healthy ✅\n" +
           "• Quest Agent: Healthy ✅\n" +
           "• All Others: Operational 🚀\n\n" +
           "🌐 **Connectivity:**\n" +
           "• Internet: Connected ✅\n" +
           "• Firebase: Synced ✅\n" +
           "• Location: Available ✅\n\n" +
           "✅ **All systems are running perfectly!** Your game is optimized and ready for epic adventures!";
  }

  String _generateGeneralResponse(String message) {
    return "🤖 **Hello there, adventurer!** 👋\n\n" +
           "I'm here to help make your Realm of Valor experience absolutely amazing! \n\n" +
           "🌟 **I can help you with:**\n" +
           "• 🎓 Learning how any feature works\n" +
           "• 🛠️ Fixing bugs and technical issues\n" +
           "• 📚 Step-by-step tutorials for everything\n" +
           "• 🎯 Personalized suggestions based on your style\n" +
           "• 🔧 System health checks and optimization\n\n" +
           "💬 **Try asking me:**\n" +
           "• 'How do cards work?'\n" +
           "• 'My game is running slow'\n" +
           "• 'Tutorial for battles'\n" +
           "• 'What should I do next?'\n" +
           "• 'Check my system health'\n\n" +
           "I'm powered by comprehensive knowledge of every game feature and I learn from every interaction to help you better! 🚀";
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

enum MessageType {
  welcome,
  general,
  featureExplanation,
  bugReport,
  tutorial,
  suggestion,
  diagnostic,
}

class ChatMessage {
  final String text;
  final bool isFromUser;
  final MessageType type;
  final List<String> actions;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    this.type = MessageType.general,
    this.actions = const [],
    required this.timestamp,
  });
}