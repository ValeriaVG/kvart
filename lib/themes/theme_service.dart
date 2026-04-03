import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kvart/purchase/purchase_service.dart';
import 'package:kvart/themes/default/default.dart';
import 'package:kvart/themes/blaze/blaze.dart';
import 'package:kvart/themes/vintage_amber/vintage_amber.dart';
import 'package:kvart/timer/timer_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // Singleton pattern
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final _themeController = StreamController<TimerTheme>.broadcast();
  final _purchaseService = PurchaseService();

  static const String _defaultTheme = 'default';
  static const String _selectedThemeKey = 'selected_theme';

  // Available themes
  static List<TimerTheme> availableThemes = [
    TimerTheme(
      id: 'default',
      name: 'Modern',
      description: 'Clean lime green design',
      view:
          ({
            required int secondsTotal,
            required int secondsElapsed,
            required TimerController controller,
            required bool ready,
            required void Function(int)? onSecondsChanged,
          }) => DefaultTimerView(
            secondsTotal: secondsTotal,
            secondsElapsed: secondsElapsed,
            controller: controller,
            ready: ready,
            onSecondsChanged: onSecondsChanged,
          ),
    ),
    TimerTheme(
      id: 'vintage_amber',
      name: 'Vintage Amber',
      description: 'Post-apocalyptic retro aesthetic',
      productId: 'theme_vintage_amber',
      view:
          ({
            required int secondsTotal,
            required int secondsElapsed,
            required TimerController controller,
            required bool ready,
            required void Function(int)? onSecondsChanged,
          }) => VintageAmberTimerView(
            secondsTotal: secondsTotal,
            secondsElapsed: secondsElapsed,
            controller: controller,
            ready: ready,
            onSecondsChanged: onSecondsChanged,
          ),
    ),
    TimerTheme(
      id: 'blaze',
      name: 'Blaze',
      description: 'Fiery gradient on dark background',
      productId: 'theme_blaze',
      view:
          ({
            required int secondsTotal,
            required int secondsElapsed,
            required TimerController controller,
            required bool ready,
            required void Function(int)? onSecondsChanged,
          }) => BlazeTimerView(
            secondsTotal: secondsTotal,
            secondsElapsed: secondsElapsed,
            controller: controller,
            ready: ready,
            onSecondsChanged: onSecondsChanged,
          ),
    ),
  ];

  /// Get selected theme ID
  Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedThemeKey) ?? _defaultTheme;
  }

  /// Set selected theme ID
  Future<void> setSelectedTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedThemeKey, themeId);
    _themeController.add(
      availableThemes.firstWhere(
        (theme) => theme.id == themeId,
        orElse: () => availableThemes.first,
      ),
    );
  }

  /// Get the TimerTheme object for the currently selected theme
  Future<TimerTheme> getSelectedTimerTheme() async {
    final themeId = await getSelectedTheme();
    return availableThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => availableThemes.first,
    );
  }

  Stream<TimerTheme> get themeStream => _themeController.stream;

  /// Initialize purchase service
  Future<void> initializePurchases() async {
    final productIds = availableThemes
        .where((t) => t.productId != null)
        .map((t) => t.productId!)
        .toSet();
    await _purchaseService.initialize(productIds: productIds);
  }

  /// Check if a theme is locked (requires purchase)
  bool isThemeLocked(String themeId) {
    final theme = availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => availableThemes.first,
    );

    if (!theme.isPaid) {
      return false; // Free theme
    }

    return !_purchaseService.isThemePurchased(theme.productId!);
  }

  /// Purchase a theme.
  /// Returns `true` on success, `false` on error, `null` if user cancelled.
  Future<bool?> purchaseTheme(String themeId) async {
    final theme = availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => availableThemes.first,
    );

    if (!theme.isPaid || theme.productId == null) {
      return false; // Not a paid theme
    }

    return await _purchaseService.purchaseTheme(theme.productId!);
  }

  /// Get the price string for a theme, or null if free/unavailable
  String? getThemePrice(String themeId) {
    final theme = availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => availableThemes.first,
    );
    if (!theme.isPaid || theme.productId == null) return null;
    return _purchaseService.getPrice(theme.productId!);
  }

}

/// Model class for timer themes
class TimerTheme {
  final String id;
  final String name;
  final String description;
  final String? productId;
  final Widget Function({
    required int secondsTotal,
    required int secondsElapsed,
    required TimerController controller,
    required bool ready,
    required void Function(int)? onSecondsChanged,
  })
  view;

  const TimerTheme({
    required this.id,
    required this.name,
    required this.description,
    this.productId,
    required this.view,
  });

  bool get isPaid => productId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerTheme && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
