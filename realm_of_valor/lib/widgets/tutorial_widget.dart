import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tutorial_service.dart';
import '../constants/theme.dart';

class TutorialWidget extends StatefulWidget {
  final Widget child;
  final bool showTutorial;

  const TutorialWidget({
    super.key,
    required this.child,
    this.showTutorial = true,
  });

  @override
  State<TutorialWidget> createState() => _TutorialWidgetState();
}

class _TutorialWidgetState extends State<TutorialWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TutorialService>(
      builder: (context, tutorialService, child) {
        if (!widget.showTutorial || !tutorialService.shouldShowTutorial()) {
          return widget.child;
        }

        return Stack(
          children: [
            widget.child,
            if (tutorialService.isTutorialActive)
              _buildTutorialOverlay(tutorialService),
          ],
        );
      },
    );
  }

  Widget _buildTutorialOverlay(TutorialService tutorialService) {
    final stepData = tutorialService.currentStepData;
    
    switch (stepData.type) {
      case TutorialType.overlay:
        return _buildOverlayTutorial(tutorialService, stepData);
      case TutorialType.modal:
        return _buildModalTutorial(tutorialService, stepData);
      case TutorialType.highlight:
        return _buildHighlightTutorial(tutorialService, stepData);
      case TutorialType.walkthrough:
        return _buildWalkthroughTutorial(tutorialService, stepData);
    }
  }

  Widget _buildOverlayTutorial(TutorialService tutorialService, TutorialStepData stepData) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: RealmOfValorTheme.accentGold,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTutorialHeader(tutorialService, stepData),
                const SizedBox(height: 16),
                _buildTutorialContent(stepData),
                const SizedBox(height: 24),
                _buildTutorialActions(tutorialService, stepData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalTutorial(TutorialService tutorialService, TutorialStepData stepData) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: RealmOfValorTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: RealmOfValorTheme.accentGold,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: RealmOfValorTheme.accentGold.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTutorialHeader(tutorialService, stepData),
                const SizedBox(height: 20),
                _buildTutorialContent(stepData),
                const SizedBox(height: 24),
                _buildTutorialActions(tutorialService, stepData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightTutorial(TutorialService tutorialService, TutorialStepData stepData) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Stack(
          children: [
            // Highlight area (placeholder - would be positioned over specific UI elements)
            Positioned(
              top: 100,
              left: 50,
              right: 50,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: RealmOfValorTheme.accentGold,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: RealmOfValorTheme.accentGold.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Tutorial content
            Positioned(
              bottom: 100,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: RealmOfValorTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: RealmOfValorTheme.accentGold,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTutorialHeader(tutorialService, stepData),
                    const SizedBox(height: 12),
                    _buildTutorialContent(stepData),
                    const SizedBox(height: 16),
                    _buildTutorialActions(tutorialService, stepData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkthroughTutorial(TutorialService tutorialService, TutorialStepData stepData) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: RealmOfValorTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: RealmOfValorTheme.accentGold,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTutorialHeader(tutorialService, stepData),
                      const SizedBox(height: 16),
                      _buildTutorialContent(stepData),
                      if (stepData.actions != null) ...[
                        const SizedBox(height: 16),
                        _buildActionSteps(stepData.actions!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildTutorialActions(tutorialService, stepData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialHeader(TutorialService tutorialService, TutorialStepData stepData) {
    return Row(
      children: [
        Icon(
          _getStepIcon(stepData.step),
          color: RealmOfValorTheme.accentGold,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepData.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: tutorialService.stepProgress,
                backgroundColor: RealmOfValorTheme.surfaceMedium,
                valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => tutorialService.skipTutorial(),
          icon: Icon(
            Icons.close,
            color: RealmOfValorTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialContent(TutorialStepData stepData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepData.description,
          style: TextStyle(
            fontSize: 16,
            color: RealmOfValorTheme.textSecondary,
            height: 1.4,
          ),
        ),
        if (stepData.estimatedTime != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: RealmOfValorTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated time: ${_formatDuration(stepData.estimatedTime!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionSteps(List<String> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Steps to complete:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RealmOfValorTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: RealmOfValorTheme.accentGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action,
                    style: TextStyle(
                      fontSize: 14,
                      color: RealmOfValorTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTutorialActions(TutorialService tutorialService, TutorialStepData stepData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (tutorialService.currentStep != TutorialStep.welcome)
          TextButton(
            onPressed: () => tutorialService.previousStep(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  color: RealmOfValorTheme.accentGold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Previous',
                  style: TextStyle(
                    color: RealmOfValorTheme.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            if (stepData.step != TutorialStep.complete)
              TextButton(
                onPressed: () => tutorialService.skipTutorial(),
                child: Text(
                  'Skip Tutorial',
                  style: TextStyle(
                    color: RealmOfValorTheme.textSecondary,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                tutorialService.completeCurrentStep();
                if (stepData.step == TutorialStep.complete) {
                  tutorialService.completeTutorial();
                } else {
                  tutorialService.nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.accentGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                stepData.step == TutorialStep.complete ? 'Start Adventure!' : 'Next',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getStepIcon(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcome:
        return Icons.celebration;
      case TutorialStep.characterCreation:
        return Icons.person_add;
      case TutorialStep.skillTree:
        return Icons.account_tree;
      case TutorialStep.battleSystem:
        return Icons.sports_esports;
      case TutorialStep.damageCalculator:
        return Icons.calculate;
      case TutorialStep.dailyQuests:
        return Icons.assignment;
      case TutorialStep.achievements:
        return Icons.emoji_events;
      case TutorialStep.socialFeatures:
        return Icons.people;
      case TutorialStep.fitnessTracking:
        return Icons.fitness_center;
      case TutorialStep.locationExploration:
        return Icons.explore;
      case TutorialStep.cardSystem:
        return Icons.style;
      case TutorialStep.qrScanner:
        return Icons.qr_code_scanner;
      case TutorialStep.settings:
        return Icons.settings;
      case TutorialStep.complete:
        return Icons.rocket_launch;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

// Tutorial overlay widget for highlighting specific UI elements
class TutorialHighlight extends StatelessWidget {
  final Widget child;
  final bool isHighlighted;
  final String? tutorialMessage;
  final VoidCallback? onTap;

  const TutorialHighlight({
    super.key,
    required this.child,
    this.isHighlighted = false,
    this.tutorialMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isHighlighted)
          Positioned.fill(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: RealmOfValorTheme.accentGold,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: RealmOfValorTheme.accentGold.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: tutorialMessage != null
                    ? Tooltip(
                        message: tutorialMessage!,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      )
                    : Container(
                        color: Colors.transparent,
                      ),
              ),
            ),
          ),
      ],
    );
  }
} 