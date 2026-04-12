import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/services/api_client.dart';

/// Product IDs — must match App Store Connect
class IAPProducts {
  static const basicMonthly = 'gf_basic_monthly';
  static const basicYearly = 'gf_basic_yearly';
  static const premiumMonthly = 'gf_premium_monthly';
  static const premiumYearly = 'gf_premium_yearly';

  static const all = {basicMonthly, basicYearly, premiumMonthly, premiumYearly};
}

/// Apple In-App Purchase service — handles StoreKit directly.
/// No RevenueCat — uses Apple's native `in_app_purchase` package.
class AppleIAPService {
  static AppleIAPService? _instance;
  static AppleIAPService get instance {
    _instance ??= AppleIAPService._();
    return _instance!;
  }

  AppleIAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _available = false;
  bool get isAvailable => _available;

  String? _error;
  String? get error => _error;

  /// Initialize — call once on app start
  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (e) => debugPrint('IAP stream error: $e'),
    );

    // Load products from Apple
    await loadProducts();
  }

  /// Load available products from App Store
  Future<void> loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(IAPProducts.all);
      if (response.error != null) {
        _error = response.error!.message;
        debugPrint('IAP product error: ${response.error}');
        return;
      }
      _products = response.productDetails;
      debugPrint('IAP: Loaded ${_products.length} products');
      for (final p in _products) {
        debugPrint('  ${p.id}: ${p.price} (${p.currencyCode})');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('IAP loadProducts error: $e');
    }
  }

  /// Purchase a subscription product
  Future<bool> purchase(ProductDetails product) async {
    try {
      final param = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      debugPrint('IAP purchase started: $started');
      return started;
    } catch (e) {
      _error = e.toString();
      debugPrint('IAP purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases (for users who reinstall)
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Handle purchase updates from Apple
  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      debugPrint('IAP update: ${purchase.productID} status=${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          _error = purchase.error?.message ?? 'Purchase failed';
          debugPrint('IAP error: ${purchase.error}');
          break;
        case PurchaseStatus.pending:
          debugPrint('IAP pending: ${purchase.productID}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('IAP canceled: ${purchase.productID}');
          break;
      }

      // Complete pending purchases (required by Apple)
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Verify receipt with backend and update subscription
  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      final receiptData = purchase.verificationData.serverVerificationData;

      final response = await ApiClient.instance.post(
        '/api/subscriptions/apple/verify',
        data: {
          'receipt_data': receiptData,
          'product_id': purchase.productID,
        },
      );

      if (response.data['success'] == true) {
        final tier = response.data['subscription']['tier'];
        debugPrint('IAP verified: tier=$tier');
      } else {
        _error = 'Receipt validation failed';
        debugPrint('IAP verification failed: ${response.data}');
      }
    } catch (e) {
      _error = 'Could not verify purchase: $e';
      debugPrint('IAP verify error: $e');
    }
  }

  /// Get a product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Get price string for a product
  String getPrice(String productId) {
    final product = getProduct(productId);
    return product?.price ?? '--';
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
