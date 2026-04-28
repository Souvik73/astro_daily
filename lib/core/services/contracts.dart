import '../models/astro_models.dart';
import '../models/subscription_models.dart';

/// Product surfaces that the usage policy arbitrates access for. Keep this
/// enum aligned with the plan in `astro-daily-plan.md`.
enum AppFeature {
  kundli,
  matching,
  numerology,
  gemstones,
  dailyHoroscope,
  horoscopeChat,
}

/// How a feature's quota bucket rolls over.
///
/// - [daily] resets at local midnight.
/// - [weekly] resets on ISO week boundaries (Mon -> Sun).
/// - [oneTimePerUser] never resets and represents "once per profile" items
///   (e.g. the first basic Kundli chart). Caching is expected to cover
///   subsequent re-opens without consuming further quota.
enum QuotaPeriod { daily, weekly, oneTimePerUser }

/// Access decision a page should render against.
///
/// - [open]: let the user in, record usage, navigate.
/// - [rewardUnlockAvailable]: free quota is spent but the user still has a
///   rewarded-ad grant left for this period. UI should surface
///   "Watch ad to unlock".
/// - [premiumRequired]: free + rewarded budgets exhausted. UI should route
///   to the subscription page.
enum FeatureAccess { open, rewardUnlockAvailable, premiumRequired }

/// Snapshot of a feature's current quota state for a single user. Used by
/// the home dashboard to render per-card labels and CTAs.
class FeatureQuotaStatus {
  const FeatureQuotaStatus({
    required this.feature,
    required this.period,
    required this.used,
    required this.quota,
    required this.rewardsGranted,
    required this.rewardCap,
    required this.access,
  });

  final AppFeature feature;
  final QuotaPeriod period;

  /// Number of times the feature was consumed in the current period.
  final int used;

  /// Total allowance for the current period including any rewarded grants.
  /// `-1` means unlimited for the user's current tier.
  final int quota;

  /// How many rewarded unlocks have been granted in the current period.
  final int rewardsGranted;

  /// Maximum rewarded unlocks available per period.
  final int rewardCap;

  final FeatureAccess access;
}

abstract class AstroProvider {
  Future<KundliData> getKundli(BirthDetails birthDetails);
  Future<CompatibilityResult> getCompatibility(CompatibilityRequest request);
  Future<NumerologyResult> getNumerology(BirthDetails birthDetails);
  Future<HoroscopeResponse> getDailyHoroscope(DailyHoroscopeRequest request);
}

abstract class GemstoneEngine {
  Future<GemstoneReport> buildReport(KundliData kundliData);
}

abstract class AiPersonalizer {
  Future<String> summarizeReport(
    GemstoneReport report, {
    required String locale,
  });

  Future<List<String>> generateDosDonts(
    HoroscopeResponse horoscope, {
    required String locale,
  });

  Future<String> answerHoroscopeQuestion(
    String question, {
    required HoroscopeResponse horoscope,
    required String locale,
    /// Conversation history as [{role: "user"|"assistant", content: "..."}].
    /// Local implementations may ignore this; the remote implementation uses
    /// it to maintain conversational context with Gemini.
    List<Map<String, String>> chatHistory = const <Map<String, String>>[],
  });
}

abstract class BillingGateway {
  Future<PurchaseStatus> startPurchase(PlanType planType);
  Future<void> restorePurchases();
  Future<SubscriptionEntitlement> syncEntitlement();
}

/// Decides whether a user can currently use a feature, folding together the
/// free quota, any rewarded-ad grants, and the user's subscription tier.
///
/// The implementation is expected to be deterministic for a given
/// `(userId, feature, now())` tuple and to be safe to call from UI code.
abstract class UsagePolicy {
  /// Returns the three-state access decision for the current period.
  FeatureAccess resolveAccess(String userId, AppFeature feature);

  /// Records a single successful use of the feature. Call this only after
  /// [resolveAccess] returned [FeatureAccess.open].
  void recordUsage(String userId, AppFeature feature);

  /// Records that a rewarded unlock was granted for this period. Each grant
  /// adds `rewardGrant` extra uses to the current period's budget.
  void recordRewardGranted(String userId, AppFeature feature);

  /// Read-only snapshot for dashboards/labels.
  FeatureQuotaStatus statusFor(String userId, AppFeature feature);
}
