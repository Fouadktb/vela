import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:vela/src/providers/provider_models.dart';
import 'package:vela/src/providers/provider_refresh_service.dart';
import 'package:vela/src/providers/provider_repository.dart';

void main() {
  test('failed episode refresh is observed once and can be retried', () async {
    final repository = _FailingProviderRepository();
    final service = ProviderRefreshService(
      providerRepository: repository,
      httpClient: MockClient(
        (request) async => throw StateError('No request expected'),
      ),
    );
    addTearDown(service.dispose);

    for (var attempt = 0; attempt < 2; attempt += 1) {
      await expectLater(
        service.refreshSeriesEpisodeDetails(
          providerId: 'provider',
          seriesId: 'series',
          externalSeriesId: 'external-series',
        ),
        throwsStateError,
      );
    }
    expect(repository.getProviderCalls, 2);
  });

  test(
    'failed stale-provider listing is observed once and can be retried',
    () async {
      final repository = _FailingProviderRepository();
      final service = ProviderRefreshService(
        providerRepository: repository,
        httpClient: MockClient(
          (request) async => throw StateError('No request expected'),
        ),
      );
      addTearDown(service.dispose);

      for (var attempt = 0; attempt < 2; attempt += 1) {
        await expectLater(service.refreshStaleProviders(), throwsStateError);
      }
      expect(repository.listProviderCalls, 2);
    },
  );
}

class _FailingProviderRepository implements ProviderRepository {
  var getProviderCalls = 0;
  var listProviderCalls = 0;

  @override
  Future<IptvProvider?> getProvider(String id) async {
    getProviderCalls += 1;
    throw StateError('Database unavailable');
  }

  @override
  Future<List<IptvProvider>> listProviders() async {
    listProviderCalls += 1;
    throw StateError('Database unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
