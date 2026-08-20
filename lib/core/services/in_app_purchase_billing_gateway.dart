import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import '../error/failures.dart';
import '../models/subscription_models.dart';
import 'contracts.dart';

/// Real implementation of [BillingGateway] using the official
/// `in_app_purchase` plugin (StoreKit on iOS, Play Billing on Android).
///
/// Product IDs must be created in App Store Connect / Google Play Console
/// with exactly these identifiers before purchases can succeed.
///
/// Server-side receipt verification is intentionally not wired here yet —
/// there are no real store products or platform API credentials to verify
/// against. Entitlement is granted on the client's read of the purchase
/// stream, matching this app's existing trust model (see
/// `AuthRepository.updateSubscriptionTier`, which is likewise client-set).
/// Before shipping paid subscriptions, add a Supabase edge function that
/// verifies the purchase token (Android: Play Developer API
/// `purchases.subscriptionsv2.get`) / transaction (iOS: App Store Server API
/// `GET /inApps/v1/subscriptions/{id}`) and only then flips
/// `profiles.subscription_tier` server-side.
class InAppPurchaseBillingGateway implements BillingGateway {
  InAppPurchaseBillingGateway() {
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object _) {},
    );
  }

  static const String monthlyProductId = 'astro_daily_premium_monthly';
  static const String yearlyProductId = 'astro_daily_premium_yearly';

  final iap.InAppPurchase _iap = iap.InAppPurchase.instance;
  late final StreamSubscription<List<iap.PurchaseDetails>>
  _purchaseSubscription;

  Completer<PurchaseStatus>? _pendingPurchase;
  SubscriptionEntitlement _entitlement = const SubscriptionEntitlement(
    tier: SubscriptionTier.free,
  );

  @override
  Future<PurchaseStatus> startPurchase(PlanType planType) async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      throw const DataFailure('The store is not available on this device.');
    }

    final String productId = switch (planType) {
      PlanType.monthly => monthlyProductId,
      PlanType.yearly => yearlyProductId,
    };

    final iap.ProductDetailsResponse response = await _iap
        .queryProductDetails(<String>{productId});
    if (response.productDetails.isEmpty ||
        response.notFoundIDs.contains(productId)) {
      throw DataFailure(
        'Plan "$productId" is not set up in the store yet.',
      );
    }

    final Completer<PurchaseStatus> completer = Completer<PurchaseStatus>();
    _pendingPurchase = completer;

    final iap.PurchaseParam param = iap.PurchaseParam(
      productDetails: response.productDetails.first,
    );
    final bool started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      _pendingPurchase = null;
      throw const DataFailure('Could not start the purchase.');
    }
    return completer.future;
  }

  @override
  Future<void> restorePurchases() {
    return _iap.restorePurchases();
  }

  @override
  Future<SubscriptionEntitlement> syncEntitlement() async {
    return _entitlement;
  }

  Future<void> _onPurchaseUpdate(
    List<iap.PurchaseDetails> purchases,
  ) async {
    for (final iap.PurchaseDetails purchase in purchases) {
      switch (purchase.status) {
        case iap.PurchaseStatus.pending:
          break;
        case iap.PurchaseStatus.purchased:
        case iap.PurchaseStatus.restored:
          _entitlement = SubscriptionEntitlement(
            tier: SubscriptionTier.premium,
            expiresAt: purchase.productID == yearlyProductId
                ? DateTime.now().add(const Duration(days: 365))
                : DateTime.now().add(const Duration(days: 30)),
          );
          _resolvePending(PurchaseStatus.success);
        case iap.PurchaseStatus.error:
          _resolvePending(PurchaseStatus.failed);
        case iap.PurchaseStatus.canceled:
          _resolvePending(PurchaseStatus.cancelled);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _resolvePending(PurchaseStatus status) {
    final Completer<PurchaseStatus>? completer = _pendingPurchase;
    if (completer != null && !completer.isCompleted) {
      completer.complete(status);
    }
    _pendingPurchase = null;
  }

  void dispose() {
    _purchaseSubscription.cancel();
  }
}
