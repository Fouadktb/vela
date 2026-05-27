import 'package:flutter/material.dart';

import 'vela_sidebar.dart';

class VelaShell extends StatefulWidget {
  const VelaShell({super.key});

  @override
  State<VelaShell> createState() => _VelaShellState();
}

class _VelaShellState extends State<VelaShell> {
  VelaSection _selectedSection = VelaSection.live;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          VelaSidebar(
            selectedSection: _selectedSection,
            onSectionSelected: (section) {
              setState(() => _selectedSection = section);
            },
          ),
          Expanded(child: _SectionPlaceholder(section: _selectedSection)),
        ],
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.section});

  final VelaSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0C0D0E)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.label, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Foundation placeholder for the ${section.label.toLowerCase()} experience.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFA9A39A),
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151719),
                    border: Border.all(color: const Color(0xFF292D31)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            section.placeholderIcon,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            section.emptyTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            section.emptyCopy,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
