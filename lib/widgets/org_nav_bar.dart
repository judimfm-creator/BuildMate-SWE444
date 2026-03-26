import 'package:flutter/material.dart';

class OrgNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const OrgNavBar({
    super.key, 
    required this.selectedIndex, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75, // الارتفاع الكلي للبار
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, 0),
          _navItem(Icons.campaign_outlined, 1),
          
          // زر الإضافة الدائري البرتقالي الكبير اللي تحبينه
          GestureDetector(
            onTap: () => onTap(2), // يفتح صفحة الإضافة
            child: Container(
              height: 55, // قطر الدائرة الكبيرة
              width: 55,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFA726), // اللون البرتقالي الجميل
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
          
          _navItem(Icons.groups_outlined, 3), // مراجعة الفرق
          _navItem(Icons.person_outline, 4), // الملف الشخصي
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        // لون البرتقالي حق BuildMate للمختار، ورمادي للبقية
        color: selectedIndex == index ? const Color(0xFFFFA726) : Colors.grey,
        size: 28, // حجم الأيقونات العادية
      ),
      onPressed: () => onTap(index),
    );
  }
}