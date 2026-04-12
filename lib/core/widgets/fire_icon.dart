import 'package:flutter/material.dart';

/// Custom fire/calories icon using the line art asset.
/// Use this instead of Icons.local_fire_department for calories.
class FireIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const FireIcon({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/fire-logo-calories.png',
      width: size,
      height: size,
      color: color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
    );
  }
}
