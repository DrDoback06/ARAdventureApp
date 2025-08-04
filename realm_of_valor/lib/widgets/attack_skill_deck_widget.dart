import 'package:flutter/material.dart';
import '../models/battle_model.dart';
import '../providers/battle_controller.dart';
import 'hearthstone_card_widget.dart';

class AttackSkillDeckWidget extends StatelessWidget {
  final BattleController controller;
  final List<ActionCard> attackCards;
  final List<ActionCard> skillCards;
  final List<ActionCard> inventoryCards;
  final bool isCurrentPlayer;

  const AttackSkillDeckWidget({
    super.key,
    required this.controller,
    required this.attackCards,
    required this.skillCards,
    required this.inventoryCards,
    required this.isCurrentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Attack Cards
          ...attackCards.map((card) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Draggable<ActionCard>(
                data: card,
                onDragStarted: () {
                  print('[DRAG] Started dragging attack card: ${card.name}');
                  controller.startAttackDrag(Offset.zero);
                },
                onDragEnd: (details) {
                  print('[DRAG] Ended dragging attack card');
                  controller.endDrag();
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFe94560),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'ATTACK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: HearthstoneCardWidget(
                    card: card,
                    controller: controller,
                    canPlay: false,
                  ),
                ),
                child: HearthstoneCardWidget(
                  card: card,
                  controller: controller,
                  canPlay: isCurrentPlayer && controller.canAttack(),
                  onTap: () {
                    if (isCurrentPlayer && controller.canAttack()) {
                      controller.selectAttackCard(card);
                    }
                  },
                ),
              ),
            );
          }).toList(),
          
          // Skill Cards
          ...skillCards.map((card) {
            final currentPlayer = controller.getCurrentPlayer();
            final canPlay = isCurrentPlayer && 
                           currentPlayer != null && 
                           currentPlayer.currentMana >= card.cost;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Draggable<ActionCard>(
                data: card,
                onDragStarted: () {
                  print('[DRAG] Started dragging skill card: ${card.name}');
                  controller.startSkillDrag(card, Offset.zero);
                },
                onDragEnd: (details) {
                  print('[DRAG] Ended dragging skill card');
                  controller.endDrag();
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: HearthstoneCardWidget(
                    card: card,
                    controller: controller,
                    canPlay: false,
                  ),
                ),
                child: HearthstoneCardWidget(
                  card: card,
                  controller: controller,
                  canPlay: canPlay,
                  onTap: () {
                    if (canPlay) {
                      controller.selectSkillCard(card);
                    }
                  },
                ),
              ),
            );
          }).toList(),
          
          // Inventory Cards
          ...inventoryCards.map((card) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Draggable<ActionCard>(
                data: card,
                onDragStarted: () {
                  print('[DRAG] Started dragging inventory card: ${card.name}');
                  controller.startCardDrag(card, Offset.zero);
                },
                onDragEnd: (details) {
                  print('[DRAG] Ended dragging inventory card');
                  controller.endDrag();
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: HearthstoneCardWidget(
                    card: card,
                    controller: controller,
                    canPlay: false,
                  ),
                ),
                child: HearthstoneCardWidget(
                  card: card,
                  controller: controller,
                  canPlay: isCurrentPlayer,
                  onTap: () {
                    if (isCurrentPlayer) {
                      controller.selectInventoryCard(card);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 