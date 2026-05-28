import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalog/catalog_models.dart';
import '../../shared/empty_state.dart';
import 'item_grid.dart';

const _channelColumnWidth = 238.0;
const _timelineWidth = 2304.0;
const _headerHeight = 46.0;
const _rowHeight = 88.0;

class LiveGuideView extends StatefulWidget {
  const LiveGuideView({
    required this.items,
    required this.selectedItemId,
    required this.dayStartMs,
    required this.epgPrograms,
    required this.onSelect,
    required this.onOpen,
    required this.onRefreshEpg,
    required this.onDayChanged,
    super.key,
  });

  final List<CatalogCardItem> items;
  final String? selectedItemId;
  final int dayStartMs;
  final AsyncValue<List<EpgProgram>> epgPrograms;
  final ValueChanged<String> onSelect;
  final ValueChanged<CatalogCardItem> onOpen;
  final VoidCallback onRefreshEpg;
  final ValueChanged<int> onDayChanged;

  @override
  State<LiveGuideView> createState() => _LiveGuideViewState();
}

class _LiveGuideViewState extends State<LiveGuideView> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.epgPrograms.when(
      data: (programs) {
        _syncDayIfNeeded();
        final day = _GuideDay.fromStartMs(widget.dayStartMs);
        final todayPrograms = programs
            .where((program) => _overlapsDay(program, day))
            .toList();
        if (todayPrograms.isEmpty) {
          return _MissingGuideState(onRefreshEpg: widget.onRefreshEpg);
        }

        final programsByChannel = _programsByChannel(
          widget.items,
          todayPrograms,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              controller: _horizontalController,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _channelColumnWidth + _timelineWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      _GuideHeader(day: day, now: _now),
                      Expanded(
                        child: Scrollbar(
                          controller: _verticalController,
                          child: ListView.separated(
                            controller: _verticalController,
                            padding: const EdgeInsets.fromLTRB(0, 0, 18, 28),
                            itemCount: widget.items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              return _GuideRow(
                                item: item,
                                selected: item.id == widget.selectedItemId,
                                programs:
                                    programsByChannel[item.id] ??
                                    const <EpgProgram>[],
                                day: day,
                                now: _now,
                                onSelect: () => widget.onSelect(item.id),
                                onOpen: item.canPlay
                                    ? () => widget.onOpen(item)
                                    : null,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        icon: LucideIcons.calendarX,
        title: 'Guide unavailable',
        message: 'The provider guide could not be loaded.',
        action: FilledButton.icon(
          onPressed: widget.onRefreshEpg,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: const Text('Refresh EPG'),
        ),
      ),
    );
  }

  void _syncDayIfNeeded() {
    final currentDayStartMs = _GuideDay.containing(_now).startMs;
    if (currentDayStartMs == widget.dayStartMs) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDayChanged(currentDayStartMs);
      }
    });
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.day, required this.now});

  final _GuideDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorLeft = _positionForMs(now.millisecondsSinceEpoch, day);

    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          Container(
            width: _channelColumnWidth,
            padding: const EdgeInsets.only(left: 14),
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('EEE, MMM d').format(day.start),
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFFD7D0C6),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          SizedBox(
            width: _timelineWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var hour = 0; hour <= 24; hour += 2)
                  Positioned(
                    left: (hour / 24) * _timelineWidth,
                    top: 10,
                    bottom: 0,
                    child: _TimeTick(
                      label: DateFormat.Hm().format(
                        day.start.add(Duration(hours: hour)),
                      ),
                    ),
                  ),
                if (indicatorLeft != null)
                  Positioned(
                    left: indicatorLeft,
                    top: 8,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const SizedBox(width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTick extends StatelessWidget {
  const _TimeTick({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: _headerHeight,
          child: VerticalDivider(width: 1, color: Color(0xFF292D31)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFA9A39A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.item,
    required this.selected,
    required this.programs,
    required this.day,
    required this.now,
    required this.onSelect,
    required this.onOpen,
  });

  final CatalogCardItem item;
  final bool selected;
  final List<EpgProgram> programs;
  final _GuideDay day;
  final DateTime now;
  final VoidCallback onSelect;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final currentMs = now.millisecondsSinceEpoch;
    final sorted = [...programs]
      ..sort((a, b) => a.startAtMs.compareTo(b.startAtMs));
    final current = sorted.where((program) {
      return program.isAiringAt(currentMs);
    }).firstOrNull;
    final next = sorted.where((program) {
      return program.startAtMs > currentMs;
    }).firstOrNull;
    final indicatorLeft = _positionForMs(currentMs, day);

    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _channelColumnWidth,
            child: _ChannelCell(
              item: item,
              selected: selected,
              current: current,
              onTap: () {
                onSelect();
                onOpen?.call();
              },
            ),
          ),
          SizedBox(
            width: _timelineWidth,
            child: Stack(
              children: [
                const Positioned.fill(child: _RowGrid()),
                if (sorted.isEmpty)
                  const Positioned.fill(child: _NoProgramStrip())
                else
                  for (final program in sorted)
                    _ProgramBlock(
                      program: program,
                      day: day,
                      label: program == current
                          ? 'NOW'
                          : program == next
                          ? 'NEXT'
                          : null,
                      isCurrent: program == current,
                      onTap: () {
                        onSelect();
                        if (program == current) {
                          onOpen?.call();
                        }
                      },
                    ),
                if (indicatorLeft != null)
                  Positioned(
                    left: indicatorLeft,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const SizedBox(width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelCell extends StatelessWidget {
  const _ChannelCell({
    required this.item,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final CatalogCardItem item;
  final bool selected;
  final EpgProgram? current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? const Color(0xFF1F211E) : const Color(0xFF151719),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : const Color(0xFF292D31),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: _ChannelArtwork(item: item),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      current?.title ?? item.subtitle ?? 'Live channel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFA9A39A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelArtwork extends StatelessWidget {
  const _ChannelArtwork({required this.item});

  final CatalogCardItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF0F1113)),
        child: item.hasArtwork
            ? Image.network(
                item.artworkUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  LucideIcons.tv,
                  color: Color(0xFF716D66),
                  size: 24,
                ),
              )
            : const Icon(LucideIcons.tv, color: Color(0xFF716D66), size: 24),
      ),
    );
  }
}

class _ProgramBlock extends StatelessWidget {
  const _ProgramBlock({
    required this.program,
    required this.day,
    required this.label,
    required this.isCurrent,
    required this.onTap,
  });

  final EpgProgram program;
  final _GuideDay day;
  final String? label;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = _positionForMs(program.startAtMs, day) ?? 0;
    final right =
        _positionForMs(program.endAtMs, day) ??
        (program.endAtMs <= day.startMs ? 0 : _timelineWidth);
    final width = (right - left).clamp(48.0, _timelineWidth - left);

    return Positioned(
      left: left,
      top: 0,
      width: width,
      height: _rowHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: Material(
          color: isCurrent ? const Color(0xFF22241F) : const Color(0xFF16191B),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : const Color(0xFF292D31),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (label != null) ...[
                        _ProgramLabel(label: label!, isCurrent: isCurrent),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          _timeRange(program),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFA9A39A),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    program.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramLabel extends StatelessWidget {
  const _ProgramLabel({required this.label, required this.isCurrent});

  final String label;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCurrent
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF292D31),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isCurrent
                ? const Color(0xFF0C0D0E)
                : const Color(0xFFD7D0C6),
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _RowGrid extends StatelessWidget {
  const _RowGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var hour = 0; hour < 24; hour++)
          const SizedBox(
            width: _timelineWidth / 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFF1F2326))),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoProgramStrip extends StatelessWidget {
  const _NoProgramStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFF121416),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No guide data for this channel today',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFFA9A39A)),
      ),
    );
  }
}

class _MissingGuideState extends StatelessWidget {
  const _MissingGuideState({required this.onRefreshEpg});

  final VoidCallback onRefreshEpg;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.calendarClock,
      title: 'No guide data available',
      message:
          'This provider has not returned EPG programs for the visible live channels.',
      action: FilledButton.icon(
        onPressed: onRefreshEpg,
        icon: const Icon(LucideIcons.refreshCw, size: 18),
        label: const Text('Refresh EPG'),
      ),
    );
  }
}

class _GuideDay {
  const _GuideDay({required this.start, required this.end});

  factory _GuideDay.fromStartMs(int startMs) {
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    return _GuideDay(start: start, end: start.add(const Duration(days: 1)));
  }

  factory _GuideDay.containing(DateTime value) {
    final start = DateTime(value.year, value.month, value.day);
    return _GuideDay(start: start, end: start.add(const Duration(days: 1)));
  }

  final DateTime start;
  final DateTime end;

  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;
}

Map<String, List<EpgProgram>> _programsByChannel(
  List<CatalogCardItem> items,
  List<EpgProgram> programs,
) {
  final programsByAlias = <String, List<EpgProgram>>{};
  for (final program in programs) {
    final key = _providerAliasKey(program.providerId, program.channelId);
    programsByAlias.putIfAbsent(key, () => []).add(program);
  }

  return {
    for (final item in items)
      item.id: _dedupePrograms([
        for (final alias in epgChannelAliases(item))
          ...programsByAlias[_providerAliasKey(item.providerId, alias)] ??
              const <EpgProgram>[],
      ]),
  };
}

List<EpgProgram> _dedupePrograms(List<EpgProgram> programs) {
  final seen = <String>{};
  final deduped = <EpgProgram>[];
  for (final program in programs) {
    final key = [
      program.providerId,
      program.startAtMs,
      program.endAtMs,
      program.title,
    ].join('\x1f');
    if (seen.add(key)) {
      deduped.add(program);
    }
  }
  deduped.sort((a, b) => a.startAtMs.compareTo(b.startAtMs));
  return deduped;
}

String _providerAliasKey(String providerId, String alias) {
  return '$providerId\x1f$alias';
}

List<String> epgChannelAliases(CatalogCardItem item) {
  final aliases = <String>[
    if (item.epgChannelId?.trim().isNotEmpty == true) item.epgChannelId!.trim(),
    if (item.externalId?.trim().isNotEmpty == true) item.externalId!.trim(),
    if (item.title.trim().isNotEmpty) item.title.trim(),
    _trailingCatalogId(item.id),
  ];
  return aliases.where((value) => value.trim().isNotEmpty).toSet().toList();
}

bool _overlapsDay(EpgProgram program, _GuideDay day) {
  return program.endAtMs > day.startMs && program.startAtMs < day.endMs;
}

double? _positionForMs(int timestampMs, _GuideDay day) {
  if (timestampMs < day.startMs || timestampMs > day.endMs) {
    return null;
  }
  final progress = (timestampMs - day.startMs) / (day.endMs - day.startMs);
  return (progress * _timelineWidth).clamp(0.0, _timelineWidth).toDouble();
}

String _timeRange(EpgProgram program) {
  final format = DateFormat.Hm();
  final start = DateTime.fromMillisecondsSinceEpoch(program.startAtMs);
  final end = DateTime.fromMillisecondsSinceEpoch(program.endAtMs);
  return '${format.format(start)}-${format.format(end)}';
}

String _trailingCatalogId(String value) {
  final separator = value.lastIndexOf(':');
  if (separator < 0 || separator >= value.length - 1) {
    return value;
  }
  return value.substring(separator + 1);
}
