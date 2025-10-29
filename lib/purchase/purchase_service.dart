import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  // Singleton pattern
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs
  static const String vintageAmberThemeId = 'theme_vintage_amber';

  // SharedPreferences keys
  static const String _purchasedThemesKey = 'purchased_themes';

  bool _isInitialized = false;
  final Set<String> _purchasedThemes = {};

  /// Initialize the purchase service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if in-app purchase is available
    final available = await _iap.isAvailable();
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

    // Restore past purchases
    await _iap.restorePurchases();

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
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
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
    // Handle error
    // In a production app, you would want to log this or show an error message
  }

  /// Check if a theme is purchased
  bool isThemePurchased(String themeId) {
    return _purchasedThemes.contains(themeId);
  }

  /// Purchase a theme
  Future<bool> purchaseTheme(String themeId) async {
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
      return false;
    }

    if (productDetailsResponse.productDetails.isEmpty) {
      return false;
    }

    final productDetails = productDetailsResponse.productDetails.first;

    // Create purchase param
    final purchaseParam = PurchaseParam(productDetails: productDetails);

    // Initiate purchase
    try {
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      await initialize();
    }

    await _iap.restorePurchases();
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
