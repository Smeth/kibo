import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diagnostic local uniquement : ni identités, chemins, corps, ni erreurs brutes.
class PhotoUploadDiagnostics {
  PhotoUploadDiagnostics({
    void Function(String)? sink,
    this.enabled = kDebugMode,
  }) : _sink = sink ?? debugPrint;

  static const marker = '[KIBO_PHOTO] ';
  static final _zoneKey = Object();
  final void Function(String) _sink;
  final bool enabled;
  static const _edgeCodes = {
    'authentication',
    'configuration',
    'body',
    'fields',
    'digest',
    'dimensions',
    'size',
    'listing',
    'owner',
    'reservation',
    'storage',
    'invalid_or_unavailable',
    'NOT_FOUND',
    'WORKER_ERROR',
    'BOOT_ERROR',
  };

  Future<T> trace<T>(Future<T> Function(PhotoUploadAttempt) action) async {
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final attempt = PhotoUploadAttempt._(this, id);
    return runZoned(() async {
      attempt.stage('validation');
      try {
        final result = await action(attempt);
        attempt.stage('complete');
        attempt._emit('success');
        return result;
      } catch (error) {
        String? code;
        if (error is PostgrestException) {
          final value = error.code ?? '';
          if (RegExp(
            r'^(?:PGRST[0-9]{3}|[0-9]{2}[0-9A-Z]{3})$',
          ).hasMatch(value)) {
            code = value;
          }
        } else if (error is FunctionException) {
          attempt._status = error.status >= 100 && error.status <= 599
              ? error.status
              : null;
          final details = error.details;
          if (details is Map) {
            final value = details['error'] ?? details['code'];
            if (value is String && _edgeCodes.contains(value)) code = value;
          }
        }
        attempt._emit('failure', code: code);
        rethrow;
      }
    }, zoneValues: {_zoneKey: attempt});
  }
}

class PhotoUploadAttempt {
  PhotoUploadAttempt._(this._diagnostics, this.id);
  final PhotoUploadDiagnostics _diagnostics;
  final String id;
  String _stage = 'validation';
  int? _status;
  String? _serverRequestId;

  void stage(String value, {bool keepResponse = false}) {
    _stage = value;
    if (!keepResponse) {
      _status = null;
      _serverRequestId = null;
    }
    _emit('start');
  }

  void _emit(String event, {String? code}) {
    if (!_diagnostics.enabled) return;
    try {
      _diagnostics._sink(
        '${PhotoUploadDiagnostics.marker}${jsonEncode({'v': 1, 'attempt': id, 'stage': _stage, 'event': event, 'http_status': _status, 'code': code, 'server_request_id': _serverRequestId})}',
      );
    } catch (_) {
      // Une panne de journalisation ne doit jamais modifier la reprise métier.
    }
  }
}

/// Observe les statuts sans lire/copier les corps ou changer les requêtes.
/// Hors d'un attach() instrumenté, aucune observation/journalisation.
class PhotoDiagnosticHttpClient extends http.BaseClient {
  PhotoDiagnosticHttpClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final attempt =
        Zone.current[PhotoUploadDiagnostics._zoneKey] as PhotoUploadAttempt?;
    final response = await _inner.send(request);
    final path = request.url.path;
    // Ne pas attribuer un refresh Auth au POST photos qui suit.
    if (attempt != null &&
        (path == '/rest/v1/kibo_listing_photos' ||
            path == '/functions/v1/kibo-upload-listing-photo')) {
      attempt._status = response.statusCode;
      final requestId = response.headers['sb-request-id'];
      if (requestId != null &&
          RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(requestId)) {
        attempt._serverRequestId = requestId;
      }
      attempt._emit('http');
    }
    return response;
  }

  @override
  void close() => _inner.close();
}
