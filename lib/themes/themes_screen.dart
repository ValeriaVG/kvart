import 'package:flutter/material.dart';
import 'package:kvart/themes/blaze/blaze.dart';
import 'package:kvart/themes/default/default.dart';
import 'package:kvart/themes/theme_service.dart';
import 'package:kvart/themes/vintage_amber/vintage_amber.dart';
import 'package:kvart/timer/timer_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  final _themeService = ThemeService();
  final _previewController = TimerController(secondsTotal: 900);
  String? _selectedThemeId;
  String? _purchasingThemeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedTheme();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedTheme() async {
    await _themeService.initializePurchases();
    final themeId = await _themeService.getSelectedTheme();
    setState(() {
      _selectedThemeId = themeId;
      _isLoading = false;
    });
  }

  Future<void> _selectTheme(String themeId) async {
    if (_themeService.isThemeLocked(themeId)) {
      _purchaseTheme(themeId);
      return;
    }

    setState(() {
      _selectedThemeId = themeId;
    });
    await _themeService.setSelectedTheme(themeId);
  }

  Future<void> _purchaseTheme(String themeId) async {
    setState(() {
      _purchasingThemeId = themeId;
    });

    final result = await _themeService.purchaseTheme(themeId);

    setState(() {
      _purchasingThemeId = null;
    });

    if (result == true && mounted) {
      setState(() {
        _selectedThemeId = themeId;
      });
      await _themeService.setSelectedTheme(themeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme unlocked successfully!'),
            backgroundColor: Color(0xFFC5F974),
          ),
        );
      }
    } else if (result == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to purchase theme. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020C1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1A30),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Themes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC5F974)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: ThemeService.availableThemes.length,
              itemBuilder: (context, index) {
                final theme = ThemeService.availableThemes[index];
                final isSelected = theme.id == _selectedThemeId;
                final isLocked = _themeService.isThemeLocked(theme.id);
                final price = _themeService.getThemePrice(theme.id);

                return _ThemeCard(
                  theme: theme,
                  isSelected: isSelected,
                  isLocked: isLocked,
                  isPurchasing: _purchasingThemeId == theme.id,
                  price: price,
                  previewController: _previewController,
                  onTap: () => _selectTheme(theme.id),
                );
              },
            ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final TimerTheme theme;
  final bool isSelected;
  final bool isLocked;
  final bool isPurchasing;
  final String? price;
  final TimerController previewController;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.isLocked,
    required this.isPurchasing,
    required this.price,
    required this.previewController,
    required this.onTap,
  });

  Color get _accentColor {
    switch (theme.id) {
      case 'default':
        return const Color(0xFFC5F974);
      case 'vintage_amber':
        return const Color(0xFFFFB347);
      case 'blaze':
        return const Color(0xFFFF784C);
      default:
        return const Color(0xFFC5F974);
    }
  }

  Color get _backgroundColor {
    switch (theme.id) {
      case 'default':
        return const Color(0xFF0A1A30);
      case 'vintage_amber':
        return const Color(0xFF2D1F0F);
      case 'blaze':
        return const Color(0xFF0C0B0B);
      default:
        return const Color(0xFF0A1A30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected && !isLocked ? _accentColor : Colors.white10,
            width: isSelected && !isLocked ? 2 : 1,
          ),
          boxShadow: isSelected && !isLocked
              ? [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Timer preview
                  Expanded(
                    child: Center(
                      child: _buildTimerPreview(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Theme name
                  Text(
                    theme.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Status / price row
                  _buildStatusRow(),
                ],
              ),
            ),
            // Selected checkmark
            if (isSelected && !isLocked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    color: Color(0xFF020C1D),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerPreview() {
    final Widget timerView;

    switch (theme.id) {
      case 'blaze':
        timerView = BlazeTimerView(
          secondsTotal: 900,
          secondsElapsed: 0,
          controller: previewController,
          ready: true,
        );
      case 'vintage_amber':
        timerView = VintageAmberTimerView(
          secondsTotal: 900,
          secondsElapsed: 0,
          controller: previewController,
          ready: true,
        );
      default:
        timerView = DefaultTimerView(
          secondsTotal: 900,
          secondsElapsed: 0,
          controller: previewController,
          ready: true,
        );
    }

    const previewSize = 120.0;
    const fullSize = 390.0;
    const scale = previewSize / fullSize;

    return SizedBox(
      width: previewSize,
      height: previewSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: OverflowBox(
          maxWidth: fullSize,
          maxHeight: fullSize,
          child: Transform.scale(
            scale: scale,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(fullSize, fullSize)),
              child: SizedBox(
                width: fullSize,
                height: fullSize,
                child: IgnorePointer(child: timerView),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    if (isLocked) {
      return isPurchasing
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: _accentColor,
                strokeWidth: 2,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                price ?? theme.description,
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
    }

    if (isSelected) {
      return Text(
        'Active',
        style: TextStyle(
          color: _accentColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return const Text(
      'Tap to apply',
      style: TextStyle(
        color: Color(0xFF7A90B0),
        fontSize: 13,
      ),
    );
  }
}
