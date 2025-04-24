import 'package:flutter/material.dart';

class InvalidDropTargetOverlay extends StatelessWidget {
  const InvalidDropTargetOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: ColoredBox(color: Color(0x4D000000), child: Placeholder()),
    );
  }
}
