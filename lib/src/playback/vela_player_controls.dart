import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'playback_controller.dart';
import 'playable_item.dart';
import 'player_state.dart';
import 'track_models.dart';

class VelaPlayerControls extends StatelessWidget {
  const VelaPlayerControls({
    required this.controller,
    required this.state,
    required this.onClose,
    required this.onNextEpisode,
    super.key,
  });

  final PlaybackController controller;
  final VelaPlayerState state;
  final VoidCallback onClose;
  final ValueChanged<PlayableItem> onNextEpisode;

  @override
  Widget build(BuildContext context) {
    final item = state.item;

    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB0000000),
                    Color(0x00000000),
                    Color(0xD9000000),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: _TopBar(item: item, onClose: onClose),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Timeline(controller: controller, state: state),
                const SizedBox(height: 12),
                _ControlRow(
                  controller: controller,
                  state: state,
                  onNextEpisode: onNextEpisode,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.item, required this.onClose});

  final PlayableItem? item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _RoundIconButton(
          tooltip: 'Back',
          icon: LucideIcons.arrowLeft,
          onPressed: onClose,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item?.title ?? 'Vela Player',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              if (item?.subtitle != null && item!.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item!.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC8C2B8),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.controller, required this.state});

  final PlaybackController controller;
  final VelaPlayerState state;

  @override
  Widget build(BuildContext context) {
    final canSeek = state.isSeekable;
    final hasDuration = state.duration > Duration.zero;
    final max = canSeek ? state.duration.inMilliseconds.toDouble() : 1.0;
    final value = state.position.inMilliseconds
        .clamp(0, max.toInt())
        .toDouble();
    final bufferValue = canSeek && state.buffer > Duration.zero
        ? state.buffer.inMilliseconds
              .clamp(value.round(), max.round())
              .toDouble()
        : null;

    return Row(
      children: [
        Text(_formatDuration(state.position), style: _timeStyle(context)),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.white,
              secondaryActiveTrackColor: const Color(0x66FFFFFF),
              inactiveTrackColor: const Color(0x66FFFFFF),
              thumbColor: Colors.white,
              overlayColor: const Color(0x33FFFFFF),
            ),
            child: Slider(
              min: 0,
              max: max,
              value: value,
              secondaryTrackValue: bufferValue,
              onChanged: canSeek
                  ? (next) {
                      controller.seekTo(Duration(milliseconds: next.round()));
                    }
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          state.isLive || !hasDuration
              ? 'LIVE'
              : _formatDuration(state.duration),
          style: _timeStyle(context),
        ),
      ],
    );
  }

  TextStyle? _timeStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
      color: const Color(0xFFD8D2C8),
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0,
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.controller,
    required this.state,
    required this.onNextEpisode,
  });

  final PlaybackController controller;
  final VelaPlayerState state;
  final ValueChanged<PlayableItem> onNextEpisode;

  @override
  Widget build(BuildContext context) {
    final item = state.item;
    final canSeek = state.isSeekable;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RoundIconButton(
          tooltip: state.playing ? 'Pause' : 'Play',
          icon: state.playing ? LucideIcons.pause : LucideIcons.play,
          isPrimary: true,
          onPressed: controller.togglePlayPause,
        ),
        _RoundIconButton(
          tooltip: 'Rewind 10 seconds',
          icon: LucideIcons.rotateCcw,
          label: '10',
          onPressed: canSeek
              ? () => controller.seekRelative(const Duration(seconds: -10))
              : null,
        ),
        _RoundIconButton(
          tooltip: 'Forward 10 seconds',
          icon: LucideIcons.rotateCw,
          label: '10',
          onPressed: canSeek
              ? () => controller.seekRelative(const Duration(seconds: 10))
              : null,
        ),
        _VolumeControl(controller: controller, state: state),
        _AudioMenu(controller: controller, tracks: state.audioTracks),
        _SubtitleMenu(controller: controller, tracks: state.subtitleTracks),
        _VideoMenu(controller: controller, tracks: state.videoTracks),
        _SpeedMenu(controller: controller, speed: state.playbackSpeed),
        if (item?.nextEpisode != null)
          FilledButton.icon(
            onPressed: () => onNextEpisode(item!.nextEpisode!),
            icon: const Icon(LucideIcons.chevronsRight, size: 18),
            label: const Text('Next Episode'),
          ),
        _RoundIconButton(
          tooltip: state.isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
          icon: state.isFullscreen
              ? LucideIcons.minimize
              : LucideIcons.maximize,
          onPressed: controller.toggleFullscreen,
        ),
      ],
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({required this.controller, required this.state});

  final PlaybackController controller;
  final VelaPlayerState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: _controlDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: state.isMuted ? 'Unmute' : 'Mute',
            onPressed: controller.toggleMute,
            icon: Icon(
              state.isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
              size: 20,
            ),
          ),
          SizedBox(
            width: 112,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: const Color(0x55FFFFFF),
                thumbColor: Colors.white,
              ),
              child: Slider(
                min: 0,
                max: 100,
                value: state.volume.clamp(0, 100).toDouble(),
                onChanged: controller.setVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioMenu extends StatelessWidget {
  const _AudioMenu({required this.controller, required this.tracks});

  final PlaybackController controller;
  final List<PlaybackAudioTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return _MenuButton<PlaybackAudioTrack>(
      tooltip: 'Audio tracks',
      icon: LucideIcons.audioLines,
      emptyLabel: 'No audio tracks',
      items: tracks,
      compactLabel: _selectedTrackLabel(tracks, fallback: 'Audio'),
      labelFor: (track) => _trackLabel(track.title, track.language),
      valueFor: (track) => track.id,
      selectedFor: (track) => track.isSelected,
      onSelected: controller.selectAudioTrack,
    );
  }
}

class _SubtitleMenu extends StatelessWidget {
  const _SubtitleMenu({required this.controller, required this.tracks});

  final PlaybackController controller;
  final List<PlaybackSubtitleTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final hasOffTrack = tracks.any((track) => track.id == 'no');
    final offSelected =
        tracks.any((track) => track.id == 'no' && track.isSelected) ||
        !tracks.any((track) => track.isSelected);

    return PopupMenuButton<String>(
      tooltip: 'Subtitle tracks',
      color: const Color(0xFF17191C),
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      onSelected: (value) {
        if (value == 'off') {
          controller.turnSubtitlesOff();
          return;
        }
        controller.selectSubtitleTrack(value);
      },
      itemBuilder: (context) {
        return [
          if (!hasOffTrack)
            PopupMenuItem(
              value: 'off',
              child: _MenuRow(label: 'Off', selected: offSelected),
            ),
          for (final track in tracks)
            PopupMenuItem(
              value: track.id == 'no' ? 'off' : track.id,
              child: _MenuRow(
                label: _trackLabel(track.title, track.language),
                selected: track.isSelected,
              ),
            ),
        ];
      },
      child: _MenuIcon(
        icon: LucideIcons.subtitles,
        compactLabel: offSelected
            ? 'Subtitles off'
            : _selectedTrackLabel(tracks, fallback: 'Subtitles'),
      ),
    );
  }
}

class _VideoMenu extends StatelessWidget {
  const _VideoMenu({required this.controller, required this.tracks});

  final PlaybackController controller;
  final List<PlaybackVideoTrack> tracks;

  @override
  Widget build(BuildContext context) {
    return _MenuButton<PlaybackVideoTrack>(
      tooltip: 'Video tracks',
      icon: LucideIcons.monitorPlay,
      emptyLabel: 'No video tracks',
      items: tracks,
      compactLabel: _selectedTrackLabel(tracks, fallback: 'Video'),
      labelFor: (track) => _trackLabel(track.title, track.language),
      valueFor: (track) => track.id,
      selectedFor: (track) => track.isSelected,
      onSelected: controller.selectVideoTrack,
    );
  }
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({required this.controller, required this.speed});

  static const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  final PlaybackController controller;
  final double speed;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Playback speed',
      color: const Color(0xFF17191C),
      elevation: 8,
      onSelected: controller.setPlaybackSpeed,
      itemBuilder: (context) {
        return [
          for (final option in speeds)
            PopupMenuItem(
              value: option,
              child: _MenuRow(
                label: option == 1.0 ? 'Normal' : '${option}x',
                selected: (speed - option).abs() < 0.01,
              ),
            ),
        ];
      },
      child: _MenuIcon(
        icon: LucideIcons.gauge,
        compactLabel: speed == 1.0 ? '1x' : '${speed}x',
      ),
    );
  }
}

class _MenuButton<T> extends StatelessWidget {
  const _MenuButton({
    required this.tooltip,
    required this.icon,
    required this.emptyLabel,
    required this.items,
    required this.compactLabel,
    required this.labelFor,
    required this.valueFor,
    required this.selectedFor,
    required this.onSelected,
  });

  final String tooltip;
  final IconData icon;
  final String emptyLabel;
  final List<T> items;
  final String compactLabel;
  final String Function(T item) labelFor;
  final String Function(T item) valueFor;
  final bool Function(T item) selectedFor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      color: const Color(0xFF17191C),
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      enabled: items.isNotEmpty,
      onSelected: onSelected,
      itemBuilder: (context) {
        if (items.isEmpty) {
          return [PopupMenuItem(enabled: false, child: Text(emptyLabel))];
        }
        return [
          for (final item in items)
            PopupMenuItem(
              value: valueFor(item),
              child: _MenuRow(
                label: labelFor(item),
                selected: selectedFor(item),
              ),
            ),
        ];
      },
      child: _MenuIcon(icon: icon, compactLabel: compactLabel),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon({required this.icon, this.compactLabel});

  final IconData icon;
  final String? compactLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      constraints: const BoxConstraints(minWidth: 44, maxWidth: 190),
      decoration: _controlDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          if (compactLabel != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                compactLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.label,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimary ? Colors.black : Colors.white;
    final background = isPrimary ? Colors.white : const Color(0x66000000);
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: isPrimary
                ? null
                : Border.all(color: const Color(0x2EFFFFFF)),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? foreground : foreground.withAlpha(89),
                  size: 20,
                ),
                if (label != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      label!,
                      style: TextStyle(
                        color: isEnabled
                            ? foreground
                            : foreground.withAlpha(89),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _controlDecoration() {
  return BoxDecoration(
    color: const Color(0x66000000),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0x2EFFFFFF)),
  );
}

String _trackLabel(String title, String? language) {
  if (language == null || language.trim().isEmpty) return title;
  return '$title (${language.trim()})';
}

String _selectedTrackLabel<T>(List<T> tracks, {required String fallback}) {
  for (final track in tracks) {
    final isSelected = switch (track) {
      PlaybackAudioTrack item => item.isSelected,
      PlaybackSubtitleTrack item => item.isSelected,
      PlaybackVideoTrack item => item.isSelected,
      _ => false,
    };
    if (!isSelected) {
      continue;
    }
    return switch (track) {
      PlaybackAudioTrack item => _trackLabel(item.title, item.language),
      PlaybackSubtitleTrack item => _trackLabel(item.title, item.language),
      PlaybackVideoTrack item => _trackLabel(item.title, item.language),
      _ => fallback,
    };
  }
  return fallback;
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
