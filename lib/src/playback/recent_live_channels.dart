import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation_controller.dart';
import '../catalog/catalog_models.dart';
import '../providers/xtream/xtream_client.dart';
import 'playable_item.dart';

const _recentLiveChannelLimit = 10;

final recentLiveChannelsProvider = StreamProvider.autoDispose
    .family<List<PlayableItem>, String?>((ref, currentLiveKey) {
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      return historyRepository.watchRecentlyWatched(limit: 80).asyncMap((
        entries,
      ) {
        return _resolveRecentLiveChannels(ref, entries, currentLiveKey);
      });
    });

String liveChannelKey(String providerId, String itemId) {
  return '$providerId::$itemId';
}

String? liveChannelKeyForItem(PlayableItem? item) {
  if (item == null || item.kind != PlayableKind.live) return null;
  return liveChannelKey(item.providerId, item.id);
}

Future<List<PlayableItem>> _resolveRecentLiveChannels(
  Ref ref,
  List<WatchHistoryEntry> entries,
  String? currentLiveKey,
) async {
  final catalogRepository = ref.read(catalogRepositoryProvider);
  final channels = <PlayableItem>[];
  final seen = <String>{};

  for (final entry in entries) {
    if (entry.itemType != PlayableContentType.live) {
      continue;
    }

    final key = liveChannelKey(entry.providerId, entry.itemId);
    if (key == currentLiveKey || !seen.add(key)) {
      continue;
    }

    final item = await catalogRepository.getItem(
      providerId: entry.providerId,
      contentType: CatalogContentType.live,
      id: entry.itemId,
    );
    if (item == null) {
      continue;
    }

    final playable = await _playableLiveItem(ref, item);
    if (playable == null) {
      continue;
    }

    channels.add(playable);
    if (channels.length >= _recentLiveChannelLimit) {
      break;
    }
  }

  return channels;
}

Future<PlayableItem?> _playableLiveItem(Ref ref, CatalogItem item) async {
  final url = await _streamUrl(
    ref,
    providerId: item.providerId,
    contentType: item.contentType,
    streamUrl: item.streamUrl,
    streamJson: item.streamJson,
  );
  if (url == null) return null;

  return PlayableItem(
    id: item.id,
    providerId: item.providerId,
    title: item.title,
    subtitle: item.subtitle,
    streamUrl: url,
    kind: PlayableKind.live,
    channelLogoUrl: item.artworkUrl,
    durationSeconds: item.durationSeconds,
  );
}

Future<String?> _streamUrl(
  Ref ref, {
  required String providerId,
  required CatalogContentType contentType,
  String? streamUrl,
  String? streamJson,
}) async {
  if (streamUrl?.trim().isNotEmpty == true) {
    return streamUrl!.trim();
  }
  if (streamJson?.trim().isEmpty != false) {
    return null;
  }

  final data = jsonDecode(streamJson!) as Map<String, dynamic>;
  if (data['providerType'] != 'xtream') {
    return null;
  }

  final provider = await ref
      .read(providerRepositoryProvider)
      .getProvider(providerId);
  if (provider == null ||
      provider.serverUrl == null ||
      provider.username == null ||
      provider.password == null) {
    return null;
  }

  final client = XtreamClient(
    credentials: XtreamCredentials(
      serverUrl: provider.serverUrl!,
      username: provider.username!,
      password: provider.password!,
    ),
  );
  try {
    final streamId = data['streamId']?.toString();
    if (streamId == null || streamId.isEmpty) return null;
    final extension =
        data['containerExtension']?.toString() ??
        (contentType == CatalogContentType.live ? 'ts' : 'mp4');
    return switch (contentType) {
      CatalogContentType.live => client.buildLiveStreamUrl(
        streamId,
        containerExtension: extension,
      ),
      CatalogContentType.movie => client.buildMovieStreamUrl(
        streamId,
        containerExtension: extension,
      ),
      CatalogContentType.series => client.buildSeriesStreamUrl(
        streamId,
        containerExtension: extension,
      ),
    };
  } finally {
    client.close();
  }
}
