import 'package:flutter/widgets.dart';

import 'section_state.dart';

class VelaStrings {
  const VelaStrings();

  static const english = VelaStrings();

  static VelaStrings of(BuildContext context) {
    return english;
  }

  TextDirection get textDirection => TextDirection.ltr;

  String sectionLabel(VelaSection section) {
    return switch (section) {
      VelaSection.home => 'Home',
      VelaSection.live => 'Live',
      VelaSection.movies => 'Movies',
      VelaSection.series => 'Series',
      VelaSection.favorites => 'Favorites',
      VelaSection.recent => 'Recent',
      VelaSection.settings => 'Settings',
    };
  }

  String sectionEyebrow(VelaSection section) {
    return switch (section) {
      VelaSection.home => 'Home',
      VelaSection.settings => 'Preferences',
      VelaSection.recent => 'History',
      _ => 'Catalog',
    };
  }

  String sectionSearchPlaceholder(VelaSection section) {
    return switch (section) {
      VelaSection.home => 'Search everything',
      VelaSection.live => 'Search channels',
      VelaSection.movies => 'Search movies',
      VelaSection.series => 'Search series',
      VelaSection.favorites => 'Search favorites',
      VelaSection.recent => 'Search recently watched',
      VelaSection.settings => 'Search settings',
    };
  }

  String sectionEmptyTitle(VelaSection section) {
    return switch (section) {
      VelaSection.home => 'No home rows yet',
      VelaSection.live => 'No live channels',
      VelaSection.movies => 'No movies',
      VelaSection.series => 'No series',
      VelaSection.favorites => 'No favorites yet',
      VelaSection.recent => 'Nothing watched yet',
      VelaSection.settings => 'No providers yet',
    };
  }

  String get homeTitle => 'Home';
  String get homeSubtitle =>
      'Pick up where you left off or browse what is new.';
  String get homePlay => 'Play';
  String get homeDetails => 'Details';
  String get homeBrowse => 'Browse';
  String get homeContinueWatching => 'Continue Watching';
  String get homeRecentLive => 'Recent Live Channels';
  String get homeLatestMovies => 'Latest Movies';
  String get homeLatestSeries => 'Latest Series';
  String get homeFavorites => 'Favorites';
  String get homePinnedCategories => 'Pinned Categories';
  String get homeEmptyTitle => 'Your home screen is waiting';
  String get homeEmptyBody =>
      'Add a provider or refresh your catalog to fill this screen.';
  String get homeRowsUnavailable => 'Home rows unavailable';
  String get homeNoArtwork => 'No artwork';
}
