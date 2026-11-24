import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/core/network/api_failure.dart';

final class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required String baseUrl,
    this.timeout = const Duration(seconds: 15),
    this.tokenProvider,
  })  : _http = httpClient,
        _baseUrl = _stripTrailingSlash(baseUrl);

  final http.Client _http;
  final String _baseUrl;
  final Duration timeout;
  final FutureOr<String?> Function()? tokenProvider;

  static String _stripTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalized');
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final headers = <String, String>{
      // Sylius collections need Hydra (`hydra:member`); application/json returns a bare array.
      'Accept': 'application/ld+json',
    };
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    final provider = tokenProvider;
    if (provider != null) {
      final token = await provider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Result<T, ApiFailure>> get<T>(
    String path, {
    required T Function(Object? json) decode,
  }) {
    return _send<T>(
      () async => _http
          .get(_uri(path), headers: await _headers())
          .timeout(timeout),
      decode: decode,
    );
  }

  Future<Result<T, ApiFailure>> post<T>(
    String path, {
    Object? body,
    required T Function(Object? json) decode,
  }) {
    return _send<T>(
      () async => _http
          .post(
            _uri(path),
            headers: await _headers(jsonBody: true),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout),
      decode: decode,
    );
  }

  Future<Result<T, ApiFailure>> _send<T>(
    Future<http.Response> Function() send, {
    required T Function(Object? json) decode,
  }) async {
    try {
      final response = await send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(
          ApiHttpFailure(
            statusCode: response.statusCode,
            body: response.body.isEmpty ? null : response.body,
          ),
        );
      }
      try {
        final Object? json =
            response.body.isEmpty ? null : jsonDecode(response.body);
        return Success(decode(json));
      } catch (e) {
        return Failure(ApiParseFailure(e.toString()));
      }
    } on TimeoutException {
      return const Failure(ApiTimeoutFailure());
    } on http.ClientException catch (e) {
      return Failure(ApiNetworkFailure(e.message));
    } on Exception catch (e) {
      return Failure(ApiNetworkFailure(e.toString()));
    }
  }
}
