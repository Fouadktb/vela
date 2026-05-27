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

  bool get isImporting => _isImporting;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  bool get shouldKeepSetupVisible => _isImporting || _errorMessage != null;

  void start(String message) {
    _isImporting = true;
    _statusMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void progress(String message) {
    _statusMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void succeed(String message) {
    _isImporting = false;
    _statusMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void fail(String message) {
    _isImporting = false;
    _statusMessage = null;
    _errorMessage = message;
    notifyListeners();
  }
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
