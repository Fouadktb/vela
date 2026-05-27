import 'package:flutter/material.dart';

enum SeekZoneDirection { backward, forward }

class SeekZones extends StatelessWidget {
  const SeekZones({
    required this.onSeek,
    required this.onCenterDoubleTap,
    this.onInteraction,
    super.key,
  });

  final ValueChanged<SeekZoneDirection> onSeek;
  final VoidCallback onCenterDoubleTap;
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
              final x = details.localPosition.dx;
              final zoneWidth = constraints.maxWidth / 3;
              if (x < zoneWidth) {
                onSeek(SeekZoneDirection.backward);
                return;
              }
              if (x > zoneWidth * 2) {
                onSeek(SeekZoneDirection.forward);
                return;
              }
              onCenterDoubleTap();
            },
          );
        },
      ),
    );
  }
}
