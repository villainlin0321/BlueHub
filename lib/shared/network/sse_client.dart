import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../auth/token_store.dart';
import 'api_exception.dart';
import 'sse_models.dart';

Stream<SseEvent> parseSseLines(Stream<String> lines) async* {
  String? eventId;
  String? eventName;
  int? retry;
  final dataLines = <String>[];

  await for (final line in lines) {
    if (line.isEmpty) {
      if (dataLines.isNotEmpty) {
        yield SseEvent(
          id: eventId,
          event: eventName,
          data: dataLines.join('\n'),
          retry: retry,
        );
      }
      eventId = null;
      eventName = null;
      retry = null;
      dataLines.clear();
      continue;
    }

    if (line.startsWith(':')) {
      continue;
    }

    final separatorIndex = line.indexOf(':');
    final field = separatorIndex == -1
        ? line
        : line.substring(0, separatorIndex);
    final value = separatorIndex == -1
        ? ''
        : line.substring(separatorIndex + 1).trimLeft();

    switch (field) {
      case 'id':
        eventId = value;
        break;
      case 'event':
        eventName = value;
        break;
      case 'retry':
        retry = int.tryParse(value);
        break;
      case 'data':
        dataLines.add(value);
        break;
    }
  }
}

class SseClient {
  SseClient({required this.baseUrl, required this.tokenStore});

  final String baseUrl;
  final TokenStore tokenStore;

  Stream<SseEvent> connect(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async* {
    final httpClient = HttpClient();
    final uri = _buildUri(path, queryParameters: queryParameters);
    try {
      final request = await httpClient.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

      final token = tokenStore.accessToken;
      if (token != null && token.trim().isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      headers?.forEach(request.headers.set);

      final response = await request.close();
      if (response.statusCode >= 400) {
        final message = await response.transform(utf8.decoder).join();
        throw ApiException.http(
          statusCode: response.statusCode,
          message: message.isEmpty ? 'SSE 请求失败' : message,
        );
      }

      await for (final event in parseSseLines(
        response.transform(utf8.decoder).transform(const LineSplitter()),
      )) {
        yield event;
      }
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException.network(error);
    } catch (error) {
      throw ApiException.unknown(error);
    } finally {
      httpClient.close(force: true);
    }
  }

  Uri _buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final uri = Uri.parse(baseUrl).resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }
}
