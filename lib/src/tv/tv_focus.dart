import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusCard extends StatelessWidget {
  const TvFocusCard({
    required this.child,
    required this.onPressed,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onPressed?.call();
            return null;
          },
        ),
      },
      autofocus: autofocus,
      enabled: onPressed != null,
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Material(
            color: focused ? const Color(0xFF24272B) : const Color(0xFF151719),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: focused
                    ? theme.colorScheme.primary
                    : const Color(0xFF292D31),
                width: focused ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              canRequestFocus: false,
              child: Padding(padding: padding, child: child),
            ),
          );
        },
      ),
    );
  }
}

class TvSectionTitle extends StatelessWidget {
  const TvSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}
