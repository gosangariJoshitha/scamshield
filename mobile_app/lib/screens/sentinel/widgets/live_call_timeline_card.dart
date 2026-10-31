import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class LiveCallTimelineCard extends StatelessWidget {
  const LiveCallTimelineCard({
    required this.elapsedSeconds,
    this.currentStep = 3, // 1: Capturing, 2: Transcribing, 3: Analyzing, 4: Generating Alert
    super.key,
  });

  final int elapsedSeconds;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
    final timerString = '$minutes:$seconds';

    final Color primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF0284C7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyzing Call in Real-Time…',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                ],
              ),
              Text(
                timerString,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4-step progress row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimelineStep(
                stepIndex: 1,
                label: 'Capturing\nAudio',
                state: currentStep > 1 ? _StepState.completed : (currentStep == 1 ? _StepState.active : _StepState.pending),
                primaryColor: primaryColor,
              ),
              Expanded(
                child: _TimelineConnector(isDone: currentStep > 1, primaryColor: primaryColor),
              ),
              _TimelineStep(
                stepIndex: 2,
                label: 'Transcribing\nSpeech',
                state: currentStep > 2 ? _StepState.completed : (currentStep == 2 ? _StepState.active : _StepState.pending),
                primaryColor: primaryColor,
              ),
              Expanded(
                child: _TimelineConnector(isDone: currentStep > 2, primaryColor: primaryColor),
              ),
              _TimelineStep(
                stepIndex: 3,
                label: 'Analyzing\nwith AI',
                state: currentStep > 3 ? _StepState.completed : (currentStep == 3 ? _StepState.active : _StepState.pending),
                primaryColor: primaryColor,
              ),
              Expanded(
                child: _TimelineConnector(isDone: currentStep > 3, primaryColor: primaryColor),
              ),
              _TimelineStep(
                stepIndex: 4,
                label: 'Generating\nAlert',
                state: currentStep >= 4 ? _StepState.completed : _StepState.pending,
                primaryColor: primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _StepState { completed, active, pending }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.stepIndex,
    required this.label,
    required this.state,
    required this.primaryColor,
  });

  final int stepIndex;
  final String label;
  final _StepState state;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = state == _StepState.completed;
    final isActive = state == _StepState.active;

    final Color circleBg = isCompleted || isActive ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final Color textColor = isCompleted || isActive ? (isDark ? Colors.white : AppColors.navy) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : (isActive
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: isCompleted || isActive ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.isDone, required this.primaryColor});

  final bool isDone;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 2,
      color: isDone ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
    );
  }
}
