import 'package:flutter/material.dart';

class OrgNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const OrgNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, 0),
          _navItem(Icons.campaign_outlined, 1),
          GestureDetector(
            onTap: () => onTap(2),
            child: Container(
              height: 55,
              width: 55,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFA726),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          _navItem(Icons.pending_actions_outlined, 3),
          _navItem(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final bool isSelected = selectedIndex == index;

    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFFFFA726) : Colors.grey,
        size: 28,
      ),
      onPressed: () => onTap(index),
    );
  }
}