import '../models/subscription_models.dart';
import '../services/contracts.dart';

/// Per-feature quota configuration.
///
/// `-1` on [freeQuota] or [premiumQuota] means unlimited for that tier.
/// When [freeQuota] is `0` and [rewardCap] > 0 the feature is effectively
/// rewarded-only for free users. When [rewardGrant] is `0` no rewarded
/// unlock is exposed (the plan treats Daily Horoscope this way since it is
/// always free and unlimited).
class FeatureQuotaConfig {
  const FeatureQuotaConfig({
    required this.period,
    required this.freeQuota,
    required this.premiumQuota,
    required this.rewardGrant,
    required this.rewardCap,
  });

  final QuotaPeriod period;
  final int freeQuota;
  final int premiumQuota;
  final int rewardGrant;
  final int rewardCap;
}

/// Default quota map, derived from `astro-daily-plan.md` v1:
///
/// * Daily Horoscope — free, unlimited, no rewarded unlock.
/// * Horoscope Companion chat — 3 free questions/day, rewarded +3 (one
///   unlock/day), Premium 30 questions/day.
/// * Numerology — 1 free/day, rewarded +1 (one unlock/day), Premium
///   unlimited.
/// * Matching — 1 free/day, rewarded +1 (one unlock/day), Premium
///   unlimited.
/// * Gemstones — 1 free/week, rewarded +1 (one unlock/week), Premium
///   unlimited.
/// * Kundli — 1 free chart per profile, 1 rewarded refresh/week, Premium
///   unlimited. This is currently modeled as weekly with a free quota of 1
///   and a weekly rewarded refresh. A follow-up that introduces the
///   `report_cache` table will lift the first chart into a `oneTimePerUser`
///   bucket and reduce the weekly free quota to 0.
const Map<AppFeature, FeatureQuotaConfig> kDefaultQuotaConfigs =
    <AppFeature, FeatureQuotaConfig>{
  AppFeature.dailyHoroscope: FeatureQuotaConfig(
    period: QuotaPeriod.daily,
    freeQuota: -1,
    premiumQuota: -1,
    rewardGrant: 0,
    rewardCap: 0,
  ),
  AppFeature.horoscopeChat: FeatureQuotaConfig(
    period: QuotaPeriod.daily,
    freeQuota: 3,
    premiumQuota: 30,
    rewardGrant: 3,
    rewardCap: 1,
  ),
  AppFeature.numerology: FeatureQuotaConfig(
    period: QuotaPeriod.daily,
    freeQuota: 1,
    premiumQuota: -1,
    rewardGrant: 1,
    rewardCap: 1,
  ),
  AppFeature.matching: FeatureQuotaConfig(
    period: QuotaPeriod.daily,
    freeQuota: 1,
    premiumQuota: -1,
    rewardGrant: 1,
    rewardCap: 1,
  ),
  AppFeature.gemstones: FeatureQuotaConfig(
    period: QuotaPeriod.weekly,
    freeQuota: 1,
    premiumQuota: -1,
    rewardGrant: 1,
    rewardCap: 1,
  ),
  AppFeature.kundli: FeatureQuotaConfig(
    period: QuotaPeriod.weekly,
    freeQuota: 1,
    premiumQuota: -1,
    rewardGrant: 1,
    rewardCap: 1,
  ),
};

/// In-memory implementation of [UsagePolicy]. Counters reset when the app
/// process dies; a production implementation should back this with the
/// Supabase `feature_usage` + `ad_rewards` tables so quotas survive
/// restarts and can be enforced server-side.
class InMemoryUsagePolicy implements UsagePolicy {
  InMemoryUsagePolicy({
    required this.tierLookup,
    Map<AppFeature, FeatureQuotaConfig> configs = kDefaultQuotaConfigs,
    DateTime Function()? now,
  })  : _configs = configs,
        _now = now ?? DateTime.now;

  final SubscriptionTier Function(String userId) tierLookup;
  final Map<AppFeature, FeatureQuotaConfig> _configs;
  final DateTime Function() _now;

  final Map<String, int> _usage = <String, int>{};
  final Map<String, int> _rewards = <String, int>{};

  @override
  FeatureAccess resolveAccess(String userId, AppFeature feature) {
    final FeatureQuotaConfig config = _configFor(feature);
    final SubscriptionTier tier = tierLookup(userId);
    final int used = _readUsage(userId, feature, config.period);
    final int rewardsGranted = _readRewards(userId, feature, config.period);

    if (tier == SubscriptionTier.premium) {
      final int premiumQuota = config.premiumQuota;
      if (premiumQuota < 0) {
        return FeatureAccess.open;
      }
      return used < premiumQuota
          ? FeatureAccess.open
          : FeatureAccess.premiumRequired;
    }

    final int freeQuota = config.freeQuota;
    if (freeQuota < 0) {
      return FeatureAccess.open;
    }
    final int totalAllowed = freeQuota + rewardsGranted * config.rewardGrant;
    if (used < totalAllowed) {
      return FeatureAccess.open;
    }
    if (rewardsGranted < config.rewardCap && config.rewardGrant > 0) {
      return FeatureAccess.rewardUnlockAvailable;
    }
    return FeatureAccess.premiumRequired;
  }

  @override
  void recordUsage(String userId, AppFeature feature) {
    final FeatureQuotaConfig config = _configFor(feature);
    final String key = _usageKey(userId, feature, config.period);
    _usage[key] = (_usage[key] ?? 0) + 1;
  }

  @override
  void recordRewardGranted(String userId, AppFeature feature) {
    final FeatureQuotaConfig config = _configFor(feature);
    if (config.rewardCap == 0 || config.rewardGrant == 0) {
      return;
    }
    final String key = _rewardsKey(userId, feature, config.period);
    final int current = _rewards[key] ?? 0;
    if (current >= config.rewardCap) {
      return;
    }
    _rewards[key] = current + 1;
  }

  @override
  FeatureQuotaStatus statusFor(String userId, AppFeature feature) {
    final FeatureQuotaConfig config = _configFor(feature);
    final SubscriptionTier tier = tierLookup(userId);
    final int used = _readUsage(userId, feature, config.period);
    final int rewardsGranted = _readRewards(userId, feature, config.period);

    final int quota;
    if (tier == SubscriptionTier.premium) {
      quota = config.premiumQuota;
    } else if (config.freeQuota < 0) {
      quota = -1;
    } else {
      quota = config.freeQuota + rewardsGranted * config.rewardGrant;
    }

    return FeatureQuotaStatus(
      feature: feature,
      period: config.period,
      used: used,
      quota: quota,
      rewardsGranted: rewardsGranted,
      rewardCap: config.rewardCap,
      access: resolveAccess(userId, feature),
    );
  }

  FeatureQuotaConfig _configFor(AppFeature feature) {
    final FeatureQuotaConfig? config = _configs[feature];
    if (config == null) {
      throw StateError('No quota config registered for $feature');
    }
    return config;
  }

  int _readUsage(String userId, AppFeature feature, QuotaPeriod period) {
    return _usage[_usageKey(userId, feature, period)] ?? 0;
  }

  int _readRewards(String userId, AppFeature feature, QuotaPeriod period) {
    return _rewards[_rewardsKey(userId, feature, period)] ?? 0;
  }

  String _usageKey(String userId, AppFeature feature, QuotaPeriod period) {
    return 'usage|${_periodKey(period)}|$userId|${feature.name}';
  }

  String _rewardsKey(String userId, AppFeature feature, QuotaPeriod period) {
    return 'reward|${_periodKey(period)}|$userId|${feature.name}';
  }

  String _periodKey(QuotaPeriod period) {
    switch (period) {
      case QuotaPeriod.daily:
        final DateTime today = _now();
        final String y = today.year.toString().padLeft(4, '0');
        final String m = today.month.toString().padLeft(2, '0');
        final String d = today.day.toString().padLeft(2, '0');
        return 'd-$y-$m-$d';
      case QuotaPeriod.weekly:
        final DateTime week = _now();
        final _IsoWeek iso = _IsoWeek.fromDate(week);
        final String y = iso.year.toString().padLeft(4, '0');
        final String w = iso.week.toString().padLeft(2, '0');
        return 'w-$y-W$w';
      case QuotaPeriod.oneTimePerUser:
        return 'forever';
    }
  }
}

/// Lightweight ISO 8601 week number. Monday is the first day of the week.
class _IsoWeek {
  const _IsoWeek(this.year, this.week);

  final int year;
  final int week;

  static _IsoWeek fromDate(DateTime date) {
    final DateTime utc = DateTime.utc(date.year, date.month, date.day);
    // ISO weekday: Monday = 1 ... Sunday = 7.
    final int weekday = utc.weekday;
    // Shift to Thursday of the same ISO week.
    final DateTime thursday = utc.add(Duration(days: 4 - weekday));
    final DateTime firstThursday = _firstThursdayOfYear(thursday.year);
    final int diffDays = thursday.difference(firstThursday).inDays;
    final int week = 1 + (diffDays ~/ 7);
    return _IsoWeek(thursday.year, week);
  }

  static DateTime _firstThursdayOfYear(int year) {
    final DateTime jan4 = DateTime.utc(year, 1, 4);
    // The week containing January 4 is always ISO week 1, and its Thursday
    // is the first Thursday of the ISO year.
    final int shift = 4 - jan4.weekday;
    return jan4.add(Duration(days: shift));
  }
}
