import 'package:flutter/material.dart';

class AnimalBackground extends StatelessWidget {
  const AnimalBackground({
    required this.asset,
    required this.child,
    this.scrim = const Color(0x3318382f),
    super.key,
  });

  final String asset;
  final Widget child;
  final Color scrim;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: Image.asset(asset, fit: BoxFit.cover)),
      Positioned.fill(child: ColoredBox(color: scrim)),
      child,
    ],
  );
}
