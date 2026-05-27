import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/navigation_controller.dart';
import '../../catalog/catalog_models.dart';
import '../../providers/provider_models.dart';
import '../../providers/refresh_interval.dart';

final providerSetupImportControllerProvider =
    ChangeNotifierProvider<ProviderSetupImportController>((ref) {
      return ProviderSetupImportController();
    });

class ProviderSetupImportController extends ChangeNotifier {
  bool _isImporting = false;
  String? _statusMessage;
  String? _errorMessage;
  ProviderImportStep _step = ProviderImportStep.idle;
  ProviderImportStep _failedStep = ProviderImportStep.idle;

  bool get isImporting => _isImporting;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  ProviderImportStep get step => _step;
  ProviderImportStep get failedStep => _failedStep;
  bool get shouldKeepSetupVisible => _isImporting || _errorMessage != null;

  void start(String message) {
    _isImporting = true;
    _statusMessage = message;
    _errorMessage = null;
    _step = _stepForMessage(message);
    _failedStep = ProviderImportStep.idle;
    notifyListeners();
  }

  void progress(String message) {
    _statusMessage = message;
    _errorMessage = null;
    _step = _stepForMessage(message);
    _failedStep = ProviderImportStep.idle;
    notifyListeners();
  }

  void succeed(String message) {
    _isImporting = false;
    _statusMessage = message;
    _errorMessage = null;
    _step = ProviderImportStep.finished;
    _failedStep = ProviderImportStep.idle;
    notifyListeners();
  }

  void fail(String message) {
    _isImporting = false;
    _statusMessage = null;
    _errorMessage = message;
    _failedStep = switch (_step) {
      ProviderImportStep.idle ||
      ProviderImportStep.finished ||
      ProviderImportStep.failed => ProviderImportStep.loadingCatalog,
      _ => _step,
    };
    _step = ProviderImportStep.failed;
    notifyListeners();
  }
}

enum ProviderImportStep {
  idle,
  savingProvider,
  checkingSource,
  loadingCatalog,
  preparingCatalog,
  savingCatalog,
  finished,
  failed,
}

ProviderImportStep _stepForMessage(String message) {
  final value = message.toLowerCase();
  if (value.contains('saving provider')) {
    return ProviderImportStep.savingProvider;
  }
  if (value.contains('checking') || value.contains('login')) {
    return ProviderImportStep.checkingSource;
  }
  if (value.contains('loading') ||
      value.contains('reading') ||
      value.contains('importing')) {
    return ProviderImportStep.loadingCatalog;
  }
  if (value.contains('parsing') || value.contains('preparing')) {
    return ProviderImportStep.preparingCatalog;
  }
  if (value.contains('saving catalog')) {
    return ProviderImportStep.savingCatalog;
  }
  if (value.contains('imported')) {
    return ProviderImportStep.finished;
  }
  return ProviderImportStep.loadingCatalog;
}

class ProviderSetupScreen extends ConsumerStatefulWidget {
  const ProviderSetupScreen({super.key});

  @override
  ConsumerState<ProviderSetupScreen> createState() =>
      _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends ConsumerState<ProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Primary IPTV');
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _fileController = TextEditingController();
  var _refreshIntervalMinutes = defaultRefreshIntervalMinutes;
  ProviderType _type = ProviderType.xtream;

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
    final theme = Theme.of(context);
    final importState = ref.watch(providerSetupImportControllerProvider);
    final isImporting = importState.isImporting;

    return ColoredBox(
      color: const Color(0xFF0C0D0E),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF151719),
                border: Border.all(color: const Color(0xFF292D31)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.radioTower,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add Provider',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SegmentedButton<ProviderType>(
                        segments: const [
                          ButtonSegment(
                            value: ProviderType.xtream,
                            icon: Icon(LucideIcons.server, size: 17),
                            label: Text('Xtream Codes'),
                          ),
                          ButtonSegment(
                            value: ProviderType.m3uUrl,
                            icon: Icon(LucideIcons.link, size: 17),
                            label: Text('M3U URL'),
                          ),
                          ButtonSegment(
                            value: ProviderType.m3uFile,
                            icon: Icon(LucideIcons.fileVideo, size: 17),
                            label: Text('Local File'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (values) {
                          setState(() => _type = values.single);
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Provider name',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      if (_type == ProviderType.xtream) ...[
                        TextFormField(
                          controller: _serverController,
                          decoration: const InputDecoration(
                            labelText: 'Server URL',
                            hintText: 'https://example.com',
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
                      if (_type == ProviderType.m3uUrl)
                        TextFormField(
                          controller: _m3uUrlController,
                          decoration: const InputDecoration(
                            labelText: 'M3U URL',
                            hintText: 'https://example.com/playlist.m3u',
                            prefixIcon: Icon(LucideIcons.link),
                          ),
                          keyboardType: TextInputType.url,
                          validator: _required,
                        ),
                      if (_type == ProviderType.m3uFile)
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
                              onPressed: isImporting ? null : _pickFile,
                              icon: const Icon(
                                LucideIcons.folderOpen,
                                size: 18,
                              ),
                              label: const Text('Choose'),
                            ),
                          ],
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
                        onChanged: isImporting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(
                                    () => _refreshIntervalMinutes = value,
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: 18),
                      if (importState.errorMessage != null)
                        _StatusBanner(
                          icon: LucideIcons.circleAlert,
                          message: importState.errorMessage!,
                          color: const Color(0xFFE26D5A),
                        ),
                      if (importState.statusMessage != null)
                        _StatusBanner(
                          icon: LucideIcons.circleCheck,
                          message: importState.statusMessage!,
                          color: theme.colorScheme.primary,
                        ),
                      if (importState.isImporting ||
                          importState.step == ProviderImportStep.finished ||
                          importState.step == ProviderImportStep.failed) ...[
                        const SizedBox(height: 12),
                        _ImportStepper(
                          currentStep: importState.step,
                          failedStep: importState.failedStep,
                          isImporting: importState.isImporting,
                        ),
                      ],
                      const SizedBox(height: 18),
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
                          label: Text(
                            isImporting ? 'Importing' : 'Save and Import',
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
      ),
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

  Future<void> _saveAndImport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final importController = ref.read(providerSetupImportControllerProvider);
    final providerRepository = ref.read(providerRepositoryProvider);
    final refreshService = ref.read(providerRefreshServiceProvider);
    importController.start('Saving provider details');

    try {
      final provider = await providerRepository.createOrUpdateProvider(
        _providerInput(),
      );
      final result = await refreshService.refreshProvider(
        provider.id,
        onProgress: importController.progress,
      );
      if (result.status == ProviderRefreshStatus.failed) {
        if (!provider.hasImportedCatalog) {
          await providerRepository.deleteProvider(provider.id);
        }
        importController.fail(result.message ?? 'Provider import failed');
        return;
      }
      importController.succeed(
        result.message ?? 'Imported ${result.itemCount} items',
      );
    } catch (error) {
      importController.fail(error.toString());
    }
  }

  ProviderInput _providerInput() {
    return ProviderInput(
      name: _nameController.text,
      type: _type,
      serverUrl: _type == ProviderType.xtream ? _serverController.text : null,
      username: _type == ProviderType.xtream ? _usernameController.text : null,
      password: _type == ProviderType.xtream ? _passwordController.text : null,
      m3uUrl: _type == ProviderType.m3uUrl ? _m3uUrlController.text : null,
      localFilePath: _type == ProviderType.m3uFile
          ? _fileController.text
          : null,
      refreshIntervalMinutes: _refreshIntervalMinutes,
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}

class _ImportStepper extends StatelessWidget {
  const _ImportStepper({
    required this.currentStep,
    required this.failedStep,
    required this.isImporting,
  });

  final ProviderImportStep currentStep;
  final ProviderImportStep failedStep;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeIndex = _stepIndex(
      currentStep == ProviderImportStep.failed ? failedStep : currentStep,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1012),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var index = 0; index < _importStepLabels.length; index += 1)
              _ImportStepRow(
                label: _importStepLabels[index],
                isActive: isImporting && index == activeIndex,
                isComplete:
                    currentStep == ProviderImportStep.finished ||
                    (currentStep != ProviderImportStep.failed &&
                        index < activeIndex),
                isFailed:
                    currentStep == ProviderImportStep.failed &&
                    index == activeIndex,
                accent: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ImportStepRow extends StatelessWidget {
  const _ImportStepRow({
    required this.label,
    required this.isActive,
    required this.isComplete,
    required this.isFailed,
    required this.accent,
  });

  final String label;
  final bool isActive;
  final bool isComplete;
  final bool isFailed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = isFailed
        ? const Color(0xFFE26D5A)
        : isComplete || isActive
        ? accent
        : const Color(0xFF5D5A54);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: isActive
                ? CircularProgressIndicator(strokeWidth: 2, color: iconColor)
                : Icon(
                    isFailed
                        ? LucideIcons.circleAlert
                        : isComplete
                        ? LucideIcons.circleCheck
                        : LucideIcons.circle,
                    size: 18,
                    color: iconColor,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive || isComplete
                    ? const Color(0xFFF4F0E8)
                    : const Color(0xFF8E8980),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _importStepLabels = [
  'Save provider',
  'Check credentials',
  'Load live TV, movies, and series',
  'Prepare catalog',
  'Save catalog',
];

int _stepIndex(ProviderImportStep step) {
  return switch (step) {
    ProviderImportStep.idle => 0,
    ProviderImportStep.savingProvider => 0,
    ProviderImportStep.checkingSource => 1,
    ProviderImportStep.loadingCatalog => 2,
    ProviderImportStep.preparingCatalog => 3,
    ProviderImportStep.savingCatalog => 4,
    ProviderImportStep.finished => _importStepLabels.length,
    ProviderImportStep.failed => 2,
  };
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}
