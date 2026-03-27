import '../models/subscription_models.dart';
import '../services/contracts.dart';

class InMemoryUsagePolicy implements UsagePolicy {
  InMemoryUsagePolicy({required this.tierLookup});

  final SubscriptionTier Function(String userId) tierLookup;

  final Map<String, int> _dailyUsage = <String, int>{};

  final Map<AppFeature, int> _freeTierQuotas = const <AppFeature, int>{
    AppFeature.dailyHoroscope: 2,
    AppFeature.kundli: 1,
    AppFeature.matching: 1,
    AppFeature.numerology: 1,
    AppFeature.gemstones: 1,
  };

  @override
  bool canUseFeature(String userId, AppFeature feature) {
    if (tierLookup(userId) == SubscriptionTier.premium) {
      return true;
    }
    final int quota = dailyQuotaFor(feature);
    return usedToday(userId, feature) < quota;
  }

  @override
  int dailyQuotaFor(AppFeature feature) => _freeTierQuotas[feature] ?? 0;

  @override
  void recordUsage(String userId, AppFeature feature) {
    final String key = _buildKey(userId, feature, DateTime.now());
    _dailyUsage[key] = usedToday(userId, feature) + 1;
  }

  @override
  int usedToday(String userId, AppFeature feature) {
    final String key = _buildKey(userId, feature, DateTime.now());
    return _dailyUsage[key] ?? 0;
  }

  String _buildKey(String userId, AppFeature feature, DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$userId|${feature.name}|$year-$month-$day';
  }
}
