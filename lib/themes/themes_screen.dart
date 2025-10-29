import 'package:flutter/material.dart';
import 'package:kvart/themes/theme_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  final _themeService = ThemeService();
  String? _selectedThemeId;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedTheme();
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
    // Check if theme is locked
    if (_themeService.isThemeLocked(themeId)) {
      // Show purchase dialog
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
      _isPurchasing = true;
    });

    final success = await _themeService.purchaseTheme(themeId);

    setState(() {
      _isPurchasing = false;
    });

    if (success && mounted) {
      // Purchase successful, select the theme
      setState(() {
        _selectedThemeId = themeId;
      });
      await _themeService.setSelectedTheme(themeId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme unlocked successfully!'),
            backgroundColor: Color(0xFFC5F974),
          ),
        );
      }
    } else if (mounted) {
      // Show error message
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ThemeService.availableThemes.length,
              itemBuilder: (context, index) {
                final theme = ThemeService.availableThemes[index];
                final isSelected = theme.id == _selectedThemeId;
                final isLocked = _themeService.isThemeLocked(theme.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ThemeCard(
                    theme: theme,
                    isSelected: isSelected,
                    isLocked: isLocked,
                    isPurchasing: _isPurchasing && isLocked,
                    onTap: () => _selectTheme(theme.id),
                  ),
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
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.isLocked,
    required this.isPurchasing,
    required this.onTap,
  });

  Color get _accentColor {
    switch (theme.id) {
      case 'default':
        return const Color(0xFFC5F974);
      case 'vintage_amber':
        return const Color(0xFFFFB347);
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
      default:
        return const Color(0xFF0A1A30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isLocked ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected && !isLocked
                    ? _accentColor
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected && !isLocked
                  ? [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Theme preview circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _backgroundColor,
                    border: Border.all(color: _accentColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '15',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: _accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Theme info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A90B0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lock or selection indicator
                if (isLocked)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A90B0),
                      shape: BoxShape.circle,
                    ),
                    child: isPurchasing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Color(0xFF020C1D),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            LucideIcons.lock,
                            color: Color(0xFF020C1D),
                            size: 16,
                          ),
                  )
                else if (isSelected)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      color: Color(0xFF020C1D),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
