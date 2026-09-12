import 'package:flutter/material.dart';

class SmartLogo extends StatelessWidget {
  const SmartLogo({
    super.key,
    this.size = 96,
    this.background = Colors.white,
  });

  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/smart_kantin_logo_circle.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
