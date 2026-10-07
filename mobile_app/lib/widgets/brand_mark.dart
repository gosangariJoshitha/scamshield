import 'package:flutter/material.dart';

class ScamShieldBrandMark extends StatelessWidget {
  const ScamShieldBrandMark({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/scamshield_launcher.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'ScamShield app icon',
    );
  }
}
