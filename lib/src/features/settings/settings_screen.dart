import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/navigation_controller.dart';
import '../../catalog/catalog_models.dart';
import '../../providers/provider_models.dart';
import '../../shared/async_value_view.dart';
import '../../shared/empty_state.dart';
import '../providers/provider_setup_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providersProvider);
    final settings = ref.watch(appSettingsProvider);

    return ColoredBox(
      color: const Color(0xFF0C0D0E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 26, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsHeader(settings: settings),
              const SizedBox(height: 22),
              Expanded(
                child: AsyncValueView(
                  value: providers,
                  data: (items) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: items.isEmpty
                              ? const EmptyState(
                                  icon: LucideIcons.serverOff,
                                  title: 'No providers configured',
                                  message:
                                      'Add an Xtream Codes provider, M3U URL, or local playlist.',
                                )
                              : ListView.separated(
                                  itemBuilder: (context, index) {
                                    return _ProviderSettingsRow(
                                      provider: items[index],
                                    );
                                  },
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemCount: items.length,
                                ),
                        ),
                        const SizedBox(width: 18),
                        const SizedBox(
                          width: 430,
                          child: ProviderSetupScreen(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends ConsumerWidget {
  const _SettingsHeader({required this.settings});

  final AsyncValue<Map<String, String>> settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audio = settings.value?['default_audio'] ?? 'Auto';
    final subtitles = settings.value?['default_subtitles'] ?? 'Off';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferences',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        _PreferenceMenu(
          label: 'Audio',
          value: audio,
          values: const ['Auto', 'Original', 'English'],
          onSelected: (value) {
            ref
                .read(appSettingsRepositoryProvider)
                .setValue('default_audio', value);
          },
        ),
        const SizedBox(width: 10),
        _PreferenceMenu(
          label: 'Subtitles',
          value: subtitles,
          values: const ['Off', 'Auto', 'English'],
          onSelected: (value) {
            ref
                .read(appSettingsRepositoryProvider)
                .setValue('default_subtitles', value);
          },
        ),
        const SizedBox(width: 14),
        Text(
          'Vela 0.2.0 (1)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF8E8980),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ProviderSettingsRow extends ConsumerStatefulWidget {
  const _ProviderSettingsRow({required this.provider});

  final IptvProvider provider;

  @override
  ConsumerState<_ProviderSettingsRow> createState() =>
      _ProviderSettingsRowState();
}

class _ProviderSettingsRowState extends ConsumerState<_ProviderSettingsRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _intervalController;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider.name);
    _intervalController = TextEditingController(
      text: widget.provider.refreshIntervalMinutes.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _ProviderSettingsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.id != widget.provider.id) {
      _nameController.text = widget.provider.name;
      _intervalController.text = widget.provider.refreshIntervalMinutes
          .toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151719),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _providerIcon(provider.type),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _RefreshStatus(provider: provider),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Interval minutes',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(LucideIcons.save, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(LucideIcons.refreshCw, size: 17),
                  label: const Text('Refresh'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearCatalog,
                  icon: const Icon(LucideIcons.databaseZap, size: 17),
                  label: const Text('Clear Catalog'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearRecent,
                  icon: const Icon(LucideIcons.history, size: 17),
                  label: const Text('Clear Recent'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(LucideIcons.trash2, size: 17),
                  label: const Text('Delete'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await _run('Saved provider settings', () async {
      final interval =
          int.tryParse(_intervalController.text.trim()) ??
          widget.provider.refreshIntervalMinutes;
      await ref
          .read(providerRepositoryProvider)
          .createOrUpdateProvider(
            ProviderInput(
              id: widget.provider.id,
              name: _nameController.text,
              type: widget.provider.type,
              serverUrl: widget.provider.serverUrl,
              username: widget.provider.username,
              password: widget.provider.password,
              m3uUrl: widget.provider.m3uUrl,
              localFilePath: widget.provider.localFilePath,
              refreshEnabled: widget.provider.refreshEnabled,
              refreshIntervalMinutes: interval,
            ),
          );
    });
  }

  Future<void> _refresh() async {
    await _run('Refresh complete', () async {
      final result = await ref
          .read(providerRefreshServiceProvider)
          .refreshProvider(widget.provider.id);
      if (result.status == ProviderRefreshStatus.failed) {
        throw ProviderRefreshFailure(result.message ?? 'Refresh failed');
      }
    });
  }

  Future<void> _clearCatalog() async {
    final confirmed = await _confirmClearCatalog();
    if (!mounted || !confirmed) return;

    await _run('Provider catalog cleared', () {
      return ref
          .read(providerRepositoryProvider)
          .clearProviderCatalog(widget.provider.id);
    });
  }

  Future<void> _clearRecent() async {
    await _run('Provider recently watched cleared', () {
      return ref
          .read(watchHistoryRepositoryProvider)
          .clearRecentlyWatched(providerId: widget.provider.id);
    });
  }

  Future<void> _delete() async {
    await _run('Provider deleted', () {
      return ref
          .read(providerRepositoryProvider)
          .deleteProvider(widget.provider.id);
    });
  }

  Future<void> _run(String success, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _message = success);
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirmClearCatalog() async {
    final providerName = widget.provider.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear provider catalog?'),
          content: Text(
            'This clears the catalog for "$providerName" plus related '
            'favorites, category order, recently watched history, and '
            'playback progress for this provider.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear Catalog'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}

class _PreferenceMenu extends StatelessWidget {
  const _PreferenceMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.onSelected,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      width: 150,
      label: Text(label),
      initialSelection: value,
      onSelected: (value) {
        if (value != null) onSelected(value);
      },
      dropdownMenuEntries: [
        for (final item in values) DropdownMenuEntry(value: item, label: item),
      ],
    );
  }
}

class _RefreshStatus extends StatelessWidget {
  const _RefreshStatus({required this.provider});

  final IptvProvider provider;

  @override
  Widget build(BuildContext context) {
    final status = provider.lastRefreshStatus;
    final label = status == null ? 'Never refreshed' : status.name;
    final color = switch (status) {
      ProviderRefreshStatus.succeeded => Theme.of(context).colorScheme.primary,
      ProviderRefreshStatus.failed => const Color(0xFFE26D5A),
      ProviderRefreshStatus.running => const Color(0xFF8FB7B0),
      null => const Color(0xFF8E8980),
    };

    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

IconData _providerIcon(ProviderType type) {
  return switch (type) {
    ProviderType.xtream => LucideIcons.server,
    ProviderType.m3uUrl => LucideIcons.link,
    ProviderType.m3uFile => LucideIcons.fileVideo,
  };
}
