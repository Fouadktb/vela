import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../providers/provider_input_validator.dart';
import '../providers/provider_models.dart';
import '../providers/refresh_interval.dart';

enum PairingSessionStatus {
  idle,
  starting,
  ready,
  received,
  importing,
  succeeded,
  failed,
  expired,
}

class PairingSessionSnapshot {
  const PairingSessionSnapshot({
    required this.status,
    this.url,
    this.code,
    this.expiresAt,
    this.message,
    this.submission,
    this.submissionId,
  });

  final PairingSessionStatus status;
  final Uri? url;
  final String? code;
  final DateTime? expiresAt;
  final String? message;
  final PairingProviderSubmission? submission;
  final int? submissionId;

  PairingSessionSnapshot copyWith({
    PairingSessionStatus? status,
    Uri? url,
    String? code,
    DateTime? expiresAt,
    String? message,
    PairingProviderSubmission? submission,
    int? submissionId,
  }) {
    return PairingSessionSnapshot(
      status: status ?? this.status,
      url: url ?? this.url,
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      message: message ?? this.message,
      submission: submission ?? this.submission,
      submissionId: submissionId ?? this.submissionId,
    );
  }
}

class PairingProviderSubmission {
  const PairingProviderSubmission({required this.input});

  final ProviderInput input;
}

class PairingSessionService {
  PairingSessionService({
    this.ttl = const Duration(minutes: 10),
    Random? random,
  }) : _random = random ?? Random.secure();

  final Duration ttl;
  final Random _random;
  final _controller = StreamController<PairingSessionSnapshot>.broadcast(
    sync: true,
  );

  HttpServer? _server;
  Timer? _expiryTimer;
  PairingSessionSnapshot _snapshot = const PairingSessionSnapshot(
    status: PairingSessionStatus.idle,
  );
  var _submissionCounter = 0;
  var _stopped = false;

  Stream<PairingSessionSnapshot> get stream => _controller.stream;
  PairingSessionSnapshot get snapshot => _snapshot;

  Future<PairingSessionSnapshot> start() async {
    if (_server != null) {
      if (_snapshot.status != PairingSessionStatus.failed &&
          _snapshot.status != PairingSessionStatus.expired &&
          _snapshot.status != PairingSessionStatus.succeeded) {
        return _snapshot;
      }
      await stop();
    }

    _stopped = false;
    _emit(const PairingSessionSnapshot(status: PairingSessionStatus.starting));
    final code = _newCode();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    final host = await _lanHost();
    final url = Uri(
      scheme: 'http',
      host: host,
      port: server.port,
      path: '/',
      queryParameters: {'code': code},
    );
    final expiresAt = DateTime.now().add(ttl);
    _expiryTimer?.cancel();
    _expiryTimer = Timer(ttl, expire);
    _emit(
      PairingSessionSnapshot(
        status: PairingSessionStatus.ready,
        url: url,
        code: code,
        expiresAt: expiresAt,
        message: 'Waiting for a phone or desktop',
      ),
    );
    unawaited(_serve(server, code));
    return _snapshot;
  }

  Future<void> stop() async {
    _stopped = true;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    if (!_controller.isClosed &&
        _snapshot.status != PairingSessionStatus.succeeded &&
        _snapshot.status != PairingSessionStatus.expired) {
      _emit(_snapshot.copyWith(status: PairingSessionStatus.idle));
    }
  }

  void markImporting(String message) {
    if (_stopped) return;
    _emit(
      _snapshot.copyWith(
        status: PairingSessionStatus.importing,
        message: message,
      ),
    );
  }

  void markSucceeded(String message) {
    if (_stopped) return;
    _emit(
      _snapshot.copyWith(
        status: PairingSessionStatus.succeeded,
        message: message,
      ),
    );
    unawaited(stop());
  }

  void markFailed(String message) {
    if (_stopped) return;
    _emit(
      _snapshot.copyWith(status: PairingSessionStatus.failed, message: message),
    );
  }

  void expire() {
    if (_stopped || _server == null) return;
    _emit(
      _snapshot.copyWith(
        status: PairingSessionStatus.expired,
        message: 'Pairing expired. Reopen Add Provider to start again.',
      ),
    );
    unawaited(stop());
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  Future<void> _serve(HttpServer server, String code) async {
    try {
      await for (final request in server) {
        if (_stopped) {
          await _sendText(request, HttpStatus.gone, 'Pairing stopped');
          continue;
        }
        try {
          await _handleRequest(request, code);
        } catch (_) {
          await _sendText(
            request,
            HttpStatus.internalServerError,
            'Vela could not process this request.',
          );
        }
      }
    } catch (_) {
      if (!_stopped) {
        markFailed('Pairing server stopped unexpectedly');
      }
    }
  }

  Future<void> _handleRequest(HttpRequest request, String code) async {
    final path = request.uri.path;
    if (request.method == 'GET' && (path == '/' || path.isEmpty)) {
      await _sendHtml(request, _pairingPage(code));
      return;
    }
    if (request.method == 'GET' && path == '/health') {
      await _sendJson(request, {'ok': true});
      return;
    }
    if (request.method == 'POST' && path == '/api/provider') {
      await _handleProviderPost(request, code);
      return;
    }
    await _sendText(request, HttpStatus.notFound, 'Not found');
  }

  Future<void> _handleProviderPost(HttpRequest request, String code) async {
    final body = await utf8.decoder
        .bind(request)
        .join()
        .timeout(const Duration(seconds: 10));
    if (body.length > 64 * 1024) {
      await _sendJson(request, {
        'ok': false,
        'message': 'Request is too large',
      }, statusCode: HttpStatus.badRequest);
      return;
    }

    final payload = _parsePayload(request, body);
    if (payload['code'] != code) {
      await _sendJson(request, {
        'ok': false,
        'message': 'Pairing code is invalid',
      }, statusCode: HttpStatus.forbidden);
      return;
    }

    final input = _providerInputFromPayload(payload);
    final validation = validateProviderInput(input);
    if (!validation.isValid) {
      await _sendJson(request, {
        'ok': false,
        'message': validation.message,
      }, statusCode: HttpStatus.badRequest);
      return;
    }

    final submission = PairingProviderSubmission(input: validation.input);
    final submissionId = _submissionCounter += 1;
    _emit(
      _snapshot.copyWith(
        status: PairingSessionStatus.received,
        message: 'Provider received from paired device',
        submission: submission,
        submissionId: submissionId,
      ),
    );
    await _sendJson(request, {
      'ok': true,
      'message': 'Provider sent to Vela. Watch the TV for import progress.',
    });
  }

  Map<String, String> _parsePayload(HttpRequest request, String body) {
    final contentType = request.headers.contentType?.mimeType;
    if (contentType == 'application/json') {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        return decoded.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
      }
      return const {};
    }
    return Uri.splitQueryString(body);
  }

  ProviderInput _providerInputFromPayload(Map<String, String> payload) {
    final typeValue = (payload['type'] ?? payload['providerType'] ?? 'xtream')
        .trim()
        .toLowerCase();
    final type = typeValue == 'm3u' || typeValue == 'm3uurl'
        ? ProviderType.m3uUrl
        : ProviderType.xtream;
    final refreshInterval =
        int.tryParse(payload['refreshInterval'] ?? '') ??
        defaultRefreshIntervalMinutes;
    return ProviderInput(
      name: payload['name']?.trim().isNotEmpty == true
          ? payload['name']!.trim()
          : 'Primary IPTV',
      type: type,
      serverUrl: type == ProviderType.xtream ? payload['serverUrl'] : null,
      username: type == ProviderType.xtream ? payload['username'] : null,
      password: type == ProviderType.xtream ? payload['password'] : null,
      m3uUrl: type == ProviderType.m3uUrl ? payload['m3uUrl'] : null,
      refreshIntervalMinutes: refreshInterval,
    );
  }

  Future<void> _sendHtml(HttpRequest request, String html) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html);
    await request.response.close();
  }

  Future<void> _sendJson(
    HttpRequest request,
    Map<String, Object?> payload, {
    int statusCode = HttpStatus.ok,
  }) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(payload));
    await request.response.close();
  }

  Future<void> _sendText(
    HttpRequest request,
    int statusCode,
    String message,
  ) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.text
      ..write(message);
    await request.response.close();
  }

  void _emit(PairingSessionSnapshot snapshot) {
    _snapshot = snapshot;
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
  }

  String _newCode() {
    return List.generate(6, (_) => _random.nextInt(10).toString()).join();
  }

  Future<String> _lanHost() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) {
          return address.address;
        }
      }
    }
    return InternetAddress.loopbackIPv4.address;
  }
}

String _pairingPage(String code) {
  return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Add Provider to Vela</title>
  <style>
    :root { color-scheme: dark; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #0c0d0e; color: #f4f0e8; }
    * { box-sizing: border-box; }
    body { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 24px; background: #0c0d0e; }
    main { width: min(680px, 100%); background: #151719; border: 1px solid #30343a; border-radius: 12px; padding: 24px; }
    h1 { margin: 0 0 8px; font-size: clamp(28px, 6vw, 42px); letter-spacing: 0; }
    p { margin: 0 0 20px; color: #bfb7aa; line-height: 1.45; }
    .tabs { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 18px; }
    button, select, input { font: inherit; }
    .tab, .submit { min-height: 48px; border: 1px solid #3a3f45; border-radius: 8px; color: #f4f0e8; background: #101214; font-weight: 800; }
    .tab[aria-selected="true"], .submit { background: #ecc15d; color: #0c0d0e; border-color: #ecc15d; }
    label { display: block; margin: 14px 0 6px; color: #d7cec0; font-weight: 800; }
    input, select { width: 100%; min-height: 48px; border: 1px solid #3a3f45; border-radius: 8px; padding: 0 14px; color: #f4f0e8; background: #0f1012; }
    .row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .submit { width: 100%; margin-top: 22px; }
    .status { margin-top: 16px; min-height: 24px; color: #ecc15d; font-weight: 800; }
    .hidden { display: none; }
    @media (max-width: 560px) { .row { grid-template-columns: 1fr; gap: 0; } main { padding: 18px; } }
  </style>
</head>
<body>
<main>
  <h1>Add Provider</h1>
  <p>This page sends provider details directly to Vela on your local network. Nothing is uploaded to a cloud service.</p>
  <form id="provider-form">
    <input type="hidden" name="code" value="$code">
    <div class="tabs" role="tablist">
      <button class="tab" type="button" data-type="xtream" aria-selected="true">Xtream Codes</button>
      <button class="tab" type="button" data-type="m3u" aria-selected="false">M3U URL</button>
    </div>
    <input type="hidden" name="type" id="type" value="xtream">
    <label for="name">Provider name</label>
    <input id="name" name="name" autocomplete="off" value="Primary IPTV">
    <section id="xtream-fields">
      <label for="serverUrl">Server URL</label>
      <input id="serverUrl" name="serverUrl" inputmode="url" autocomplete="url" placeholder="http://example.com">
      <div class="row">
        <div>
          <label for="username">Username</label>
          <input id="username" name="username" autocomplete="username">
        </div>
        <div>
          <label for="password">Password</label>
          <input id="password" name="password" type="password" autocomplete="current-password">
        </div>
      </div>
    </section>
    <section id="m3u-fields" class="hidden">
      <label for="m3uUrl">M3U URL</label>
      <input id="m3uUrl" name="m3uUrl" inputmode="url" autocomplete="url" placeholder="http://example.com/playlist.m3u">
    </section>
    <label for="refreshInterval">Auto-refresh</label>
    <select id="refreshInterval" name="refreshInterval">
      <option value="180">Every 3 hours</option>
      <option value="360">Every 6 hours</option>
      <option value="720">Every 12 hours</option>
      <option value="1440" selected>Every day</option>
      <option value="10080">Every week</option>
    </select>
    <button class="submit" type="submit">Send to Vela</button>
    <div class="status" id="status" aria-live="polite"></div>
  </form>
</main>
<script>
const form = document.getElementById('provider-form');
const statusEl = document.getElementById('status');
const typeEl = document.getElementById('type');
const xtream = document.getElementById('xtream-fields');
const m3u = document.getElementById('m3u-fields');
for (const tab of document.querySelectorAll('.tab')) {
  tab.addEventListener('click', () => {
    const type = tab.dataset.type;
    typeEl.value = type;
    for (const other of document.querySelectorAll('.tab')) {
      other.setAttribute('aria-selected', String(other === tab));
    }
    xtream.classList.toggle('hidden', type !== 'xtream');
    m3u.classList.toggle('hidden', type !== 'm3u');
  });
}
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  statusEl.textContent = 'Sending...';
  try {
    const body = new URLSearchParams(new FormData(form));
    const response = await fetch('/api/provider', { method: 'POST', body });
    const payload = await response.json();
    statusEl.textContent = payload.message || (response.ok ? 'Sent to Vela.' : 'Could not send provider.');
  } catch (error) {
    statusEl.textContent = 'Could not reach Vela. Make sure this device is on the same network.';
  }
});
</script>
</body>
</html>
''';
}
