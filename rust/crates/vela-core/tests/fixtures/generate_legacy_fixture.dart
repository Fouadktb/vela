// Run from the legacy Flutter checkout using flutter test <this file>.
// Fixture data is entirely synthetic; never open the user's installed database.
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vela/src/app/navigation_controller.dart';
import 'package:vela/src/catalog/catalog_database.dart';
import 'package:vela/src/catalog/catalog_models.dart';
import 'package:vela/src/catalog/catalog_repository.dart';
import 'package:vela/src/catalog/category_repository.dart';
import 'package:vela/src/catalog/watch_history_repository.dart';

void main() {
  test('generate synthetic real Drift schema4 fixture', () async {
    final fixture=File('rust/crates/vela-core/tests/fixtures/flutter_schema4.sqlite');
    if (fixture.existsSync()) fixture.deleteSync();
    final db=CatalogDatabase(NativeDatabase(fixture));
    final catalog=CatalogRepository(db);
    await catalog.createOrUpdateProvider(const CatalogProviderInput(
      id:'fixture',type:CatalogProviderType.xtream,name:'Synthetic provider',
      source:'https://fixture.invalid',username:'fake-user',password:'fake-password',
    ));
    await catalog.replaceProviderCatalog(const ProviderCatalogSnapshot(
      providerId:'fixture',refreshedAtMs:1700000000000,
      categories:[CatalogCategoryInput(providerId:'fixture',contentType:CatalogContentType.movie,name:'Films & More')],
      items:[
        CatalogItemInput(id:'movie',providerId:'fixture',contentType:CatalogContentType.movie,title:'Fixture Movie',categoryName:'Films & More',streamUrl:'https://fixture.invalid/movie.ts'),
        CatalogItemInput(id:'series:one',providerId:'fixture',contentType:CatalogContentType.series,title:'Fixture Show',categoryName:'Shows'),
      ],
      series:[SeriesInput(id:'external-series',catalogItemId:'series:one',providerId:'fixture',title:'Fixture Show')],
      seasons:[SeasonInput(id:'upstream-season',providerId:'fixture',seriesId:'series:one',seasonNumber:1)],
      episodes:[EpisodeInput(id:'episode:one',providerId:'fixture',seriesId:'series:one',seasonId:'1',seasonNumber:1,episodeNumber:1,title:'Fixture Pilot',streamUrl:'https://fixture.invalid/episode.ts')],
    ));
    await catalog.toggleItemFavorite(providerId:'fixture',itemType:FavoriteItemType.movie,itemId:'movie');
    final categories=CategoryRepository(db);
    final films=catalogCategoryId('fixture',CatalogContentType.movie,'Films & More');
    await categories.toggleCategoryFavorite(providerId:'fixture',contentType:CatalogContentType.movie,categoryId:films);
    await categories.reorderCategories(providerId:'fixture',contentType:CatalogContentType.movie,categoryIds:[films]);
    await catalog.replaceProviderEpg(providerId:'fixture',programs:[const EpgProgramInput(providerId:'fixture',channelId:'fixture-channel',startAtMs:1700000000000,endAtMs:1700003600000,title:'Fixture News')]);
    final settings=AppSettingsRepository(db);
    await settings.setValue('language','de');
    await settings.setValue('playback_output_volume','{"volume":0,"lastAudibleVolume":27}');
    await settings.setValue('playback_track_preferences:fixture:movie:movie','{"audio":{"id":"2","title":"German","language":"de"}}');
    await WatchHistoryRepository(db).addOrUpdateWatchHistory(const WatchHistoryUpdate(
      itemId:'episode:one',itemType:PlayableContentType.episode,providerId:'fixture',title:'Fixture Pilot',seriesId:'series:one',seasonId:'1',positionSeconds:123,durationSeconds:1000,completionPercentage:.123,watchedAtMs:1700000000000,
    ));
    await catalog.createRefreshRun(id:'fixture-run',providerId:'fixture',startedAtMs:1700000000000);
    await catalog.finishRefreshRun(id:'fixture-run',status:ProviderRefreshStatus.succeeded,itemCount:2,finishedAtMs:1700000000001);
    await db.close();
    expect(fixture.lengthSync(),greaterThan(0));
  });
}
