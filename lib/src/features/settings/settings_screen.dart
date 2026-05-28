import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_version.dart';
import '../../app/navigation_controller.dart';
import '../../backup/backup_service.dart';
import '../../catalog/catalog_models.dart';
import '../../diagnostics/diagnostics_exporter.dart';
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

final providerDetailsProvider = StreamProvider.autoDispose
    .family<IptvProvider?, String>((ref, providerId) {
      return ref.watch(providerRepositoryProvider).watchProvider(providerId);
    });

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _selectedProviderId;
  bool _isAddingProvider = false;

  @override
  Widget build(BuildContext context) {
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
                    final selectedHealth = _selectedHealth(items);
                    final showAddProvider =
                        items.isEmpty ||
                        _isAddingProvider ||
                        selectedHealth == null;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 390,
                          child: _ProviderManagementList(
                            providers: items,
                            selectedProviderId: showAddProvider
                                ? null
                                : selectedHealth.provider.id,
                            isAddingProvider: showAddProvider,
                            onAddProvider: () {
                              setState(() => _isAddingProvider = true);
                            },
                            onSelectProvider: (providerId) {
                              setState(() {
                                _selectedProviderId = providerId;
                                _isAddingProvider = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: ListView(
                            children: [
                              if (showAddProvider)
                                const ProviderSetupScreen(embedded: true)
                              else
                                _ProviderEditorPanel(
                                  providerId: selectedHealth.provider.id,
                                  health: selectedHealth,
                                ),
                              const SizedBox(height: 14),
                              _SettingsOperationsGrid(settings: settings),
                            ],
                          ),
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

  ProviderHealth? _selectedHealth(List<ProviderHealth> items) {
    if (items.isEmpty) return null;
    final selectedId = _selectedProviderId;
    if (selectedId != null) {
      for (final item in items) {
        if (item.provider.id == selectedId) {
          return item;
        }
      }
    }
    return items.first;
  }
}

class _ProviderManagementList extends StatelessWidget {
  const _ProviderManagementList({
    required this.providers,
    required this.selectedProviderId,
    required this.isAddingProvider,
    required this.onAddProvider,
    required this.onSelectProvider,
  });

  final List<ProviderHealth> providers;
  final String? selectedProviderId;
  final bool isAddingProvider;
  final VoidCallback onAddProvider;
  final ValueChanged<String> onSelectProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151719),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.server, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Providers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Add provider',
                  onPressed: onAddProvider,
                  icon: const Icon(LucideIcons.plus, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AddProviderListItem(
              selected: isAddingProvider,
              onTap: onAddProvider,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: providers.isEmpty
                  ? const _ProviderListEmpty()
                  : ListView.separated(
                      itemBuilder: (context, index) {
                        final health = providers[index];
                        return _ProviderListItem(
                          health: health,
                          selected: health.provider.id == selectedProviderId,
                          onTap: () => onSelectProvider(health.provider.id),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemCount: providers.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProviderListItem extends StatelessWidget {
  const _AddProviderListItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SelectableProviderTile(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(LucideIcons.radioTower, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add provider',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          const Icon(LucideIcons.plus, size: 17),
        ],
      ),
    );
  }
}

class _ProviderListItem extends StatelessWidget {
  const _ProviderListItem({
    required this.health,
    required this.selected,
    required this.onTap,
  });

  final ProviderHealth health;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = health.provider;
    final statusColor = health.latestRefreshFailed
        ? const Color(0xFFE26D5A)
        : health.hasImportedCatalog
        ? theme.colorScheme.primary
        : const Color(0xFF8E8980);

    return _SelectableProviderTile(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_providerIcon(provider.type), color: statusColor, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _providerTypeLabel(provider.type),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFA9A39A),
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF5D5A54),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _providerListStatus(health),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${NumberFormat.compact().format(health.stats.liveCount)} live  '
            '${NumberFormat.compact().format(health.stats.movieCount)} movies  '
            '${NumberFormat.compact().format(health.stats.seriesCount)} series',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF8E8980),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableProviderTile extends StatelessWidget {
  const _SelectableProviderTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2A2416) : const Color(0xFF101214),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF292D31),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }
}

class _ProviderListEmpty extends StatelessWidget {
  const _ProviderListEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No providers yet',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF8E8980),
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ProviderEditorPanel extends ConsumerStatefulWidget {
  const _ProviderEditorPanel({required this.providerId, required this.health});

  final String providerId;
  final ProviderHealth health;

  @override
  ConsumerState<_ProviderEditorPanel> createState() =>
      _ProviderEditorPanelState();
}

class _ProviderEditorPanelState extends ConsumerState<_ProviderEditorPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _fileController = TextEditingController();
  String? _loadedProviderId;
  bool _isEnabled = true;
  bool _refreshEnabled = true;
  int _refreshIntervalMinutes = defaultRefreshIntervalMinutes;
  bool _busy = false;
  String? _message;

  @override
  void didUpdateWidget(covariant _ProviderEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId != widget.providerId) {
      _loadedProviderId = null;
      _message = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uUrlController.dispose();
    _fileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerValue = ref.watch(providerDetailsProvider(widget.providerId));
    return providerValue.when(
      loading: () => const _SettingsPanel(
        child: SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) =>
          _SettingsPanel(child: _ProviderError(message: error.toString())),
      data: (provider) {
        if (provider == null) {
          return const _SettingsPanel(
            child: EmptyState(
              icon: LucideIcons.serverOff,
              title: 'Provider not found',
              message: 'This provider was deleted or is no longer available.',
            ),
          );
        }
        _syncProvider(provider);
        return _buildEditor(context, provider);
      },
    );
  }

  Widget _buildEditor(BuildContext context, IptvProvider provider) {
    final theme = Theme.of(context);
    final health = widget.health;

    return _SettingsPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _providerIcon(provider.type),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Edit ${_providerTypeLabel(provider.type)} provider',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFA9A39A),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                _RefreshStatus(health: health),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  icon: _isEnabled
                      ? LucideIcons.circleCheck
                      : LucideIcons.circleOff,
                  label: _isEnabled ? 'Enabled' : 'Disabled',
                  color: _isEnabled
                      ? const Color(0xFF8FB7B0)
                      : const Color(0xFF8E8980),
                ),
                _StatusPill(
                  icon: _refreshEnabled
                      ? LucideIcons.clock3
                      : LucideIcons.alarmClockOff,
                  label: _refreshEnabled
                      ? 'Auto refresh on'
                      : 'Auto refresh off',
                  color: _refreshEnabled
                      ? theme.colorScheme.primary
                      : const Color(0xFF8E8980),
                ),
                _StatusPill(
                  icon: _providerIcon(provider.type),
                  label: _providerTypeLabel(provider.type),
                  color: const Color(0xFFA9A39A),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RefreshTime(
                    label: 'Last refresh',
                    value: _formatDateTime(provider.lastRefreshAt),
                  ),
                ),
                const SizedBox(width: 14),
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
            if (provider.lastRefreshMessage?.trim().isNotEmpty == true &&
                health.latestRefreshFailed) ...[
              const SizedBox(height: 14),
              _ProviderError(message: provider.lastRefreshMessage!.trim()),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Provider name',
                prefixIcon: Icon(LucideIcons.tag),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            ..._sourceFields(provider),
            const SizedBox(height: 14),
            _SwitchRow(
              icon: LucideIcons.power,
              title: 'Provider enabled',
              subtitle: _isEnabled
                  ? 'Provider appears in the app and can refresh.'
                  : 'Provider stays saved but will not auto-refresh.',
              value: _isEnabled,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _isEnabled = value),
            ),
            const SizedBox(height: 10),
            _SwitchRow(
              icon: LucideIcons.clock3,
              title: 'Auto-refresh catalog',
              subtitle: 'Refresh this provider in the background.',
              value: _refreshEnabled,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _refreshEnabled = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _refreshIntervalMinutes,
              decoration: const InputDecoration(
                labelText: 'Auto-refresh interval',
                prefixIcon: Icon(LucideIcons.clock),
              ),
              items: [
                for (final option in refreshIntervalOptions)
                  DropdownMenuItem(
                    value: option.minutes,
                    child: Text(option.label),
                  ),
              ],
              onChanged: !_refreshEnabled || _busy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _refreshIntervalMinutes = value);
                      }
                    },
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _save(provider),
                  icon: const Icon(LucideIcons.save, size: 18),
                  label: const Text('Save changes'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _save(provider, refresh: true),
                  icon: const Icon(LucideIcons.refreshCw, size: 17),
                  label: const Text('Save and refresh'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(LucideIcons.rotateCw, size: 17),
                  label: const Text('Refresh now'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearCatalog,
                  icon: const Icon(LucideIcons.databaseZap, size: 17),
                  label: const Text('Clear catalog'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearRecent,
                  icon: const Icon(LucideIcons.history, size: 17),
                  label: const Text('Clear recent'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(LucideIcons.trash2, size: 17),
                  label: const Text('Delete'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _sourceFields(IptvProvider provider) {
    return switch (provider.type) {
      ProviderType.xtream => [
        TextFormField(
          controller: _serverController,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            prefixIcon: Icon(LucideIcons.server),
          ),
          keyboardType: TextInputType.url,
          validator: _required,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(LucideIcons.user),
                ),
                validator: _required,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(LucideIcons.keyRound),
                ),
                obscureText: true,
                validator: _required,
              ),
            ),
          ],
        ),
      ],
      ProviderType.m3uUrl => [
        TextFormField(
          controller: _m3uUrlController,
          decoration: const InputDecoration(
            labelText: 'M3U URL',
            prefixIcon: Icon(LucideIcons.link),
          ),
          keyboardType: TextInputType.url,
          validator: _required,
        ),
      ],
      ProviderType.m3uFile => [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fileController,
                decoration: const InputDecoration(
                  labelText: 'Local M3U file',
                  prefixIcon: Icon(LucideIcons.fileVideo),
                ),
                readOnly: true,
                validator: _required,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(LucideIcons.folderOpen, size: 18),
              label: const Text('Choose'),
            ),
          ],
        ),
      ],
    };
  }

  void _syncProvider(IptvProvider provider) {
    if (_loadedProviderId == provider.id) return;
    _loadedProviderId = provider.id;
    _nameController.text = provider.name;
    _serverController.text = provider.serverUrl ?? '';
    _usernameController.text = provider.username ?? '';
    _passwordController.text = provider.password ?? '';
    _m3uUrlController.text = provider.m3uUrl ?? '';
    _fileController.text = provider.localFilePath ?? '';
    _isEnabled = provider.isEnabled;
    _refreshEnabled = provider.refreshEnabled;
    _refreshIntervalMinutes = supportedRefreshIntervalMinutes(
      provider.refreshIntervalMinutes,
    );
  }

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'M3U playlists',
      extensions: ['m3u', 'm3u8', 'txt'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    setState(() => _fileController.text = file.path);
  }

  Future<void> _save(IptvProvider provider, {bool refresh = false}) async {
    if (!_formKey.currentState!.validate()) return;
    await _run(
      refresh ? 'Provider saved and refreshed' : 'Provider saved',
      () async {
        await ref
            .read(providerRepositoryProvider)
            .createOrUpdateProvider(_inputFor(provider));
        if (!refresh) return;
        final result = await ref
            .read(providerRefreshServiceProvider)
            .refreshProvider(provider.id);
        if (result.status == ProviderRefreshStatus.failed) {
          throw ProviderRefreshFailure(result.message ?? 'Refresh failed');
        }
      },
    );
  }

  Future<void> _refresh() async {
    await _run('Refresh complete', () async {
      final result = await ref
          .read(providerRefreshServiceProvider)
          .refreshProvider(widget.providerId);
      if (result.status == ProviderRefreshStatus.failed) {
        throw ProviderRefreshFailure(result.message ?? 'Refresh failed');
      }
    });
  }

  Future<void> _clearCatalog() async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Clear provider catalog?',
      message:
          'This clears imported catalog, EPG, favorites, category order, recently watched history, and playback progress for this provider.',
      confirmLabel: 'Clear catalog',
    );
    if (!mounted || !confirmed) return;
    await _run('Provider catalog cleared', () {
      return ref
          .read(providerRepositoryProvider)
          .clearProviderCatalog(widget.providerId);
    });
  }

  Future<void> _clearRecent() async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Clear provider recently watched?',
      message:
          'This deletes recently watched history and playback progress for this provider. Provider configuration and catalog data are kept.',
      confirmLabel: 'Clear recent',
    );
    if (!mounted || !confirmed) return;
    await _run('Provider recently watched cleared', () {
      return ref
          .read(watchHistoryRepositoryProvider)
          .clearRecentlyWatched(providerId: widget.providerId);
    });
  }

  Future<void> _delete() async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Delete provider?',
      message:
          'This deletes this provider, credentials, catalog, EPG, favorites, category order, recently watched history, playback progress, and refresh records.',
      confirmLabel: 'Delete provider',
    );
    if (!mounted || !confirmed) return;
    await _run('Provider deleted', () {
      return ref
          .read(providerRepositoryProvider)
          .deleteProvider(widget.providerId);
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

  ProviderInput _inputFor(IptvProvider provider) {
    return ProviderInput(
      id: provider.id,
      name: _nameController.text,
      type: provider.type,
      serverUrl: provider.type == ProviderType.xtream
          ? _serverController.text
          : null,
      username: provider.type == ProviderType.xtream
          ? _usernameController.text
          : null,
      password: provider.type == ProviderType.xtream
          ? _passwordController.text
          : null,
      m3uUrl: provider.type == ProviderType.m3uUrl
          ? _m3uUrlController.text
          : null,
      localFilePath: provider.type == ProviderType.m3uFile
          ? _fileController.text
          : null,
      isEnabled: _isEnabled,
      refreshEnabled: _refreshEnabled,
      refreshIntervalMinutes: _refreshIntervalMinutes,
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

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
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8E8980),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _SettingsOperationsGrid extends StatelessWidget {
  const _SettingsOperationsGrid({required this.settings});

  final AsyncValue<Map<String, String>> settings;

  @override
  Widget build(BuildContext context) {
    return _DataDiagnosticsCard(settings: settings);
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151719),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _DataDiagnosticsCard extends ConsumerStatefulWidget {
  const _DataDiagnosticsCard({required this.settings});

  final AsyncValue<Map<String, String>> settings;

  @override
  ConsumerState<_DataDiagnosticsCard> createState() =>
      _DataDiagnosticsCardState();
}

class _DataDiagnosticsCardState extends ConsumerState<_DataDiagnosticsCard> {
  bool _busy = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
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
                Icon(LucideIcons.database, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Data & diagnostics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _exportDiagnostics,
                  icon: const Icon(LucideIcons.fileText, size: 17),
                  label: const Text('Export diagnostics'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _exportBackup,
                  icon: const Icon(LucideIcons.archive, size: 17),
                  label: const Text('Export backup'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearHistory,
                  icon: const Icon(LucideIcons.history, size: 17),
                  label: const Text('Clear history'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearCatalogCache,
                  icon: const Icon(LucideIcons.databaseZap, size: 17),
                  label: const Text('Clear catalog cache'),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _resetAppData,
                  icon: const Icon(LucideIcons.trash2, size: 17),
                  label: const Text('Reset app data'),
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

  Future<void> _exportDiagnostics() async {
    await _run((setMessage) async {
      final updateValue = ref.read(updateStatusProvider);
      UpdateStatus? status;
      Object? updateError;
      var updateLoading = false;
      updateValue.when(
        data: (value) => status = value,
        error: (error, _) => updateError = error,
        loading: () => updateLoading = true,
      );
      final path =
          await DiagnosticsExporter(
            catalogRepository: ref.read(catalogRepositoryProvider),
            watchHistoryRepository: ref.read(watchHistoryRepositoryProvider),
          ).export(
            appSettings: widget.settings.value,
            updateStatus: status,
            updateError: updateError,
            updateLoading: updateLoading,
          );
      setMessage(path == null ? 'Diagnostics export canceled' : 'Saved $path');
    });
  }

  Future<void> _exportBackup() async {
    await _run((setMessage) async {
      final path = await BackupService(
        catalogRepository: ref.read(catalogRepositoryProvider),
        watchHistoryRepository: ref.read(watchHistoryRepositoryProvider),
      ).export(appSettings: widget.settings.value);
      setMessage(path == null ? 'Backup export canceled' : 'Saved $path');
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Clear recently watched and progress?',
      message:
          'This deletes recently watched history and playback progress for all '
          'providers. Providers, catalog data, favorites, category order, and '
          'app settings are kept.',
      confirmLabel: 'Clear history',
    );
    if (!mounted || !confirmed) return;

    await _run((setMessage) async {
      await ref.read(watchHistoryRepositoryProvider).clearRecentlyWatched();
      setMessage('Recently watched and playback progress cleared');
    });
  }

  Future<void> _clearCatalogCache() async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Clear provider catalog cache?',
      message:
          'This deletes imported live, movie, series, episode, EPG catalog '
          'cache, and refresh run records for all providers. Providers, '
          'favorites, category order, recently watched history, playback '
          'progress, and app settings are kept.',
      confirmLabel: 'Clear catalog cache',
    );
    if (!mounted || !confirmed) return;

    await _run((setMessage) async {
      await ref.read(catalogRepositoryProvider).clearCatalogCache();
      setMessage('Provider catalog cache cleared');
    });
  }

  Future<void> _resetAppData() async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Reset all app data?',
      message:
          'This deletes provider configurations and credentials, imported '
          'catalog data, EPG data, favorites, category order, recently watched '
          'history, playback progress, refresh records, and app settings.',
      confirmLabel: 'Reset app data',
    );
    if (!mounted || !confirmed) return;

    await _run((setMessage) async {
      await ref.read(catalogRepositoryProvider).clearAllAppData();
      setMessage('All app data reset');
    });
  }

  Future<void> _run(
    Future<void> Function(void Function(String message) setMessage) action,
  ) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action((message) {
        if (mounted) {
          setState(() => _message = message);
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
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

String _providerListStatus(ProviderHealth health) {
  if (!health.isEnabled) {
    return 'Disabled';
  }
  if (health.latestRefreshFailed) {
    return health.hasImportedCatalog
        ? 'Catalog valid, refresh failed'
        : 'Invalid';
  }
  if (health.hasImportedCatalog) {
    return 'Catalog ready';
  }
  return 'Not imported';
}

Future<bool> _confirmAction({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
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
