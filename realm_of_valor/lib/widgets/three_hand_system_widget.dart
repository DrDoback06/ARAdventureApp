import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../models/card_model.dart';
import '../models/character_model.dart';
import '../providers/battle_controller.dart';
import 'hearthstone_card_widget.dart';
import '../constants/theme.dart';

enum HandType {
  actionCards,
  skills,
  inventory,
}

class ThreeHandSystemWidget extends StatefulWidget {
  final BattleController controller;
  final BattlePlayer currentPlayer;
  final bool isCurrentPlayer;

  const ThreeHandSystemWidget({
    super.key,
    required this.controller,
    required this.currentPlayer,
    required this.isCurrentPlayer,
  });

  @override
  State<ThreeHandSystemWidget> createState() => _ThreeHandSystemWidgetState();
}

class _ThreeHandSystemWidgetState extends State<ThreeHandSystemWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  HandType _activeHand = HandType.actionCards;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: RealmOfValorTheme.accentGold, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Hand Type Selector
          _buildHandSelector(),
          
          // Cards Display
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActionCardsHand(),
                _buildSkillsHand(),
                _buildInventoryHand(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          _buildHandTab('Action Cards', HandType.actionCards, Icons.style),
          _buildHandTab('Skills', HandType.skills, Icons.auto_awesome),
          _buildHandTab('Inventory', HandType.inventory, Icons.inventory),
        ],
      ),
    );
  }

  Widget _buildHandTab(String title, HandType handType, IconData icon) {
    final isActive = _activeHand == handType;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeHand = handType;
          });
          _tabController.animateTo(_getTabIndex(handType));
        },
        child: Container(
          decoration: BoxDecoration(
            color: isActive 
                ? RealmOfValorTheme.accentGold.withOpacity(0.2)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isActive ? RealmOfValorTheme.accentGold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? RealmOfValorTheme.accentGold : RealmOfValorTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? RealmOfValorTheme.accentGold : RealmOfValorTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTabIndex(HandType handType) {
    switch (handType) {
      case HandType.actionCards:
        return 0;
      case HandType.skills:
        return 1;
      case HandType.inventory:
        return 2;
    }
  }

  Widget _buildActionCardsHand() {
    final actionCards = widget.currentPlayer.hand;
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hand size indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Action Cards (${actionCards.length}/10)',
                style: TextStyle(
                  color: RealmOfValorTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.isCurrentPlayer)
                Text(
                  'Draw: ${widget.controller.getCurrentPlayer()?.currentMana ?? 0} mana',
                  style: TextStyle(
                    color: RealmOfValorTheme.accentGold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Cards display
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: actionCards.length,
              itemBuilder: (context, index) {
                final card = actionCards[index];
                final canPlay = widget.isCurrentPlayer && 
                               widget.controller.canPlayCard(card);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: HearthstoneCardWidget(
                    card: card,
                    controller: widget.controller,
                    canPlay: canPlay,
                    onTap: () {
                      if (canPlay) {
                        widget.controller.selectCard(card);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsHand() {
    final skills = widget.currentPlayer.activeSkills;
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills (${skills.length})',
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: skills.length,
              itemBuilder: (context, index) {
                final skill = skills[index];
                final canUse = widget.isCurrentPlayer && 
                              widget.controller.canUseSkill(skill);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSkillCard(skill, canUse),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(GameCard skill, bool canUse) {
    return GestureDetector(
      onTap: canUse ? () => widget.controller.useSkill(skill) : null,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: canUse 
                ? [Colors.blue.withOpacity(0.8), Colors.blue.withOpacity(0.6)]
                : [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)],
          ),
          border: Border.all(
            color: canUse ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: canUse ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              skill.name,
              style: TextStyle(
                color: canUse ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Skill',
              style: TextStyle(
                color: canUse ? Colors.white70 : Colors.grey,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryHand() {
    final inventory = widget.currentPlayer.character.equipment.getAllEquippedItems();
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory (${inventory.length})',
            style: TextStyle(
              color: RealmOfValorTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                final canUse = widget.isCurrentPlayer && 
                              widget.controller.canUseItem(item);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildInventoryCard(item, canUse),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(CardInstance item, bool canUse) {
    return GestureDetector(
      onTap: canUse ? () => widget.controller.useItem(item) : null,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: canUse 
                ? [Colors.orange.withOpacity(0.8), Colors.orange.withOpacity(0.6)]
                : [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)],
          ),
          border: Border.all(
            color: canUse ? Colors.orange : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              color: canUse ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.card.name,
              style: TextStyle(
                color: canUse ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              item.card.rarity.name,
              style: TextStyle(
                color: canUse ? Colors.white70 : Colors.grey,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 