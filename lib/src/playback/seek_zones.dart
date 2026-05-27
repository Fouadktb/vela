import 'package:flutter/material.dart';

enum SeekZoneDirection { backward, forward }

class SeekZones extends StatelessWidget {
  const SeekZones({required this.onSeek, this.onInteraction, super.key});

  final ValueChanged<SeekZoneDirection> onSeek;
  final VoidCallback? onInteraction;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (_) => onInteraction?.call(),
            onDoubleTapDown: (details) {
              final isLeft =
                  details.localPosition.dx < constraints.maxWidth / 2;
              onSeek(
                isLeft ? SeekZoneDirection.backward : SeekZoneDirection.forward,
              );
            },
          );
        },
      ),
    );
  }
}
