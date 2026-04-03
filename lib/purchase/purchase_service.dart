import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  // Singleton pattern
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // SharedPreferences keys
  static const String _purchasedThemesKey = 'purchased_themes';

  bool _isInitialized = false;
  final Set<String> _purchasedThemes = {};
  final Map<String, String> _productPrices = {};
  final Map<String, Completer<bool?>> _purchaseCompleters = {};

  /// Initialize the purchase service
  Future<void> initialize({Set<String> productIds = const {}}) async {
    if (_isInitialized) return;

    // Check if in-app purchase is available
    final available = await _iap.isAvailable();
    debugPrint('[PurchaseService] IAP available: $available');
    if (!available) {
      _isInitialized = true;
      return;
    }

    // Load locally stored purchases
    await _loadPurchasedThemes();

    // Listen to purchase updates
    final purchaseUpdates = _iap.purchaseStream;
    _subscription = purchaseUpdates.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseUpdateDone,
      onError: _onPurchaseUpdateError,
    );

    // Fetch product prices
    await _loadProductPrices(productIds);

    _isInitialized = true;
  }

  /// Load purchased themes from local storage
  Future<void> _loadPurchasedThemes() async {
    final prefs = await SharedPreferences.getInstance();
    final purchasedList = prefs.getStringList(_purchasedThemesKey) ?? [];
    _purchasedThemes.addAll(purchasedList);
  }

  /// Save purchased themes to local storage
  Future<void> _savePurchasedThemes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_purchasedThemesKey, _purchasedThemes.toList());
  }

  /// Handle purchase updates
  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('[PurchaseService] handlePurchase: ${purchaseDetails.productID} '
        'status=${purchaseDetails.status}');
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      // Verify purchase locally (basic verification)
      final valid = await _verifyPurchase(purchaseDetails);
      if (valid) {
        // Add to purchased themes
        _purchasedThemes.add(purchaseDetails.productID);
        await _savePurchasedThemes();
      }
    }

    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }

    // Signal purchase completer
    final completer = _purchaseCompleters.remove(purchaseDetails.productID);
    if (completer != null && !completer.isCompleted) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          completer.complete(true);
        case PurchaseStatus.canceled:
          completer.complete(null);
        default:
          completer.complete(false);
      }
    }
  }

  /// Local purchase verification
  /// In production, you should implement server-side verification
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Basic local verification
    // Check if purchase details are valid
    if (purchaseDetails.productID.isEmpty) {
      return false;
    }

    // In a real app, you would verify the purchase receipt with your server
    // or with Apple/Google servers. For now, we'll do basic local verification
    return purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored;
  }

  void _onPurchaseUpdateDone() {
    _subscription?.cancel();
  }

  void _onPurchaseUpdateError(dynamic error) {
    debugPrint('[PurchaseService] stream error: $error');
  }

  /// Load product prices from the store
  Future<void> _loadProductPrices(Set<String> productIds) async {
    if (productIds.isEmpty) return;
    final response = await _iap.queryProductDetails(productIds);
    debugPrint('[PurchaseService] queried prices for $productIds: '
        '${response.productDetails.length} found, '
        'notFound=${response.notFoundIDs}');
    if (response.error != null) {
      debugPrint('[PurchaseService] price query error: ${response.error}');
    }
    for (final product in response.productDetails) {
      _productPrices[product.id] = product.price;
    }
  }

  /// Get the price string for a product, or null if unavailable
  String? getPrice(String productId) => _productPrices[productId];

  /// Check if a theme is purchased
  bool isThemePurchased(String themeId) {
    return _purchasedThemes.contains(themeId);
  }

  /// Purchase a theme.
  /// Returns `true` on success, `false` on error, `null` if user cancelled.
  Future<bool?> purchaseTheme(String themeId) async {
    if (!_isInitialized) {
      await initialize();
    }

    final available = await _iap.isAvailable();
    if (!available) {
      return false;
    }

    // Query product details
    final productDetailsResponse = await _iap.queryProductDetails({themeId});

    if (productDetailsResponse.error != null) {
      debugPrint('[PurchaseService] purchase query error: '
          '${productDetailsResponse.error}');
      return false;
    }

    if (productDetailsResponse.productDetails.isEmpty) {
      debugPrint('[PurchaseService] no product found for $themeId, '
          'notFound=${productDetailsResponse.notFoundIDs}');
      return false;
    }

    final productDetails = productDetailsResponse.productDetails.first;

    // Create purchase param
    final purchaseParam = PurchaseParam(productDetails: productDetails);

    // Register a completer so _handlePurchase can signal us
    final completer = Completer<bool?>();
    _purchaseCompleters[themeId] = completer;

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('[PurchaseService] purchase exception: $e');
      _purchaseCompleters.remove(themeId);
      return false;
    }
  }

  /// Restore previously purchased items.
  /// Returns `true` if any purchases were restored, `false` otherwise.
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      await initialize();
    }

    final available = await _iap.isAvailable();
    if (!available) return false;

    final countBefore = _purchasedThemes.length;

    try {
      await _iap.restorePurchases();
      // Give the purchase stream time to deliver restored items
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[PurchaseService] restore error: $e');
      return false;
    }

    return _purchasedThemes.length > countBefore;
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
