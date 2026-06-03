# Android TV Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Android TV support to Vela with a sideloadable APK, remote-first navigation, in-app playback, and shared catalog/provider logic.

**Architecture:** Keep one Flutter codebase. Add Android platform scaffolding, platform-safe window/fullscreen adapters, and an Android TV shell selected at runtime while preserving the existing desktop shell for macOS and Windows.

**Tech Stack:** Flutter 3.44, Dart 3.12, Riverpod, Drift, media_kit, Android TV Leanback launcher, GitHub Releases.

---

## Baseline Notes

- Work in `/Users/fouadktb/Documents/GitHub/iptv-player/.worktrees/android-tv` on branch `feature/android-tv`.
- The main checkout is dirty on `bug/playback-error-notification`; do not modify it.
- Current Android SDK status from `flutter doctor -v`: Android SDK is missing. Build and device verification require installing Android Studio/SDK or running the Android build on a machine/runner with the SDK.
- User preference: do not add a new automated test suite for this feature. Use `flutter analyze`, Android build, desktop analyze, and device smoke checks.

## Target File Structure

- Create `android/**`: generated Flutter Android platform files, customized for Android TV.
- Modify `pubspec.yaml`: add Android media-kit package explicitly if Flutter does not keep it after scaffold generation.
- Modify `pubspec.lock`: dependency resolution after Android package changes.
- Modify `lib/main.dart`: platform-safe startup.
- Create `lib/src/platform/vela_platform.dart`: platform capability helpers.
- Create `lib/src/platform/vela_windowing.dart`: desktop window manager and Android immersive fullscreen adapter.
- Modify `lib/src/app/vela_app.dart`: select desktop shell or TV shell.
- Create `lib/src/tv/vela_tv_shell.dart`: Android TV app shell.
- Create `lib/src/tv/tv_focus.dart`: TV focus ring and D-pad friendly components.
- Create `lib/src/tv/tv_provider_setup_screen.dart`: remote-first provider setup using shared repository/import logic.
- Create `lib/src/tv/tv_catalog_screen.dart`: category/content browsing for TV.
- Create `lib/src/tv/tv_detail_panel.dart`: TV item detail and actions.
- Modify `lib/src/playback/vela_player_route.dart`: one shared player route with desktop and Android TV input handling.
- Modify `lib/src/playback/playback_controller.dart`: use platform fullscreen adapter.
- Modify `lib/src/playback/vela_player_route.dart`: remove direct window manager assumptions and support TV remote keys.
- Modify `lib/src/updates/update_checker.dart`: expose platform-specific release asset guidance and use cross-platform URL launching.
- Create `scripts/package-android-tv.sh`: local Android TV APK build wrapper.
- Modify `docs/release-checklist.md`: add Android TV packaging and smoke checks.

---

### Task 1: Android Platform Scaffold

**Files:**
- Create: `android/**`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

- [ ] **Step 1: Confirm clean feature worktree**

Run:

```bash
git status --short --branch
```

Expected:

```text
## feature/android-tv
```

- [ ] **Step 2: Add Flutter Android platform files**

Run:

```bash
flutter create --platforms=android --org com.fouadktb --project-name vela .
```

Expected:

```text
Wrote ...
```

- [ ] **Step 3: Keep Android media-kit dependency explicit**

Open `pubspec.yaml`. If `media_kit_libs_android_video` is not listed under `dependencies`, add it beside the existing media-kit packages:

```yaml
  media_kit: ^1.2.6
  media_kit_libs_video: ^1.0.7
  media_kit_libs_android_video: ^1.3.8
  media_kit_video: ^2.0.1
```

If `flutter pub get` resolves a newer compatible `media_kit_libs_android_video`, keep the resolved version range that works with the lockfile.

- [ ] **Step 4: Resolve dependencies**

Run:

```bash
flutter pub get
```

Expected:

```text
Got dependencies!
```

- [ ] **Step 5: Verify Android scaffold exists**

Run:

```bash
test -f android/app/src/main/AndroidManifest.xml && \
test -f android/app/build.gradle.kts && \
test -f android/settings.gradle.kts
```

Expected: command exits with code `0`.

- [ ] **Step 6: Commit scaffold**

Run:

```bash
git add android pubspec.yaml pubspec.lock
git commit -m "feat: add android platform scaffold"
```

---

### Task 2: Platform Capability Helpers

**Files:**
- Create: `lib/src/platform/vela_platform.dart`

- [ ] **Step 1: Add platform helper**

Create `lib/src/platform/vela_platform.dart`:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';

enum VelaSurface { desktop, androidTv }

class VelaPlatform {
  const VelaPlatform._();

  static bool get isDesktopWindowPlatform {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  static bool get isAndroidTv {
    return isAndroid;
  }

  static VelaSurface get surface {
    return isAndroidTv ? VelaSurface.androidTv : VelaSurface.desktop;
  }

  static bool get supportsLocalFilePicker {
    return isDesktopWindowPlatform;
  }
}
```

- [ ] **Step 2: Verify helper compiles**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 3: Commit helper**

Run:

```bash
git add lib/src/platform/vela_platform.dart
git commit -m "feat: add platform capability helpers"
```

---

### Task 3: Platform-Safe Startup and Windowing

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/src/platform/vela_windowing.dart`

- [ ] **Step 1: Add windowing adapter**

Create `lib/src/platform/vela_windowing.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'vela_platform.dart';

class VelaWindowing {
  const VelaWindowing._();

  static Future<void> initializeMainWindow() async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }

    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'Vela',
        minimumSize: Size(1120, 720),
        size: Size(1440, 900),
        center: true,
        backgroundColor: Colors.black,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
}

class VelaFullscreenController {
  bool _isFullscreen = false;
  bool _restoreMaximizedAfterFullscreen = false;

  bool get isFullscreen => _isFullscreen;

  Future<bool> refreshFullscreenState() async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      _isFullscreen = true;
      return _isFullscreen;
    }
    _isFullscreen = await windowManager.isFullScreen();
    return _isFullscreen;
  }

  Future<void> setFullscreen(bool enabled) async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      _isFullscreen = true;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }

    if (enabled) {
      await _prepareDesktopWindowForFullscreen();
      await windowManager.setFullScreen(true);
      _isFullscreen = true;
      return;
    }

    await windowManager.setFullScreen(false);
    await _restoreDesktopWindowAfterFullscreen();
    _isFullscreen = false;
  }

  Future<void> toggleFullscreen() async {
    final current = await refreshFullscreenState();
    await setFullscreen(!current);
  }

  Future<void> exitFullscreenIfNeeded() async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _isFullscreen = true;
      return;
    }
    if (await windowManager.isFullScreen()) {
      await setFullscreen(false);
      return;
    }
    _isFullscreen = false;
  }

  Future<void> _prepareDesktopWindowForFullscreen() async {
    _restoreMaximizedAfterFullscreen = false;
    if (!Platform.isWindows) return;

    final wasMaximized = await windowManager.isMaximized();
    if (!wasMaximized) return;

    _restoreMaximizedAfterFullscreen = true;
    await windowManager.unmaximize();
  }

  Future<void> _restoreDesktopWindowAfterFullscreen() async {
    if (!Platform.isWindows || !_restoreMaximizedAfterFullscreen) return;

    _restoreMaximizedAfterFullscreen = false;
    await windowManager.maximize();
  }
}

class VelaWindowCloseGuard with WindowListener {
  VelaWindowCloseGuard({required this.onClose});

  final FutureOr<void> Function() onClose;
  bool _enabled = false;

  Future<void> enable() async {
    if (!VelaPlatform.isDesktopWindowPlatform || _enabled) return;
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    _enabled = true;
  }

  Future<void> disable() async {
    if (!VelaPlatform.isDesktopWindowPlatform || !_enabled) return;
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    _enabled = false;
  }

  @override
  void onWindowClose() {
    unawaited(Future<void>.sync(onClose));
  }
}
```

- [ ] **Step 2: Update app startup**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'src/app/vela_app.dart';
import 'src/platform/vela_windowing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await VelaWindowing.initializeMainWindow();

  runApp(const ProviderScope(child: VelaApp()));
}
```

- [ ] **Step 3: Verify desktop analyze**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 4: Commit startup/windowing**

Run:

```bash
git add lib/main.dart lib/src/platform/vela_windowing.dart
git commit -m "feat: add platform-safe windowing"
```

---

### Task 4: Android TV Manifest and Resources

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle.kts`
- Create/modify: `android/app/src/main/res/drawable*/**`
- Create/modify: `android/app/src/main/res/mipmap*/**`
- Create: `android/app/src/main/res/values/strings.xml` if missing

- [ ] **Step 1: Configure Android manifest for TV**

Edit `android/app/src/main/AndroidManifest.xml` so the core shape is:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />

    <uses-feature
        android:name="android.software.leanback"
        android:required="true" />
    <uses-feature
        android:name="android.hardware.touchscreen"
        android:required="false" />

    <application
        android:label="Vela"
        android:name="${applicationName}"
        android:banner="@drawable/tv_banner"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:exported="true"
            android:hardwareAccelerated="true"
            android:launchMode="singleTop"
            android:screenOrientation="landscape"
            android:theme="@style/LaunchTheme"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

- [ ] **Step 2: Add TV banner resource**

Create `android/app/src/main/res/drawable/tv_banner.xml`:

```xml
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#0C0D0E" />
    <size
        android:width="320dp"
        android:height="180dp" />
    <padding
        android:left="24dp"
        android:top="24dp"
        android:right="24dp"
        android:bottom="24dp" />
</shape>
```

This is enough for a first launcher banner. Replace it with branded bitmap artwork once the Android TV APK flow works.

- [ ] **Step 3: Set minimum SDK and app id**

In `android/app/build.gradle.kts`, confirm:

```kotlin
android {
    namespace = "com.fouadktb.vela"

    defaultConfig {
        applicationId = "com.fouadktb.vela"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

- [ ] **Step 4: Verify manifest parses**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 5: Commit Android TV manifest**

Run:

```bash
git add android
git commit -m "feat: configure android tv launcher"
```

---

### Task 5: Select Desktop Shell or TV Shell

**Files:**
- Modify: `lib/src/app/vela_app.dart`
- Create: `lib/src/tv/vela_tv_shell.dart`
- Create: `lib/src/tv/tv_focus.dart`

- [ ] **Step 1: Add TV focus primitives**

Create `lib/src/tv/tv_focus.dart`:

```dart
import 'package:flutter/material.dart';

class TvFocusCard extends StatelessWidget {
  const TvFocusCard({
    required this.child,
    required this.onPressed,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableActionDetector(
      autofocus: autofocus,
      mouseCursor: SystemMouseCursors.click,
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Material(
            color: focused ? const Color(0xFF24272B) : const Color(0xFF151719),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: focused
                    ? theme.colorScheme.primary
                    : const Color(0xFF292D31),
                width: focused ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Padding(padding: padding, child: child),
            ),
          );
        },
      ),
    );
  }
}

class TvSectionTitle extends StatelessWidget {
  const TvSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
    );
  }
}
```

- [ ] **Step 2: Add TV shell skeleton**

Create `lib/src/tv/vela_tv_shell.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../features/providers/provider_setup_screen.dart';
import '../updates/update_checker.dart';
import 'tv_focus.dart';

class VelaTvShell extends ConsumerStatefulWidget {
  const VelaTvShell({super.key});

  @override
  ConsumerState<VelaTvShell> createState() => _VelaTvShellState();
}

class _VelaTvShellState extends ConsumerState<VelaTvShell> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() async {
        await ref.read(providerRefreshServiceProvider).refreshStaleProvidersOnLaunch();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(providersProvider);
    final updateStatus = ref.watch(updateStatusProvider).value;
    final navigation = ref.watch(navigationControllerProvider);

    return providers.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text(error.toString()))),
      data: (items) {
        final hasProviders = items.any((provider) => provider.hasImportedCatalog);
        return Scaffold(
          backgroundColor: const Color(0xFF0C0D0E),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.radioTower, color: Color(0xFFE7B85B), size: 34),
                      const SizedBox(width: 14),
                      Text(
                        'Vela',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const Spacer(),
                      if (updateStatus?.hasUpdate == true)
                        FilledButton.icon(
                          onPressed: () => unawaited(openExternalUrl(updateStatus!.releaseUrl)),
                          icon: const Icon(LucideIcons.download),
                          label: Text('Update ${updateStatus!.latestVersion}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (!hasProviders)
                    const Expanded(child: ProviderSetupScreen())
                  else
                    Expanded(
                      child: _TvSectionGrid(
                        selected: navigation.selectedSection,
                        onSelect: ref.read(navigationControllerProvider).selectSection,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TvSectionGrid extends StatelessWidget {
  const _TvSectionGrid({required this.selected, required this.onSelect});

  final VelaSection selected;
  final ValueChanged<VelaSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final sections = VelaSection.values;
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 2.2,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return TvFocusCard(
          autofocus: index == 0,
          onPressed: () => onSelect(section),
          child: Row(
            children: [
              Icon(section.icon, size: 34, color: const Color(0xFFE7B85B)),
              const SizedBox(width: 16),
              Expanded(child: TvSectionTitle(section.label)),
            ],
          ),
        );
      },
    );
  }
}
```

This skeleton intentionally gets Android TV shell selection compiling before the full TV catalog replaces the grid.

- [ ] **Step 3: Select shell by platform**

Modify `lib/src/app/vela_app.dart`:

```dart
import 'package:flutter/material.dart';

import '../platform/vela_platform.dart';
import '../shell/vela_shell.dart';
import '../tv/vela_tv_shell.dart';
import 'app_theme.dart';

class VelaApp extends StatelessWidget {
  const VelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vela',
      debugShowCheckedModeBanner: false,
      theme: buildVelaTheme(),
      home: VelaPlatform.surface == VelaSurface.androidTv
          ? const VelaTvShell()
          : const VelaShell(),
    );
  }
}
```

- [ ] **Step 4: Verify shell selection compiles**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 5: Commit shell selection**

Run:

```bash
git add lib/src/app/vela_app.dart lib/src/tv
git commit -m "feat: add android tv shell selection"
```

---

### Task 6: Remote-Friendly Provider Setup

**Files:**
- Modify: `lib/src/features/providers/provider_setup_screen.dart`
- Create: `lib/src/tv/tv_provider_setup_screen.dart`
- Modify: `lib/src/tv/vela_tv_shell.dart`

- [ ] **Step 1: Add platform-aware provider type list**

In `lib/src/features/providers/provider_setup_screen.dart`, import `VelaPlatform`:

```dart
import '../../platform/vela_platform.dart';
```

Replace the hard-coded `SegmentedButton` segments with a helper that hides local file on Android TV:

```dart
List<ButtonSegment<ProviderType>> _providerTypeSegments() {
  return [
    const ButtonSegment(
      value: ProviderType.xtream,
      icon: Icon(LucideIcons.server, size: 17),
      label: Text('Xtream Codes'),
    ),
    const ButtonSegment(
      value: ProviderType.m3uUrl,
      icon: Icon(LucideIcons.link, size: 17),
      label: Text('M3U URL'),
    ),
    if (VelaPlatform.supportsLocalFilePicker)
      const ButtonSegment(
        value: ProviderType.m3uFile,
        icon: Icon(LucideIcons.fileVideo, size: 17),
        label: Text('Local File'),
      ),
  ];
}
```

Use it:

```dart
final activeType = _effectiveProviderType;

SegmentedButton<ProviderType>(
  segments: _providerTypeSegments(),
  selected: {activeType},
  onSelectionChanged: (values) {
    setState(() => _type = values.single);
  },
)
```

Add this getter to `_ProviderSetupScreenState`:

```dart
ProviderType get _effectiveProviderType {
  if (_type == ProviderType.m3uFile && !VelaPlatform.supportsLocalFilePicker) {
    return ProviderType.xtream;
  }
  return _type;
}
```

Use `activeType` for the conditional field rendering inside `build`. In `_providerInput()`, use `final type = _effectiveProviderType;` and then use `type` for `ProviderInput.type`, `serverUrl`, `username`, `password`, `m3uUrl`, and `localFilePath`.

- [ ] **Step 2: Add TV provider setup wrapper**

Create `lib/src/tv/tv_provider_setup_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../features/providers/provider_setup_screen.dart';

class TvProviderSetupScreen extends StatelessWidget {
  const TvProviderSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Transform.scale(
          scale: 1.08,
          child: const ProviderSetupScreen(),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Use TV provider setup in TV shell**

In `lib/src/tv/vela_tv_shell.dart`, replace:

```dart
import '../features/providers/provider_setup_screen.dart';
```

with:

```dart
import 'tv_provider_setup_screen.dart';
```

Replace:

```dart
const Expanded(child: ProviderSetupScreen())
```

with:

```dart
const Expanded(child: TvProviderSetupScreen())
```

- [ ] **Step 4: Verify provider setup compiles**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 5: Commit provider setup**

Run:

```bash
git add lib/src/features/providers/provider_setup_screen.dart lib/src/tv
git commit -m "feat: adapt provider setup for android tv"
```

---

### Task 7: TV Catalog Browser

**Files:**
- Create: `lib/src/tv/tv_catalog_screen.dart`
- Create: `lib/src/tv/tv_detail_panel.dart`
- Modify: `lib/src/tv/vela_tv_shell.dart`
- Create: `lib/src/features/catalog/catalog_card_mapper.dart`
- Create: `lib/src/features/catalog/catalog_playback_target.dart`
- Modify: `lib/src/features/catalog/catalog_screen.dart` to use the extracted shared mapping and playback target helpers.

- [ ] **Step 1: Add TV catalog screen using shared providers**

Create `lib/src/tv/tv_catalog_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../catalog/catalog_models.dart';
import '../playback/playable_item.dart';
import 'tv_focus.dart';

class TvCatalogScreen extends ConsumerWidget {
  const TvCatalogScreen({
    required this.section,
    required this.onOpenPlayer,
    super.key,
  });

  final VelaSection section;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentType = section.contentType;
    final categoriesValue = contentType == null
        ? const AsyncValue<List<CatalogCategory>>.data(<CatalogCategory>[])
        : ref.watch(
            categoriesProvider(
              CategoryQuery(contentType: contentType),
            ),
          );

    return categoriesValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (categories) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(section.icon, size: 36, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 14),
                TvSectionTitle(section.label),
              ],
            ),
            const SizedBox(height: 22),
            if (contentType != null)
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final category = isAll ? null : categories[index - 1];
                    return SizedBox(
                      width: 300,
                      child: TvFocusCard(
                        autofocus: index == 0,
                        onPressed: () {
                          ref.read(navigationControllerProvider).selectCategory(category?.id);
                        },
                        child: Text(
                          isAll ? 'All ${section.label}' : category!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 22),
            Expanded(
              child: _TvCatalogGrid(
                section: section,
                contentType: contentType,
                categoryId: ref.watch(navigationControllerProvider).stateFor(section).selectedCategoryId,
                onOpenPlayer: onOpenPlayer,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TvCatalogGrid extends ConsumerWidget {
  const _TvCatalogGrid({
    required this.section,
    required this.contentType,
    required this.categoryId,
    required this.onOpenPlayer,
  });

  final VelaSection section;
  final CatalogContentType? contentType;
  final String? categoryId;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contentType == null) {
      return Center(
        child: Text(
          'Open Live, Movies, or Series from the TV navigation.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    final itemsValue = ref.watch(
      catalogItemsProvider(
        CatalogItemsQuery(section: contentType!, categoryId: categoryId),
      ),
    );

    return itemsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No ${section.label.toLowerCase()} found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return TvFocusCard(
              onPressed: () {
                if (item.contentType == CatalogContentType.series) {
                  ref.read(navigationControllerProvider).selectItem(item.id);
                  return;
                }
                final streamUrl = item.streamUrl;
                if (streamUrl == null || streamUrl.trim().isEmpty) return;
                onOpenPlayer(
                  PlayableItem(
                    id: item.id,
                    providerId: item.providerId,
                    title: item.title,
                    streamUrl: streamUrl,
                    kind: switch (item.contentType) {
                      CatalogContentType.live => PlayableKind.live,
                      CatalogContentType.movie => PlayableKind.movie,
                      CatalogContentType.series => PlayableKind.episode,
                    },
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF202326),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Icon(section.icon, size: 42)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Replace section grid with catalog screen**

In `lib/src/tv/vela_tv_shell.dart`, import:

```dart
import '../playback/playable_item.dart';
import '../playback/vela_player_route.dart';
import 'tv_catalog_screen.dart';
```

Add method inside `_VelaTvShellState`:

```dart
void _openPlayer(BuildContext context, PlayableItem item) {
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
```

Replace `_TvSectionGrid` rendering with:

```dart
Expanded(
  child: TvCatalogScreen(
    section: navigation.selectedSection,
    onOpenPlayer: (item) => _openPlayer(context, item),
  ),
)
```

Remove `_TvSectionGrid` after `TvCatalogScreen` becomes the TV content body.

- [ ] **Step 3: Extract shared catalog card and playback mapping**

Extract the private card mapping and playback target logic from `CatalogScreen` so desktop and TV use identical stream URL, resume, episode, and watch-history behavior.

Create `lib/src/features/catalog/catalog_card_mapper.dart` with public functions for:

```dart
Future<List<CatalogCardItem>> catalogItemsToCards(
  CatalogRepository catalogRepository,
  WatchHistoryRepository historyRepository,
  List<CatalogItem> items,
)
```

Move the existing private mapping logic from `catalog_screen.dart` into that file and update both desktop and TV imports.

Create `lib/src/features/catalog/catalog_playback_target.dart`:

```dart
import '../../catalog/catalog_models.dart';
import '../../playback/playable_item.dart';

class CatalogPlaybackTarget {
  const CatalogPlaybackTarget({required this.playable, this.history});

  final PlayableItem playable;
  final WatchHistoryUpdate? history;
}
```

In the same file, move the existing implementations of `_playbackTargetForCard`, `_recentPlaybackTarget`, `_episodePlaybackTarget`, `_episodePlayableItems`, `_episodePlayable`, `_streamUrl`, `_episodeHasPlayableStream`, `_hasPlayableStream`, and `_externalSeriesIdFromCatalogId` from `catalog_screen.dart`. Rename `_PlaybackTarget` to `CatalogPlaybackTarget`, rename `_playbackTargetForCard` to `playbackTargetForCatalogCard`, and expose `_episodePlaybackTarget` as `playbackTargetForCatalogEpisode`. After the move, desktop `CatalogScreen` must call `playbackTargetForCatalogCard` instead of its former private `_playbackTargetForCard`.

- [ ] **Step 4: Add TV content grid**

Complete `TvCatalogScreen` by watching `catalogItemsProvider` for the active section/category and rendering a grid of `TvFocusCard`. Each card opens `PlayableItem` for live/movie or opens a details panel for series.

Grid shape:

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 5,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 0.72,
  ),
  itemCount: cards.length,
  itemBuilder: (context, index) {
    final card = cards[index];
    return TvFocusCard(
      onPressed: () => _openCard(card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF202326),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(section.icon, size: 42)),
            ),
          ),
          const SizedBox(height: 10),
          Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  },
)
```

- [ ] **Step 5: Add TV series detail panel**

Create `lib/src/tv/tv_detail_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation_controller.dart';
import '../catalog/catalog_models.dart';
import '../playback/playable_item.dart';
import '../features/catalog/catalog_playback_target.dart';
import '../features/catalog/item_grid.dart';
import 'tv_focus.dart';

final _tvSeriesEpisodesProvider = StreamProvider.autoDispose
    .family<List<CatalogEpisode>, _TvSeriesEpisodesQuery>((ref, query) {
  return ref
      .watch(catalogRepositoryProvider)
      .watchEpisodesForSeries(
        providerId: query.providerId,
        seriesId: query.seriesId,
      );
});

class _TvSeriesEpisodesQuery {
  const _TvSeriesEpisodesQuery({
    required this.providerId,
    required this.seriesId,
  });

  final String providerId;
  final String seriesId;

  @override
  bool operator ==(Object other) {
    return other is _TvSeriesEpisodesQuery &&
        other.providerId == providerId &&
        other.seriesId == seriesId;
  }

  @override
  int get hashCode => Object.hash(providerId, seriesId);
}

class TvDetailPanel extends ConsumerWidget {
  const TvDetailPanel({
    required this.item,
    required this.onOpenPlayer,
    super.key,
  });

  final CatalogCardItem item;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesValue = item.contentType == CatalogContentType.series
        ? ref.watch(
            _tvSeriesEpisodesProvider(
              _TvSeriesEpisodesQuery(
                providerId: item.providerId,
                seriesId: item.id,
              ),
            ),
          )
        : const AsyncValue<List<CatalogEpisode>>.data(<CatalogEpisode>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
        ),
        const SizedBox(height: 16),
        TvFocusCard(
          autofocus: true,
          onPressed: () async {
            final target = await playbackTargetForCatalogCard(ref, item);
            if (target != null) onOpenPlayer(target.playable);
          },
          child: Text(item.seriesPlaybackLabel ?? (item.hasResume ? 'Resume' : 'Play')),
        ),
        const SizedBox(height: 18),
        if (item.contentType == CatalogContentType.series)
          Expanded(
            child: episodesValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (episodes) => ListView.separated(
                itemCount: episodes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  return TvFocusCard(
                    onPressed: () async {
                      final target = await playbackTargetForCatalogEpisode(
                        ref,
                        episode: episode,
                        episodes: episodes,
                        fallbackPosterUrl: item.artworkUrl,
                      );
                      if (target != null) onOpenPlayer(target.playable);
                    },
                    child: Text(
                      'S${episode.seasonNumber} E${episode.episodeNumber}  ${episode.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
```

Series cards must use this panel path: the grid selects the series card, the panel shows Play/Resume plus episode rows, and each episode row opens `PlayableKind.episode` through `playbackTargetForCatalogEpisode`.

- [ ] **Step 6: Verify TV catalog compiles**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 7: Commit TV catalog**

Run:

```bash
git add lib/src/tv lib/src/features/catalog
git commit -m "feat: add android tv catalog browser"
```

---

### Task 8: TV Remote Playback and Fullscreen Safety

**Files:**
- Modify: `lib/src/playback/playback_controller.dart`
- Modify: `lib/src/playback/vela_player_route.dart`
- Modify: `lib/src/playback/vela_player_controls.dart` to keep focus labels and control hit areas TV-safe.
- Use: `lib/src/platform/vela_windowing.dart`

- [ ] **Step 1: Remove direct fullscreen window manager use from playback controller**

In `lib/src/playback/playback_controller.dart`, remove:

```dart
import 'dart:io';
import 'package:window_manager/window_manager.dart';
```

Import:

```dart
import '../platform/vela_windowing.dart';
```

Add field:

```dart
final VelaFullscreenController _fullscreenController = VelaFullscreenController();
```

Replace `toggleFullscreen`, `exitFullscreenIfNeeded`, `_setFullscreen`, `_prepareWindowForFullscreen`, and `_restoreWindowAfterFullscreen` with:

```dart
Future<void> toggleFullscreen() async {
  await _fullscreenController.toggleFullscreen();
  _emit(_state.copyWith(isFullscreen: _fullscreenController.isFullscreen));
}

Future<void> exitFullscreenIfNeeded() async {
  await _fullscreenController.exitFullscreenIfNeeded();
  _emit(_state.copyWith(isFullscreen: _fullscreenController.isFullscreen));
}

Future<void> _syncFullscreen() async {
  await _fullscreenController.refreshFullscreenState();
  if (!_disposed) {
    _emit(_state.copyWith(isFullscreen: _fullscreenController.isFullscreen));
  }
}
```

- [ ] **Step 2: Replace player window close intercept**

In `lib/src/playback/vela_player_route.dart`, remove:

```dart
import 'package:window_manager/window_manager.dart';
```

Remove `with WindowListener` from `_VelaPlayerRouteState`.

Import:

```dart
import '../platform/vela_windowing.dart';
```

Add field:

```dart
late final VelaWindowCloseGuard _windowCloseGuard;
```

In `initState`, before enabling close intercept:

```dart
_windowCloseGuard = VelaWindowCloseGuard(onClose: _close);
unawaited(_windowCloseGuard.enable());
```

Remove `windowManager.addListener(this)`, `windowManager.removeListener(this)`, `_enableWindowCloseIntercept`, `_restoreWindowCloseBehavior`, and `onWindowClose`.

In `dispose`, call:

```dart
unawaited(_windowCloseGuard.disable());
```

In `_cleanupPlayback`, replace `_restoreWindowCloseBehavior()` with:

```dart
await _windowCloseGuard.disable();
```

- [ ] **Step 3: Add Android TV remote key aliases**

In `_handleKey`, treat select/enter as play/pause or control activation when overlay is visible:

```dart
case LogicalKeyboardKey.select:
case LogicalKeyboardKey.enter:
  _controller.togglePlayPause();
case LogicalKeyboardKey.goBack:
case LogicalKeyboardKey.browserBack:
  unawaited(_close());
```

Add these keys to `_isPlayerShortcutKey`.

- [ ] **Step 4: Keep Android TV immersive mode after player close**

In `_cleanupPlayback`, after fullscreen cleanup, Android should stay immersive. This is already handled by `VelaFullscreenController.exitFullscreenIfNeeded`; confirm that no desktop window call runs on Android.

- [ ] **Step 5: Verify playback compiles**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 6: Commit playback platform safety**

Run:

```bash
git add lib/src/playback lib/src/platform
git commit -m "feat: adapt playback for android tv"
```

---

### Task 9: Android Update Guidance

**Files:**
- Modify: `lib/src/updates/update_checker.dart`
- Modify: `lib/src/tv/vela_tv_shell.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

- [ ] **Step 1: Add URL launcher**

Run:

```bash
flutter pub add url_launcher
```

Expected:

```text
Changed 1 dependency!
```

- [ ] **Step 2: Add release asset model**

Extend `UpdateStatus`:

```dart
class UpdateStatus {
  const UpdateStatus({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
    required this.checkedAt,
    this.androidApkUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;
  final DateTime checkedAt;
  final String? androidApkUrl;
}
```

Parse assets in `GitHubUpdateChecker.check()`:

```dart
final assets = body['assets'];
String? androidApkUrl;
if (assets is List<Object?>) {
  for (final asset in assets) {
    if (asset is! Map<String, Object?>) continue;
    final name = asset['name'] as String? ?? '';
    final downloadUrl = asset['browser_download_url'] as String?;
    if (name.endsWith('.apk') && name.contains('android-tv')) {
      androidApkUrl = downloadUrl;
      break;
    }
  }
}
```

Pass `androidApkUrl` into `UpdateStatus`.

- [ ] **Step 3: Prefer APK URL in TV shell**

In `lib/src/tv/vela_tv_shell.dart`, update the update button action:

```dart
final updateUrl = updateStatus?.androidApkUrl ?? updateStatus?.releaseUrl;
```

Use `updateUrl` for `openExternalUrl`.

- [ ] **Step 4: Make external URL opening cross-platform**

In `lib/src/updates/update_checker.dart`, remove:

```dart
import 'dart:io';
```

Import:

```dart
import 'package:url_launcher/url_launcher.dart';
```

Replace `openExternalUrl` with:

```dart
Future<void> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    throw const UpdateCheckException('Release URL is invalid');
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw const UpdateCheckException('Could not open release URL');
  }
}
```

- [ ] **Step 5: Verify update code compiles**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 6: Commit update guidance**

Run:

```bash
git add pubspec.yaml pubspec.lock lib/src/updates/update_checker.dart lib/src/tv/vela_tv_shell.dart
git commit -m "feat: add android update asset guidance"
```

---

### Task 10: Android TV Packaging Script

**Files:**
- Create: `scripts/package-android-tv.sh`
- Modify: `docs/release-checklist.md`

- [ ] **Step 1: Add packaging script**

Create `scripts/package-android-tv.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
BUILD_DIR="$ROOT/build/app/outputs/flutter-apk"
RELEASE_DIR="$ROOT/release"
APK_SOURCE="$BUILD_DIR/app-release.apk"
APK_TARGET="$RELEASE_DIR/vela-android-tv-v$VERSION.apk"

mkdir -p "$RELEASE_DIR"

dart run scripts/verify_version_sync.dart
flutter pub get
flutter analyze
flutter build apk --release

if [[ ! -f "$APK_SOURCE" ]]; then
  echo "Expected APK not found at $APK_SOURCE" >&2
  exit 1
fi

cp "$APK_SOURCE" "$APK_TARGET"
shasum -a 256 "$APK_TARGET" > "$RELEASE_DIR/SHA256SUMS-android-tv-v$VERSION.txt"

echo "Android TV APK: $APK_TARGET"
echo "Checksum: $RELEASE_DIR/SHA256SUMS-android-tv-v$VERSION.txt"
```

Make it executable:

```bash
chmod +x scripts/package-android-tv.sh
```

- [ ] **Step 2: Document Android release flow**

Append to `docs/release-checklist.md`:

```markdown
## Android TV

- Confirm Android SDK is installed: `flutter doctor -v`
- Build APK: `scripts/package-android-tv.sh`
- Install on Android TV/emulator:
  `adb install -r release/vela-android-tv-v<version>.apk`
- Smoke check:
  - App appears in Android TV launcher.
  - D-pad reaches provider setup fields.
  - Xtream provider imports.
  - Live channel plays.
  - Movie or episode plays.
  - Back exits player without quitting Vela.
- Upload APK and checksum to the GitHub release.
```

- [ ] **Step 3: Verify script shell syntax**

Run:

```bash
bash -n scripts/package-android-tv.sh
```

Expected: command exits with code `0`.

- [ ] **Step 4: Commit packaging**

Run:

```bash
git add scripts/package-android-tv.sh docs/release-checklist.md
git commit -m "chore: add android tv packaging flow"
```

---

### Task 11: Android Build and Device Smoke

**Files:**
- Inspect and fix concrete files reported by Android build/device verification.

- [ ] **Step 1: Confirm Android SDK**

Run:

```bash
flutter doctor -v
```

Expected: Android toolchain has a checkmark. If it is missing, install Android Studio and Android SDK, or run the build on a machine/runner that has Android tooling.

- [ ] **Step 2: Build APK**

Run:

```bash
scripts/package-android-tv.sh
```

Expected:

```text
Android TV APK: .../release/vela-android-tv-v<version>.apk
```

- [ ] **Step 3: Install on Android TV target**

Run:

```bash
adb devices
adb install -r release/vela-android-tv-v$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1).apk
```

Expected:

```text
Success
```

- [ ] **Step 4: Manual smoke checklist**

Complete these checks on an Android TV emulator or physical device:

```text
[ ] Vela appears in the Android TV launcher.
[ ] Remote up/down/left/right/select can reach setup fields.
[ ] Local File provider type is not shown on Android TV.
[ ] Xtream provider import shows progress and only unlocks app after success.
[ ] Live section opens after import.
[ ] Movies and Series sections are reachable.
[ ] A live channel starts playback.
[ ] A movie or episode starts playback.
[ ] Back in player returns to catalog and does not quit the app.
[ ] Audio/subtitle/video menus are reachable when tracks exist.
```

- [ ] **Step 5: Commit device-fix changes if any**

If smoke checks required changes:

```bash
git status --short
git add android lib/src/tv lib/src/playback lib/src/platform
git commit -m "fix: stabilize android tv smoke flow"
```

If no changes were needed, do not create an empty commit.

---

### Task 12: Desktop Regression Check

**Files:**
- Inspect and fix concrete files reported by desktop verification.

- [ ] **Step 1: Run shared verification**

Run:

```bash
dart run scripts/verify_version_sync.dart
flutter analyze
```

Expected:

```text
Version metadata is synced: 0.4.4+10
No issues found!
```

- [ ] **Step 2: Build macOS**

Run:

```bash
flutter build macos
```

Expected: build completes successfully.

- [ ] **Step 3: Confirm desktop shell still selected on macOS**

Run the app on macOS:

```bash
flutter run -d macos
```

Expected:

```text
The existing desktop sidebar shell appears, not the TV shell.
```

- [ ] **Step 4: Commit regression fixes if any**

If changes were required:

```bash
git status --short
git add lib/main.dart lib/src/app lib/src/shell lib/src/playback lib/src/platform
git commit -m "fix: preserve desktop behavior with android tv"
```

If no changes were required, do not create an empty commit.

---

## Final Readiness

- [ ] `git status --short --branch` shows a clean `feature/android-tv` branch.
- [ ] `flutter analyze` passes.
- [ ] `scripts/package-android-tv.sh` passes on a machine with Android SDK.
- [ ] Android TV smoke checklist is complete.
- [ ] macOS desktop shell still runs.
- [ ] Push branch:

```bash
git push -u origin feature/android-tv
```
