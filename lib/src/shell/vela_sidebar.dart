import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/app_version.dart';
import '../app/section_state.dart';

const double velaSidebarCollapsedWidth = 72;
const double velaSidebarExpandedWidth = 232;
const double _sidebarHorizontalPadding = 12;
const double _sidebarIconSlotWidth = 48;

class VelaSidebar extends StatefulWidget {
  const VelaSidebar({
    required this.selectedSection,
    required this.onSectionSelected,
    this.hasProviders = true,
    super.key,
  });

  final VelaSection selectedSection;
  final ValueChanged<VelaSection> onSectionSelected;
  final bool hasProviders;

  @override
  State<VelaSidebar> createState() => _VelaSidebarState();
}

class _VelaSidebarState extends State<VelaSidebar> {
  bool _isHovered = false;
  bool _isPinned = false;

  bool get _isExpanded => _isPinned || _isHovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = _isExpanded
        ? velaSidebarExpandedWidth
        : velaSidebarCollapsedWidth;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        width: width,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: const BoxDecoration(
          color: Color(0xFF0F1012),
          border: Border(right: BorderSide(color: Color(0xFF292D31))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: _sidebarHorizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SidebarHeader(
                  isExpanded: _isExpanded,
                  isPinned: _isPinned,
                  onPinPressed: () {
                    setState(() => _isPinned = !_isPinned);
                  },
                ),
                const SizedBox(height: 24),
                for (final section in VelaSection.values) ...[
                  _SidebarItem(
                    section: section,
                    isExpanded: _isExpanded,
                    isSelected: section == widget.selectedSection,
                    isEnabled:
                        widget.hasProviders || section == VelaSection.live,
                    onPressed: () => widget.onSectionSelected(section),
                  ),
                  if (section == VelaSection.recent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: theme.dividerColor),
                    ),
                ],
                const Spacer(),
                AnimatedOpacity(
                  opacity: _isExpanded ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: Text(
                    'Vela $velaVersion',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF716D66),
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.isExpanded,
    required this.isPinned,
    required this.onPinPressed,
  });

  final bool isExpanded;
  final bool isPinned;
  final VoidCallback onPinPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowAction = constraints.maxWidth >= 128;
        final iconSlotWidth = constraints.maxWidth < _sidebarIconSlotWidth
            ? constraints.maxWidth
            : _sidebarIconSlotWidth;

        return SizedBox(
          height: 40,
          child: Row(
            children: [
              SizedBox(
                width: iconSlotWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'V',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0C0D0E),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isExpanded && canShowAction ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Vela',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              if (canShowAction)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IgnorePointer(
                    ignoring: !isExpanded,
                    child: AnimatedOpacity(
                      opacity: isExpanded ? 1 : 0,
                      duration: const Duration(milliseconds: 120),
                      child: IconButton(
                        tooltip: isPinned ? 'Unpin sidebar' : 'Pin sidebar',
                        onPressed: onPinPressed,
                        icon: Icon(
                          isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.isExpanded,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
  });

  final VelaSection section;
  final bool isExpanded;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = !isEnabled
        ? const Color(0xFF5D5A54)
        : isSelected
        ? theme.colorScheme.primary
        : const Color(0xFFD7D0C6);
    final background = isSelected && isEnabled
        ? const Color(0xFF25211A)
        : Colors.transparent;
    final tooltip = isEnabled || isExpanded
        ? section.label
        : '${section.label} requires a provider';

    return Tooltip(
      message: isExpanded && isEnabled ? '' : tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: _sidebarIconSlotWidth,
                    child: Icon(section.icon, color: foreground, size: 21),
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: isExpanded ? 1 : 0,
                      duration: const Duration(milliseconds: 120),
                      child: Text(
                        section.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
