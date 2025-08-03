import 'package:flutter/material.dart';

BottomAppBar buildBottomAppBar({
  required int selectedIndex,
  required Function(int) onItemTapped,
}) {
  return BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8.0,
    child: Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
              _buildNavItem(
                icon: Icons.bar_chart,
                label: 'Stats',
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
            ],
          ),
        ),
        const SizedBox(width: 48), // Space for FAB in center
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.play_arrow, // Triangle play icon
                label: 'Shorts',
                index: 2, // Corrected index for Shorts
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
              _buildNavItem(
                icon: Icons.more_horiz,
                label: 'More',
                index: 3, // Corrected index for More
                selectedIndex: selectedIndex,
                onTap: onItemTapped,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildNavItem({
  required IconData icon,
  required String label,
  required int index,
  required int selectedIndex,
  required Function(int) onTap,
}) {
  final isSelected = selectedIndex == index;
  return GestureDetector(
    onTap: () => onTap(index),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}
