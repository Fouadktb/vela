import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../catalog/catalog_models.dart';
import '../features/providers/provider_setup_screen.dart';
import '../providers/provider_models.dart';
import '../providers/provider_repository.dart';
import '../providers/refresh_interval.dart';
import 'tv_focus.dart';

class TvProviderSetupScreen extends ConsumerStatefulWidget {
  const TvProviderSetupScreen({super.key});

  @override
  ConsumerState<TvProviderSetupScreen> createState() =>
      _TvProviderSetupScreenState();
}

class _TvProviderSetupScreenState extends ConsumerState<TvProviderSetupScreen> {
  var _type = ProviderType.xtream;
  var _name = 'Primary IPTV';
  var _serverUrl = '';
  var _username = '';
  var _password = '';
  var _m3uUrl = '';
  var _refreshIntervalMinutes = defaultRefreshIntervalMinutes;
  String? _validationMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final importState = ref.watch(providerSetupImportControllerProvider);
    final isImporting = importState.isImporting;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF151719),
              border: Border.all(color: const Color(0xFF292D31)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: FocusTraversalGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.radioTower,
                          color: theme.colorScheme.primary,
                          size: 34,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Add Provider',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ProviderTypePicker(
                      selectedType: _type,
                      isImporting: isImporting,
                      onChanged: (type) {
                        setState(() {
                          _type = type;
                          _validationMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _TvValueField(
                      label: 'Provider name',
                      value: _name,
                      icon: LucideIcons.tag,
                      autofocus: true,
                      enabled: !isImporting,
                      error: _fieldError(_name),
                      onPressed: () => _editText(
                        title: 'Provider name',
                        value: _name,
                        onChanged: (value) => setState(() => _name = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_type == ProviderType.xtream) ...[
                      _TvValueField(
                        label: 'Server URL',
                        value: _serverUrl,
                        placeholder: 'https://example.com',
                        icon: LucideIcons.server,
                        keyboardType: TextInputType.url,
                        enabled: !isImporting,
                        error: _fieldError(_serverUrl),
                        onPressed: () => _editText(
                          title: 'Server URL',
                          value: _serverUrl,
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            setState(() => _serverUrl = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ResponsivePair(
                        children: [
                          _TvValueField(
                            label: 'Username',
                            value: _username,
                            icon: LucideIcons.user,
                            enabled: !isImporting,
                            error: _fieldError(_username),
                            onPressed: () => _editText(
                              title: 'Username',
                              value: _username,
                              onChanged: (value) {
                                setState(() => _username = value);
                              },
                            ),
                          ),
                          _TvValueField(
                            label: 'Password',
                            value: _password,
                            icon: LucideIcons.keyRound,
                            obscure: true,
                            enabled: !isImporting,
                            error: _fieldError(_password),
                            onPressed: () => _editText(
                              title: 'Password',
                              value: _password,
                              obscure: true,
                              onChanged: (value) {
                                setState(() => _password = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_type == ProviderType.m3uUrl)
                      _TvValueField(
                        label: 'M3U URL',
                        value: _m3uUrl,
                        placeholder: 'https://example.com/playlist.m3u',
                        icon: LucideIcons.link,
                        keyboardType: TextInputType.url,
                        enabled: !isImporting,
                        error: _fieldError(_m3uUrl),
                        onPressed: () => _editText(
                          title: 'M3U URL',
                          value: _m3uUrl,
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            setState(() => _m3uUrl = value);
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    _TvValueField(
                      label: 'Auto-refresh interval',
                      value: refreshIntervalLabel(_refreshIntervalMinutes),
                      icon: LucideIcons.clock,
                      enabled: !isImporting,
                      trailingIcon: LucideIcons.chevronDown,
                      onPressed: _pickRefreshInterval,
                    ),
                    const SizedBox(height: 18),
                    if (_validationMessage != null)
                      _TvStatusBanner(
                        icon: LucideIcons.circleAlert,
                        message: _validationMessage!,
                        color: const Color(0xFFE26D5A),
                      ),
                    if (importState.errorMessage != null)
                      _TvStatusBanner(
                        icon: LucideIcons.circleAlert,
                        message: importState.errorMessage!,
                        color: const Color(0xFFE26D5A),
                      ),
                    if (importState.statusMessage != null)
                      _TvStatusBanner(
                        icon: LucideIcons.circleCheck,
                        message: importState.statusMessage!,
                        color: theme.colorScheme.primary,
                      ),
                    if (importState.isImporting ||
                        importState.stage == ProviderImportStage.done ||
                        importState.stage == ProviderImportStage.failed) ...[
                      const SizedBox(height: 12),
                      _TvImportStepper(
                        currentStage: importState.stage,
                        failedStage: importState.failedStage,
                        isImporting: importState.isImporting,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: isImporting ? null : _saveAndImport,
                        icon: isImporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0C0D0E),
                                ),
                              )
                            : const Icon(LucideIcons.download, size: 22),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            isImporting ? 'Importing' : 'Save and Import',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
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
      ),
    );
  }

  String? _fieldError(String value) {
    if (_validationMessage == null) {
      return null;
    }
    return value.trim().isEmpty ? 'Required' : null;
  }

  Future<void> _editText({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
    bool obscure = false,
    TextInputType? keyboardType,
  }) async {
    final edited = await showDialog<String>(
      context: context,
      builder: (context) {
        return _TvTextEntryDialog(
          title: title,
          value: value,
          obscure: obscure,
          keyboardType: keyboardType,
        );
      },
    );
    if (edited == null) {
      return;
    }
    onChanged(edited.trim());
    setState(() => _validationMessage = null);
  }

  Future<void> _pickRefreshInterval() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return _TvRefreshIntervalDialog(selected: _refreshIntervalMinutes);
      },
    );
    if (selected == null) {
      return;
    }
    setState(() => _refreshIntervalMinutes = selected);
  }

  Future<void> _saveAndImport() async {
    final missing = _missingFields();
    if (missing.isNotEmpty) {
      setState(() {
        _validationMessage = 'Fill in ${missing.join(', ')} before importing.';
      });
      return;
    }

    final importController = ref.read(providerSetupImportControllerProvider);
    final providerRepository = ref.read(providerRepositoryProvider);
    final refreshService = ref.read(providerRefreshServiceProvider);
    importController.start();
    setState(() => _validationMessage = null);
    IptvProvider? provider;

    try {
      provider = await providerRepository.createOrUpdateProvider(
        _providerInput(),
      );
      final result = await refreshService.refreshProvider(
        provider.id,
        onProgress: importController.progress,
      );
      if (result.status == ProviderRefreshStatus.failed) {
        if (!provider.hasImportedCatalog) {
          await _deleteFailedProvider(providerRepository, provider);
        }
        importController.fail(result.message ?? 'Provider import failed');
        return;
      }
      importController.succeed(
        result.message ?? 'Imported ${result.itemCount} items',
      );
    } catch (error) {
      final createdProvider = provider;
      if (createdProvider != null && !createdProvider.hasImportedCatalog) {
        await _deleteFailedProvider(providerRepository, createdProvider);
      }
      importController.fail(error.toString());
    }
  }

  List<String> _missingFields() {
    final missing = <String>[];
    if (_name.trim().isEmpty) {
      missing.add('provider name');
    }
    if (_type == ProviderType.xtream) {
      if (_serverUrl.trim().isEmpty) {
        missing.add('server URL');
      }
      if (_username.trim().isEmpty) {
        missing.add('username');
      }
      if (_password.trim().isEmpty) {
        missing.add('password');
      }
    } else if (_type == ProviderType.m3uUrl && _m3uUrl.trim().isEmpty) {
      missing.add('M3U URL');
    }
    return missing;
  }

  Future<void> _deleteFailedProvider(
    ProviderRepository providerRepository,
    IptvProvider provider,
  ) async {
    try {
      await providerRepository.deleteProvider(provider.id);
    } catch (_) {
      // Best-effort cleanup; the visible import error still tells the user
      // what failed, and the provider remains unusable without a catalog.
    }
  }

  ProviderInput _providerInput() {
    return ProviderInput(
      name: _name,
      type: _type,
      serverUrl: _type == ProviderType.xtream ? _serverUrl : null,
      username: _type == ProviderType.xtream ? _username : null,
      password: _type == ProviderType.xtream ? _password : null,
      m3uUrl: _type == ProviderType.m3uUrl ? _m3uUrl : null,
      refreshIntervalMinutes: _refreshIntervalMinutes,
    );
  }
}

class _ProviderTypePicker extends StatelessWidget {
  const _ProviderTypePicker({
    required this.selectedType,
    required this.isImporting,
    required this.onChanged,
  });

  final ProviderType selectedType;
  final bool isImporting;
  final ValueChanged<ProviderType> onChanged;

  @override
  Widget build(BuildContext context) {
    final types = [ProviderType.xtream, ProviderType.m3uUrl];
    return Row(
      children: [
        for (final type in types) ...[
          Expanded(
            child: TvFocusCard(
              onPressed: isImporting ? null : () => onChanged(type),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedType == type
                        ? LucideIcons.check
                        : _providerTypeIcon(type),
                    color: selectedType == type
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFF4F0E8),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _providerTypeLabel(type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        color: selectedType == type
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFF4F0E8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (type != types.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _TvValueField extends StatelessWidget {
  const _TvValueField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPressed,
    this.placeholder = 'Not set',
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.error,
    this.trailingIcon = LucideIcons.pencil,
    this.keyboardType,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onPressed;
  final String placeholder;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final String? error;
  final IconData trailingIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value.trim().isNotEmpty;
    final displayValue = hasValue
        ? obscure
              ? '•' * value.characters.length.clamp(6, 14).toInt()
              : value
        : placeholder;
    final error = this.error;

    return TvFocusCard(
      autofocus: autofocus,
      onPressed: enabled ? onPressed : null,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFF4F0E8)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFCFC7B8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: hasValue
                        ? const Color(0xFFF4F0E8)
                        : const Color(0xFF8E8980),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFE26D5A),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Icon(trailingIcon, size: 24, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [children[0], const SizedBox(height: 12), children[1]],
          );
        }
        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 12),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}

class _TvTextEntryDialog extends StatefulWidget {
  const _TvTextEntryDialog({
    required this.title,
    required this.value,
    required this.obscure,
    required this.keyboardType,
  });

  final String title;
  final String value;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  State<_TvTextEntryDialog> createState() => _TvTextEntryDialogState();
}

class _TvTextEntryDialogState extends State<_TvTextEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151719),
      title: Text(widget.title),
      content: SizedBox(
        width: 620,
        child: TextField(
          controller: _controller,
          autofocus: true,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: widget.title,
            suffixIcon: Icon(
              widget.obscure ? LucideIcons.keyRound : LucideIcons.pencil,
            ),
          ),
          onSubmitted: (_) => _save(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _save(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  void _save(BuildContext context) {
    Navigator.of(context).pop(_controller.text);
  }
}

class _TvRefreshIntervalDialog extends StatelessWidget {
  const _TvRefreshIntervalDialog({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151719),
      title: const Text('Auto-refresh interval'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in refreshIntervalOptions) ...[
              TvFocusCard(
                autofocus: option.minutes == selected,
                onPressed: () => Navigator.of(context).pop(option.minutes),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      option.minutes == selected
                          ? LucideIcons.check
                          : LucideIcons.clock,
                      color: option.minutes == selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFF4F0E8),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        option.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (option != refreshIntervalOptions.last)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _TvImportStepper extends StatelessWidget {
  const _TvImportStepper({
    required this.currentStage,
    required this.failedStage,
    required this.isImporting,
  });

  final ProviderImportStage currentStage;
  final ProviderImportStage? failedStage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _stageIndex(
      currentStage == ProviderImportStage.failed
          ? failedStage ?? ProviderImportStage.validating
          : currentStage,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1012),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var index = 0; index < _importStages.length; index += 1)
              _TvImportStepRow(
                label: _importStages[index].label,
                message: _importStages[index].message,
                isActive: isImporting && index == activeIndex,
                isComplete:
                    currentStage == ProviderImportStage.done ||
                    (currentStage != ProviderImportStage.failed &&
                        index < activeIndex),
                isFailed:
                    currentStage == ProviderImportStage.failed &&
                    index == activeIndex,
              ),
          ],
        ),
      ),
    );
  }
}

class _TvImportStepRow extends StatelessWidget {
  const _TvImportStepRow({
    required this.label,
    required this.message,
    required this.isActive,
    required this.isComplete,
    required this.isFailed,
  });

  final String label;
  final String message;
  final bool isActive;
  final bool isComplete;
  final bool isFailed;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final color = isFailed
        ? const Color(0xFFE26D5A)
        : isActive || isComplete
        ? accent
        : const Color(0xFF5D5A54);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: isActive
                ? CircularProgressIndicator(strokeWidth: 2, color: color)
                : Icon(
                    isFailed
                        ? LucideIcons.circleAlert
                        : isComplete
                        ? LucideIcons.circleCheck
                        : LucideIcons.circle,
                    color: color,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label · $_statusText',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isActive || isComplete || isFailed
                    ? const Color(0xFFF4F0E8)
                    : const Color(0xFF8E8980),
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _statusText {
    if (isFailed) {
      return 'Error';
    }
    if (isActive) {
      return message;
    }
    if (isComplete) {
      return 'Done';
    }
    return 'Pending';
  }
}

class _TvStatusBanner extends StatelessWidget {
  const _TvStatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
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

const _importStages = [
  _TvImportStage(
    stage: ProviderImportStage.validating,
    label: 'Validating account',
    message: 'Running',
  ),
  _TvImportStage(
    stage: ProviderImportStage.live,
    label: 'Live TV',
    message: 'Loading catalog',
  ),
  _TvImportStage(
    stage: ProviderImportStage.movies,
    label: 'Movies',
    message: 'Loading catalog',
  ),
  _TvImportStage(
    stage: ProviderImportStage.series,
    label: 'Series',
    message: 'Loading catalog',
  ),
  _TvImportStage(
    stage: ProviderImportStage.epg,
    label: 'EPG',
    message: 'Preparing metadata',
  ),
  _TvImportStage(
    stage: ProviderImportStage.indexing,
    label: 'Indexing',
    message: 'Saving catalog',
  ),
];

int _stageIndex(ProviderImportStage stage) {
  if (stage == ProviderImportStage.done) {
    return _importStages.length;
  }
  if (stage == ProviderImportStage.failed) {
    return _stageIndex(ProviderImportStage.validating);
  }
  final index = _importStages.indexWhere((item) => item.stage == stage);
  return index < 0 ? 0 : index;
}

class _TvImportStage {
  const _TvImportStage({
    required this.stage,
    required this.label,
    required this.message,
  });

  final ProviderImportStage stage;
  final String label;
  final String message;
}

IconData _providerTypeIcon(ProviderType type) {
  return switch (type) {
    ProviderType.xtream => LucideIcons.server,
    ProviderType.m3uUrl => LucideIcons.link,
    ProviderType.m3uFile => LucideIcons.fileVideo,
  };
}

String _providerTypeLabel(ProviderType type) {
  return switch (type) {
    ProviderType.xtream => 'Xtream Codes',
    ProviderType.m3uUrl => 'M3U URL',
    ProviderType.m3uFile => 'Local File',
  };
}
