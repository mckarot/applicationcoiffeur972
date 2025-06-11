import 'package:flutter/material.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index) {
    bool isSelected = currentIndex == index;
    Color activeColor = Theme.of(context).colorScheme.primary;
    Color inactiveColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: screenWidth * 2 / 3,
          height: 65,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(context, Icons.calendar_today_outlined, "RDV", 0),
                _buildNavItem(
                    context, Icons.event_note_outlined, "Planning", 1),
                _buildNavItem(
                    context, Icons.location_on_outlined, "Localisation", 2),
                _buildNavItem(
                    context, Icons.settings_outlined, "Paramètres", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
