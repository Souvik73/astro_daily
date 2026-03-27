import '../models/astro_models.dart';
import '../models/subscription_models.dart';

enum AppFeature { kundli, matching, numerology, gemstones, dailyHoroscope }

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
}

abstract class BillingGateway {
  Future<PurchaseStatus> startPurchase(PlanType planType);
  Future<void> restorePurchases();
  Future<SubscriptionEntitlement> syncEntitlement();
}

abstract class UsagePolicy {
  bool canUseFeature(String userId, AppFeature feature);
  void recordUsage(String userId, AppFeature feature);
  int usedToday(String userId, AppFeature feature);
  int dailyQuotaFor(AppFeature feature);
}
