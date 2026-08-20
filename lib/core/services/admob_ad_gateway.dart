import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/auth_environment.dart';
import 'contracts.dart';

/// Real implementation of [AdGateway] backed by Google AdMob rewarded ads.
///
/// An ad is preloaded eagerly so the "watch ad" CTA can present it with as
/// little delay as possible, and a replacement is preloaded again after each
/// show completes (or fails).
class AdMobAdGateway implements AdGateway {
  AdMobAdGateway() {
    _loadAd();
  }

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void _loadAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: AuthEnvironment.admobRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  @override
  Future<RewardedAdResult> showRewardedAd() async {
    // If nothing is preloaded yet, kick off a load and give it a short
    // window to finish rather than failing immediately.
    if (_rewardedAd == null) {
      _loadAd();
      final DateTime deadline = DateTime.now().add(const Duration(seconds: 8));
      while (_rewardedAd == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    final RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      return RewardedAdResult.failedToLoad;
    }
    _rewardedAd = null; // consumed — a fresh one loads after this completes

    bool earned = false;
    final Completer<RewardedAdResult> completer = Completer<RewardedAdResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _loadAd();
        if (!completer.isCompleted) {
          completer.complete(
            earned ? RewardedAdResult.earned : RewardedAdResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _loadAd();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdResult.failedToLoad);
        }
      },
    );

    unawaited(
      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          earned = true;
        },
      ),
    );

    return completer.future;
  }
}
