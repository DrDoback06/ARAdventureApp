import 'package:flutter/material.dart';
import '../models/battle_model.dart';

class EnhancedDragFeedbackWidget extends StatefulWidget {
  final ActionCard card;
  final bool canPlay;
  final bool isSelected;
  final bool enabled;
  final Function(Offset)? onDragStart;
  final Function(Offset)? onDragUpdate;
  final Function(Offset)? onDragEnd;

  const EnhancedDragFeedbackWidget({
    super.key,
    required this.card,
    required this.canPlay,
    required this.isSelected,
    required this.enabled,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<EnhancedDragFeedbackWidget> createState() => _EnhancedDragFeedbackWidgetState();
}

class _EnhancedDragFeedbackWidgetState extends State<EnhancedDragFeedbackWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.enabled && widget.canPlay ? (details) {
        setState(() {
          _isPressed = true;
        });
        widget.onDragStart?.call(details.globalPosition);
      } : null,
      onPanUpdate: widget.enabled && widget.canPlay ? (details) {
        widget.onDragUpdate?.call(details.globalPosition);
      } : null,
      onPanEnd: widget.enabled && widget.canPlay ? (details) {
        setState(() {
          _isPressed = false;
        });
        widget.onDragEnd?.call(details.globalPosition);
      } : null,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: widget.canPlay ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected ? Colors.white : Colors.black,
            width: widget.isSelected ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.card.cost}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.card.type.toString().split('.').last.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                widget.card.description,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 