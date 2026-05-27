import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../playback/playable_item.dart';
import '../playback/vela_player_route.dart';
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
          Expanded(
            child: _SectionPlaceholder(
              section: _selectedSection,
              onOpenPlayer: _openPlayer,
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayer(PlayableItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) {
          return VelaPlayerRoute(
            item: item,
            onClose: () => Navigator.of(routeContext).maybePop(),
          );
        },
      ),
    );
  }
}

class _SectionPlaceholder extends StatefulWidget {
  const _SectionPlaceholder({
    required this.section,
    required this.onOpenPlayer,
  });

  final VelaSection section;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  State<_SectionPlaceholder> createState() => _SectionPlaceholderState();
}

class _SectionPlaceholderState extends State<_SectionPlaceholder> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  bool get _hasStreamUrl => _urlController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onInputChanged);
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SectionPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final section = widget.section;

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
                          const SizedBox(height: 28),
                          _DeveloperPlaybackLauncher(
                            urlController: _urlController,
                            titleController: _titleController,
                            canOpen: _hasStreamUrl,
                            onOpen: _openPlayer,
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

  void _onInputChanged() => setState(() {});

  void _openPlayer() {
    final streamUrl = _urlController.text.trim();
    if (streamUrl.isEmpty) return;

    final title = _titleController.text.trim();
    widget.onOpenPlayer(
      PlayableItem(
        id: 'dev-${DateTime.now().microsecondsSinceEpoch}',
        title: title.isEmpty ? 'Sample Stream' : title,
        subtitle: 'Temporary playback spike',
        streamUrl: streamUrl,
        kind: _kindForSection(widget.section),
      ),
    );
  }

  PlayableKind _kindForSection(VelaSection section) {
    return switch (section) {
      VelaSection.movies => PlayableKind.movie,
      VelaSection.series => PlayableKind.episode,
      _ => PlayableKind.live,
    };
  }
}

class _DeveloperPlaybackLauncher extends StatelessWidget {
  const _DeveloperPlaybackLauncher({
    required this.urlController,
    required this.titleController,
    required this.canOpen,
    required this.onOpen,
  });

  final TextEditingController urlController;
  final TextEditingController titleController;
  final bool canOpen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101214),
        border: Border.all(color: const Color(0xFF34383C)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.monitorPlay,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Developer Playback Spike',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFF4F0E8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Legal stream or sample URL',
                hintText: 'https://example.com/sample.m3u8',
                prefixIcon: Icon(LucideIcons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (canOpen) onOpen();
              },
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Sample Stream',
                prefixIcon: Icon(LucideIcons.type),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: canOpen ? onOpen : null,
                icon: const Icon(LucideIcons.play, size: 18),
                label: const Text('Open Embedded Player'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
