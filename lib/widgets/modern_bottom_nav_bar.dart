import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Using MediaQuery to get safe area padding, making it adaptive.
    final safeAreaPadding = MediaQuery.of(context).padding.bottom;

    // Adjusted height and padding to prevent overflow on various screen densities.
    return Container(
      height: 70 + safeAreaPadding,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: safeAreaPadding + 8,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            selectedIcon: Icons.calendar_today,
            unselectedIcon: Icons.calendar_today_outlined,
            label: "RDV",
            index: 0,
          ),
          _buildNavItem(
            context: context,
            selectedIcon: Icons.event_note,
            unselectedIcon: Icons.event_note_outlined,
            label: "Planning",
            index: 1,
          ),
          _buildNavItem(
            context: context,
            selectedIcon: Icons.location_on,
            unselectedIcon: Icons.location_on_outlined,
            label: "Localisation",
            index: 2,
          ),
          _buildNavItem(
            context: context,
            selectedIcon: Icons.settings,
            unselectedIcon: Icons.settings_outlined,
            label: "Paramètres",
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;
    final theme = Theme.of(context);
    final Color activeColor = theme.colorScheme.primary;
    final Color inactiveColor = theme.colorScheme.onSurface.withOpacity(0.6);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTap(index);
          HapticFeedback.lightImpact();
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: isSelected
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2), // Reduced height to prevent overflow
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10, // Reduced font size for more space
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}