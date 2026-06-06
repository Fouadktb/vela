import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/navigation_controller.dart';
import '../catalog/catalog_models.dart';
import '../features/providers/provider_setup_screen.dart';
import '../providers/provider_input_validator.dart';
import '../providers/provider_models.dart';
import '../providers/provider_repository.dart';
import '../providers/refresh_interval.dart';
import 'pairing_session_service.dart';
import 'tv_focus.dart';

class TvProviderSetupScreen extends ConsumerStatefulWidget {
  const TvProviderSetupScreen({super.key});

  @override
  ConsumerState<TvProviderSetupScreen> createState() =>
      _TvProviderSetupScreenState();
}

class _TvProviderSetupScreenState extends ConsumerState<TvProviderSetupScreen> {
  final PairingSessionService _pairingService = PairingSessionService();
  final _scrollController = ScrollController();
  final _statusKey = GlobalKey();
  StreamSubscription<PairingSessionSnapshot>? _pairingSubscription;
  var _type = ProviderType.xtream;
  var _name = 'Primary IPTV';
  var _serverUrl = '';
  var _username = '';
  var _password = '';
  var _m3uUrl = '';
  String? _validationMessage;
  PairingSessionSnapshot _pairingSnapshot = const PairingSessionSnapshot(
    status: PairingSessionStatus.idle,
  );
  int? _handledSubmissionId;

  @override
  void initState() {
    super.initState();
    _pairingSubscription = _pairingService.stream.listen(_handlePairingUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startPairing());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pairingSubscription?.cancel();
    unawaited(_pairingService.dispose());
    super.dispose();
  }

  Future<void> _startPairing() async {
    try {
      final snapshot = await _pairingService.start();
      if (mounted) {
        setState(() => _pairingSnapshot = snapshot);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pairingSnapshot = const PairingSessionSnapshot(
          status: PairingSessionStatus.failed,
          message: 'Could not start local pairing on this device.',
        );
      });
    }
  }

  void _handlePairingUpdate(PairingSessionSnapshot snapshot) {
    if (!mounted) return;
    setState(() => _pairingSnapshot = snapshot);
    final submission = snapshot.submission;
    final submissionId = snapshot.submissionId;
    if (submission == null ||
        submissionId == null ||
        submissionId == _handledSubmissionId) {
      return;
    }
    _handledSubmissionId = submissionId;
    _applyProviderInput(submission.input);
    unawaited(_importProviderInput(submission.input, fromPairing: true));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      providerSetupImportControllerProvider.select(
        (state) => (
          state.isImporting,
          state.statusMessage,
          state.errorMessage,
          state.stage,
          state.current,
          state.total,
        ),
      ),
      (_, next) {
        if (next.$1 || next.$2 != null || next.$3 != null) {
          _scrollStatusIntoView();
        }
      },
    );

    final importState = ref.watch(providerSetupImportControllerProvider);
    final isImporting = importState.isImporting;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 920;
        final compact =
            constraints.maxWidth < 1100 || constraints.maxHeight < 720;
        final formPanel = _panel(
          child: _buildForm(context, importState, isImporting, compact),
        );
        final qrPanel = _panel(
          child: _PairingPanel(
            snapshot: _pairingSnapshot,
            isImporting: isImporting,
            onRestart: _startPairing,
          ),
        );

        return Center(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: compact ? 12 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: horizontal ? 1080 : 680),
              child: horizontal
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: formPanel),
                        SizedBox(width: compact ? 12 : 16),
                        Expanded(flex: 4, child: qrPanel),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        formPanel,
                        const SizedBox(height: 14),
                        qrPanel,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _panel({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151719),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _buildForm(
    BuildContext context,
    ProviderSetupImportController importState,
    bool isImporting,
    bool compact,
  ) {
    final theme = Theme.of(context);
    final padding = compact ? 14.0 : 18.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.radioTower,
                  color: theme.colorScheme.primary,
                  size: compact ? 23 : 27,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Provider',
                    style:
                        (compact
                                ? theme.textTheme.titleLarge
                                : theme.textTheme.headlineSmall)
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 14),
            _ProviderTypePicker(
              selectedType: _type,
              isImporting: isImporting,
              compact: compact,
              onChanged: (type) {
                setState(() {
                  _type = type;
                  _validationMessage = null;
                });
              },
            ),
            SizedBox(height: compact ? 10 : 12),
            _TvValueField(
              label: 'Provider name',
              value: _name,
              icon: LucideIcons.tag,
              autofocus: true,
              compact: compact,
              enabled: !isImporting,
              error: _fieldError(_name),
              onPressed: () => _editText(
                title: 'Provider name',
                value: _name,
                onChanged: (value) => setState(() => _name = value),
              ),
            ),
            const SizedBox(height: 10),
            if (_type == ProviderType.xtream) ...[
              _TvValueField(
                label: 'Server URL',
                value: _serverUrl,
                placeholder: 'https://example.com',
                icon: LucideIcons.server,
                keyboardType: TextInputType.url,
                compact: compact,
                enabled: !isImporting,
                error: _fieldError(_serverUrl),
                onPressed: () => _editText(
                  title: 'Server URL',
                  value: _serverUrl,
                  keyboardType: TextInputType.url,
                  onChanged: (value) => setState(() => _serverUrl = value),
                ),
              ),
              const SizedBox(height: 10),
              _ResponsivePair(
                children: [
                  _TvValueField(
                    label: 'Username',
                    value: _username,
                    icon: LucideIcons.user,
                    compact: compact,
                    enabled: !isImporting,
                    error: _fieldError(_username),
                    onPressed: () => _editText(
                      title: 'Username',
                      value: _username,
                      onChanged: (value) => setState(() => _username = value),
                    ),
                  ),
                  _TvValueField(
                    label: 'Password',
                    value: _password,
                    icon: LucideIcons.keyRound,
                    obscure: true,
                    compact: compact,
                    enabled: !isImporting,
                    error: _fieldError(_password),
                    onPressed: () => _editText(
                      title: 'Password',
                      value: _password,
                      obscure: true,
                      onChanged: (value) => setState(() => _password = value),
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
                compact: compact,
                enabled: !isImporting,
                error: _fieldError(_m3uUrl),
                onPressed: () => _editText(
                  title: 'M3U URL',
                  value: _m3uUrl,
                  keyboardType: TextInputType.url,
                  onChanged: (value) => setState(() => _m3uUrl = value),
                ),
              ),
            SizedBox(height: compact ? 12 : 14),
            KeyedSubtree(
              key: _statusKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                      icon: importState.isImporting
                          ? LucideIcons.loaderCircle
                          : LucideIcons.circleCheck,
                      message: _progressMessage(importState),
                      color: theme.colorScheme.primary,
                      loading: importState.isImporting,
                    ),
                  if (importState.isImporting ||
                      importState.stage == ProviderImportStage.done ||
                      importState.stage == ProviderImportStage.failed) ...[
                    const SizedBox(height: 10),
                    _TvImportStepper(
                      currentStage: importState.stage,
                      failedStage: importState.failedStage,
                      isImporting: importState.isImporting,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: compact ? 12 : 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isImporting ? null : _saveAndImport,
                icon: isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0C0D0E),
                        ),
                      )
                    : const Icon(LucideIcons.download, size: 18),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 0 : 2),
                  child: Text(
                    isImporting ? 'Importing' : 'Save and Import',
                    style: TextStyle(
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  String _progressMessage(ProviderSetupImportController importState) {
    final message = importState.statusMessage ?? 'Importing provider';
    final current = importState.current;
    final total = importState.total;
    if (current == null) {
      return message;
    }
    if (total == null || total <= 0) {
      return '$message · ${_formatCount(current)}';
    }
    return '$message · ${_formatCount(current)} of ${_formatCount(total)}';
  }

  void _applyProviderInput(ProviderInput input) {
    setState(() {
      _type = input.type;
      _name = input.name;
      _serverUrl = input.serverUrl ?? '';
      _username = input.username ?? '';
      _password = input.password ?? '';
      _m3uUrl = input.m3uUrl ?? '';
      _validationMessage = null;
    });
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

  Future<void> _saveAndImport() async {
    final validation = validateProviderInput(_providerInput());
    if (!validation.isValid) {
      setState(() {
        _validationMessage = validation.message;
      });
      return;
    }
    await _importProviderInput(validation.input);
  }

  Future<void> _importProviderInput(
    ProviderInput input, {
    bool fromPairing = false,
  }) async {
    final importController = ref.read(providerSetupImportControllerProvider);
    final providerRepository = ref.read(providerRepositoryProvider);
    final refreshService = ref.read(providerRefreshServiceProvider);
    importController.start();
    _scrollStatusIntoView();
    setState(() => _validationMessage = null);
    if (fromPairing) {
      _pairingService.markImporting('Importing provider on Vela');
    }
    IptvProvider? provider;

    try {
      provider = await providerRepository.createOrUpdateProvider(input);
      final result = await refreshService.refreshProvider(
        provider.id,
        onProgress: importController.progress,
      );
      if (result.status == ProviderRefreshStatus.failed) {
        if (!provider.hasImportedCatalog) {
          await _deleteFailedProvider(providerRepository, provider);
        }
        importController.fail(result.message ?? 'Provider import failed');
        if (fromPairing) {
          _pairingService.markFailed(
            result.message ?? 'Provider import failed',
          );
        }
        return;
      }
      importController.succeed(
        result.message ?? 'Imported ${result.itemCount} items',
      );
      if (fromPairing) {
        _pairingService.markSucceeded(
          result.message ?? 'Imported ${result.itemCount} items',
        );
      } else {
        await _pairingService.stop();
      }
    } catch (error) {
      final createdProvider = provider;
      if (createdProvider != null && !createdProvider.hasImportedCatalog) {
        await _deleteFailedProvider(providerRepository, createdProvider);
      }
      importController.fail(error.toString());
      if (fromPairing) {
        _pairingService.markFailed(error.toString());
      }
    }
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
      refreshIntervalMinutes: defaultRefreshIntervalMinutes,
    );
  }

  void _scrollStatusIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _statusKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.78,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _ProviderTypePicker extends StatelessWidget {
  const _ProviderTypePicker({
    required this.selectedType,
    required this.isImporting,
    required this.compact,
    required this.onChanged,
  });

  final ProviderType selectedType;
  final bool isImporting;
  final bool compact;
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
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 12 : 14,
              ),
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
                    size: compact ? 21 : 24,
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Flexible(
                    child: Text(
                      _providerTypeLabel(type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.titleLarge)
                              ?.copyWith(
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

class _PairingPanel extends StatelessWidget {
  const _PairingPanel({
    required this.snapshot,
    required this.isImporting,
    required this.onRestart,
  });

  final PairingSessionSnapshot snapshot;
  final bool isImporting;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = snapshot.url;
    final ready =
        snapshot.status == PairingSessionStatus.ready ||
        snapshot.status == PairingSessionStatus.received ||
        snapshot.status == PairingSessionStatus.importing ||
        snapshot.status == PairingSessionStatus.failed;
    final message = snapshot.message ?? _statusLabel(snapshot.status);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.qrCode,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add by QR',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Scan from a phone or desktop on the same network.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFAFA8A0),
              height: 1.3,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ready && url != null
                    ? QrImageView(
                        data: url.toString(),
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PairingStatusRow(status: snapshot.status, message: message),
          if (url != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              url.toString(),
              maxLines: 3,
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFFCFC7B8),
                letterSpacing: 0,
              ),
            ),
          ],
          if (snapshot.code != null) ...[
            const SizedBox(height: 8),
            Text(
              'Code ${snapshot.code}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
          if (snapshot.status == PairingSessionStatus.expired ||
              snapshot.status == PairingSessionStatus.failed) ...[
            const SizedBox(height: 14),
            TvFocusCard(
              onPressed: isImporting ? null : onRestart,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.refreshCw, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Restart QR',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(PairingSessionStatus status) {
    return switch (status) {
      PairingSessionStatus.idle => 'QR pairing is idle',
      PairingSessionStatus.starting => 'Starting local pairing',
      PairingSessionStatus.ready => 'Waiting for provider details',
      PairingSessionStatus.received => 'Provider received',
      PairingSessionStatus.importing => 'Importing provider',
      PairingSessionStatus.succeeded => 'Provider imported',
      PairingSessionStatus.failed => 'QR pairing failed',
      PairingSessionStatus.expired => 'QR pairing expired',
    };
  }
}

class _PairingStatusRow extends StatelessWidget {
  const _PairingStatusRow({required this.status, required this.message});

  final PairingSessionStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PairingSessionStatus.failed ||
      PairingSessionStatus.expired => const Color(0xFFE26D5A),
      PairingSessionStatus.succeeded => const Color(0xFF8EC5A1),
      PairingSessionStatus.ready ||
      PairingSessionStatus.received ||
      PairingSessionStatus.importing => Theme.of(context).colorScheme.primary,
      _ => const Color(0xFFAFA8A0),
    };
    final loading =
        status == PairingSessionStatus.starting ||
        status == PairingSessionStatus.importing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: loading
                  ? CircularProgressIndicator(strokeWidth: 2, color: color)
                  : Icon(
                      status == PairingSessionStatus.failed ||
                              status == PairingSessionStatus.expired
                          ? LucideIcons.circleAlert
                          : LucideIcons.circleCheck,
                      color: color,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFF4F0E8),
                  fontWeight: FontWeight.w800,
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
    this.keyboardType,
    this.compact = false,
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
  final TextInputType? keyboardType;
  final bool compact;

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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 16,
        vertical: compact ? 12 : 14,
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 24 : 28, color: const Color(0xFFF4F0E8)),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      (compact
                              ? theme.textTheme.labelLarge
                              : theme.textTheme.titleSmall)
                          ?.copyWith(
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
                  style:
                      (compact
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge)
                          ?.copyWith(
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
          SizedBox(width: compact ? 10 : 12),
          Icon(
            LucideIcons.pencil,
            size: compact ? 20 : 23,
            color: theme.colorScheme.primary,
          ),
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
    this.loading = false,
  });

  final IconData icon;
  final String message;
  final Color color;
  final bool loading;

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
              SizedBox(
                width: 24,
                height: 24,
                child: loading
                    ? CircularProgressIndicator(strokeWidth: 2, color: color)
                    : Icon(icon, color: color, size: 24),
              ),
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

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}
