import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../constants/theme.dart';

class RewardsPopupWidget extends StatefulWidget {
  final List<CardInstance> items;
  final int gold;
  final int xp;
  final VoidCallback? onClose;
  final Function(CardInstance)? onItemCollected;
  final Function(CardInstance)? onItemDraggedToInventory;

  const RewardsPopupWidget({
    Key? key,
    required this.items,
    this.gold = 0,
    this.xp = 0,
    this.onClose,
    this.onItemCollected,
    this.onItemDraggedToInventory,
  }) : super(key: key);

  @override
  State<RewardsPopupWidget> createState() => _RewardsPopupWidgetState();
}

class _RewardsPopupWidgetState extends State<RewardsPopupWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final List<CardInstance> _collectedItems = [];
  bool _isCollecting = false;
  CardInstance? _draggedItem;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _collectAllItems() async {
    if (_isCollecting) return;
    
    setState(() {
      _isCollecting = true;
    });

    for (final item in widget.items) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _collectedItems.add(item);
      });
      
      if (widget.onItemCollected != null) {
        widget.onItemCollected!(item);
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  void _onItemDraggedToInventory(CardInstance item) {
    if (widget.onItemDraggedToInventory != null) {
      widget.onItemDraggedToInventory!(item);
    }
    
    setState(() {
      _collectedItems.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: RealmOfValorTheme.surfaceDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RealmOfValorTheme.accentGold.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: RealmOfValorTheme.accentGold,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rewards Collected!',
                          style: TextStyle(
                            color: RealmOfValorTheme.accentGold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: Icon(
                            Icons.close,
                            color: RealmOfValorTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // XP and Gold
                  if (widget.xp > 0 || widget.gold > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (widget.xp > 0)
                            _buildRewardChip(
                              Icons.star,
                              '${widget.xp} XP',
                              Colors.amber,
                            ),
                          if (widget.gold > 0)
                            _buildRewardChip(
                              Icons.monetization_on,
                              '${widget.gold} Gold',
                              Colors.yellow,
                            ),
                        ],
                      ),
                    ),
                  
                  // Items Section
                  if (widget.items.isNotEmpty)
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(
                                  'Items Found',
                                  style: TextStyle(
                                    color: RealmOfValorTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Drag items to inventory',
                                  style: TextStyle(
                                    color: RealmOfValorTheme.textSecondary,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: widget.items.length,
                              itemBuilder: (context, index) {
                                final item = widget.items[index];
                                final isCollected = _collectedItems.contains(item);
                                
                                return _buildDraggableItemCard(item, isCollected);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Collect All Button
                  if (widget.items.isNotEmpty && !_isCollecting)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _collectAllItems,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RealmOfValorTheme.accentGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory),
                              const SizedBox(width: 8),
                              Text(
                                'Collect All Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(CardInstance item, bool isCollected) {
    return Container(
      decoration: BoxDecoration(
        color: isCollected 
            ? RealmOfValorTheme.accentGold.withOpacity(0.3)
            : RealmOfValorTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCollected 
              ? RealmOfValorTheme.accentGold
              : RealmOfValorTheme.accentGold.withOpacity(0.3),
          width: isCollected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getItemIcon(item.card.name),
            color: _getItemColor(item.card.name),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            item.card.name,
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.card.rarity.name.toUpperCase(),
            style: TextStyle(
              color: _getRarityColor(item.card.rarity),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isCollected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'COLLECTED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableItemCard(CardInstance item, bool isCollected) {
    return Draggable<CardInstance>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: RealmOfValorTheme.accentGold.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RealmOfValorTheme.accentGold,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getItemIcon(item.card.name),
                color: _getItemColor(item.card.name),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                item.card.name,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: RealmOfValorTheme.surfaceLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: RealmOfValorTheme.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              color: RealmOfValorTheme.textSecondary.withOpacity(0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Dragging...',
              style: TextStyle(
                color: RealmOfValorTheme.textSecondary.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDragStarted: () {
        setState(() {
          _draggedItem = item;
        });
      },
      onDragEnd: (details) {
        setState(() {
          _draggedItem = null;
        });
      },
      child: _buildItemCard(item, isCollected),
    );
  }

  IconData _getItemIcon(String itemName) {
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains('sword') || lowerName.contains('weapon')) {
      return Icons.gps_fixed;
    } else if (lowerName.contains('armor') || lowerName.contains('shield')) {
      return Icons.shield;
    } else if (lowerName.contains('potion') || lowerName.contains('heal')) {
      return Icons.local_drink;
    } else if (lowerName.contains('scroll') || lowerName.contains('spell')) {
      return Icons.auto_stories;
    } else if (lowerName.contains('treasure') || lowerName.contains('gold')) {
      return Icons.workspace_premium;
    } else if (lowerName.contains('rare')) {
      return Icons.diamond;
    } else {
      return Icons.inventory;
    }
  }

  Color _getItemColor(String itemName) {
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains('rare')) {
      return Colors.purple;
    } else if (lowerName.contains('epic')) {
      return Colors.deepPurple;
    } else if (lowerName.contains('legendary')) {
      return Colors.orange;
    } else if (lowerName.contains('potion')) {
      return Colors.green;
    } else if (lowerName.contains('weapon')) {
      return Colors.red;
    } else if (lowerName.contains('armor')) {
      return Colors.blue;
    } else {
      return RealmOfValorTheme.accentGold;
    }
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.uncommon:
        return Colors.green;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.epic:
        return Colors.purple;
      case CardRarity.legendary:
        return Colors.orange;
      case CardRarity.mythic:
        return Colors.red;
      case CardRarity.holographic:
        return Colors.cyan;
      case CardRarity.firstEdition:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
} 