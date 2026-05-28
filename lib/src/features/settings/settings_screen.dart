import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_version.dart';
import '../../app/navigation_controller.dart';
import '../../catalog/catalog_models.dart';
import '../../providers/provider_models.dart';
import '../../providers/provider_repository.dart';
import '../../providers/refresh_interval.dart';
import '../../shared/async_value_view.dart';
import '../../shared/empty_state.dart';
import '../../updates/update_checker.dart';
import '../providers/provider_setup_screen.dart';

final providerHealthOverviewProvider =
    StreamProvider.autoDispose<List<ProviderHealth>>((ref) {
      return ref.watch(providerRepositoryProvider).watchProviderHealth();
    });

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providerHealthOverviewProvider);
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
              const SizedBox(height: 16),
              const _UpdateCard(),
              const SizedBox(height: 18),
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
                                      health: items[index],
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
          'Vela $velaVersion ($velaBuildNumber)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF8E8980),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _UpdateCard extends ConsumerWidget {
  const _UpdateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(updateStatusProvider);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151719),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: value.when(
          loading: () => _UpdateCardContent(
            icon: LucideIcons.loaderCircle,
            title: 'Checking for updates',
            message: 'Looking at the latest Vela release on GitHub.',
            trailing: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => _UpdateCardContent(
            icon: LucideIcons.cloudOff,
            title: 'Update check unavailable',
            message: error.toString(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Check again',
                  onPressed: () => ref.invalidate(updateStatusProvider),
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await openExternalUrl(velaReleasesUrl);
                  },
                  icon: const Icon(LucideIcons.externalLink, size: 17),
                  label: const Text('Releases'),
                ),
              ],
            ),
          ),
          data: (status) {
            final hasUpdate = status.hasUpdate;
            return _UpdateCardContent(
              icon: hasUpdate ? LucideIcons.sparkles : LucideIcons.checkCircle2,
              title: hasUpdate ? 'Update available' : 'Up to date',
              message: hasUpdate
                  ? 'Vela ${status.latestVersion} is available. Download and install it manually from GitHub.'
                  : 'Installed version ${status.currentVersion} is the latest GitHub release.',
              iconColor: hasUpdate
                  ? theme.colorScheme.primary
                  : const Color(0xFF8FB7B0),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Check again',
                    onPressed: () => ref.invalidate(updateStatusProvider),
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                  ),
                  if (hasUpdate) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await openExternalUrl(status.releaseUrl);
                      },
                      icon: const Icon(LucideIcons.download, size: 17),
                      label: const Text('Download'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UpdateCardContent extends StatelessWidget {
  const _UpdateCardContent({
    required this.icon,
    required this.title,
    required this.message,
    required this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFA9A39A),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        trailing,
      ],
    );
  }
}

class _ProviderSettingsRow extends ConsumerStatefulWidget {
  const _ProviderSettingsRow({required this.health});

  final ProviderHealth health;

  @override
  ConsumerState<_ProviderSettingsRow> createState() =>
      _ProviderSettingsRowState();
}

class _ProviderSettingsRowState extends ConsumerState<_ProviderSettingsRow> {
  late final TextEditingController _nameController;
  late int _refreshIntervalMinutes;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.health.provider.name);
    _refreshIntervalMinutes = supportedRefreshIntervalMinutes(
      widget.health.provider.refreshIntervalMinutes,
    );
  }

  @override
  void didUpdateWidget(covariant _ProviderSettingsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.health.provider.id != widget.health.provider.id ||
        oldWidget.health.provider.name != widget.health.provider.name) {
      _nameController.text = widget.health.provider.name;
    }
    if (oldWidget.health.provider.id != widget.health.provider.id ||
        oldWidget.health.provider.refreshIntervalMinutes !=
            widget.health.provider.refreshIntervalMinutes) {
      _refreshIntervalMinutes = supportedRefreshIntervalMinutes(
        widget.health.provider.refreshIntervalMinutes,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = widget.health;
    final provider = health.provider;
    final theme = Theme.of(context);
    final lastError =
        health.latestRefreshFailed &&
            provider.lastRefreshMessage?.trim().isNotEmpty == true
        ? provider.lastRefreshMessage!.trim()
        : null;

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
                _RefreshStatus(health: health),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  icon: health.isEnabled
                      ? LucideIcons.circleCheck
                      : LucideIcons.circleOff,
                  label: health.isEnabled ? 'Enabled' : 'Disabled',
                  color: health.isEnabled
                      ? const Color(0xFF8FB7B0)
                      : const Color(0xFF8E8980),
                ),
                _StatusPill(
                  icon: _providerIcon(provider.type),
                  label: _providerTypeLabel(provider.type),
                  color: const Color(0xFFA9A39A),
                ),
                _StatusPill(
                  icon: provider.refreshEnabled
                      ? LucideIcons.clock3
                      : LucideIcons.alarmClockOff,
                  label: provider.refreshEnabled
                      ? 'Auto refresh on'
                      : 'Auto refresh off',
                  color: provider.refreshEnabled
                      ? theme.colorScheme.primary
                      : const Color(0xFF8E8980),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CatalogStat(label: 'Live', count: health.stats.liveCount),
                _CatalogStat(label: 'Movies', count: health.stats.movieCount),
                _CatalogStat(label: 'Series', count: health.stats.seriesCount),
                _CatalogStat(
                  label: 'Episodes',
                  count: health.stats.episodeCount,
                ),
                _CatalogStat(label: 'EPG', count: health.stats.epgProgramCount),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _RefreshTime(
                    label: 'Last refresh',
                    value: _formatDateTime(provider.lastRefreshAt),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RefreshTime(
                    label: 'Next refresh',
                    value: provider.refreshEnabled
                        ? _formatMs(health.nextRefreshAtMs)
                        : 'Off',
                  ),
                ),
              ],
            ),
            if (lastError != null) ...[
              const SizedBox(height: 12),
              _ProviderError(message: lastError),
            ],
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
                  child: DropdownButtonFormField<int>(
                    initialValue: _refreshIntervalMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Refresh every',
                    ),
                    items: [
                      for (final option in refreshIntervalOptions)
                        DropdownMenuItem(
                          value: option.minutes,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _refreshIntervalMinutes = value);
                            }
                          },
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
                  label: const Text('Refresh Catalog'),
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
      await ref
          .read(providerRepositoryProvider)
          .updateProviderHealthSettings(
            providerId: widget.health.provider.id,
            name: _nameController.text,
            refreshEnabled: widget.health.provider.refreshEnabled,
            refreshIntervalMinutes: _refreshIntervalMinutes,
          );
    });
  }

  Future<void> _refresh() async {
    await _run('Refresh complete', () async {
      final result = await ref
          .read(providerRefreshServiceProvider)
          .refreshProvider(
            widget.health.provider.id,
            onProgress: (message) {
              if (mounted) {
                setState(() => _message = message);
              }
            },
          );
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
          .clearProviderCatalog(widget.health.provider.id);
    });
  }

  Future<void> _clearRecent() async {
    await _run('Provider recently watched cleared', () {
      return ref
          .read(watchHistoryRepositoryProvider)
          .clearRecentlyWatched(providerId: widget.health.provider.id);
    });
  }

  Future<void> _delete() async {
    await _run('Provider deleted', () {
      return ref
          .read(providerRepositoryProvider)
          .deleteProvider(widget.health.provider.id);
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
    final providerName = widget.health.provider.name;
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101214),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogStat extends StatelessWidget {
  const _CatalogStat({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101214),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NumberFormat.compact().format(count),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFA9A39A),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshTime extends StatelessWidget {
  const _RefreshTime({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF8E8980),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFE6E0D7),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ProviderError extends StatelessWidget {
  const _ProviderError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF241817),
        border: Border.all(color: const Color(0xFF5A2924)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              size: 16,
              color: Color(0xFFE26D5A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFE0B1A8),
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
  const _RefreshStatus({required this.health});

  final ProviderHealth health;

  @override
  Widget build(BuildContext context) {
    final provider = health.provider;
    final status = provider.lastRefreshStatus;
    final hasCatalog = health.hasImportedCatalog;
    final label = switch (status) {
      ProviderRefreshStatus.running => 'Checking',
      ProviderRefreshStatus.failed when hasCatalog => 'Valid, refresh failed',
      ProviderRefreshStatus.failed => 'Invalid',
      ProviderRefreshStatus.succeeded => 'Valid',
      null when hasCatalog => 'Valid',
      null => 'Not checked',
    };
    final color = switch (status) {
      ProviderRefreshStatus.running => const Color(0xFF8FB7B0),
      ProviderRefreshStatus.failed when !hasCatalog => const Color(0xFFE26D5A),
      _ when hasCatalog => Theme.of(context).colorScheme.primary,
      _ => const Color(0xFF8E8980),
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

String _providerTypeLabel(ProviderType type) {
  return switch (type) {
    ProviderType.xtream => 'Xtream',
    ProviderType.m3uUrl => 'M3U URL',
    ProviderType.m3uFile => 'M3U file',
  };
}

String _formatMs(int? value) {
  return value == null
      ? 'Not scheduled'
      : _formatDateTime(DateTime.fromMillisecondsSinceEpoch(value));
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Never';
  }
  return DateFormat('MMM d, h:mm a').format(value);
}
