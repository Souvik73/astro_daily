import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/contracts.dart';

class ChatQuotaBanner extends StatelessWidget {
  const ChatQuotaBanner({required this.access, super.key});

  final FeatureAccess access;

  @override
  Widget build(BuildContext context) {
    final bool isReward = access == FeatureAccess.rewardUnlockAvailable;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isReward
          ? AppTheme.gold.withValues(alpha: 0.12)
          : AppTheme.coral.withValues(alpha: 0.10),
      child: Text(
        isReward
            ? 'Daily limit reached — watch an ad to unlock 3 more questions.'
            : 'Upgrade to Premium for up to 30 questions per day.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isReward ? AppTheme.gold : AppTheme.coral,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
