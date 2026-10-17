import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cliente HTTP do backend .NET. Recebe tudo por injeção:
/// o http.Client, a função que dá o token do Firebase e a URL base.
class NesaroApi {
  NesaroApi({
    required http.Client client,
    required Future<String?> Function() idTokenProvider,
    required String baseUrl,
  })  : _client = client,
        _idTokenProvider = idTokenProvider,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  final http.Client _client;
  final Future<String?> Function() _idTokenProvider;
  final String _baseUrl;

  /// Pede ao backend a URL oficial da Meta para conectar o Instagram.
  Future<Uri> startInstagramConnection() async {
    final response = await _post('/auth/instagram/start');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Uri.parse(body['url'] as String);
  }

  Future<void> disconnectInstagram() => _post('/auth/instagram/disconnect');

  void close() => _client.close();

  Future<http.Response> _post(String path) async {
    final token = await _idTokenProvider();
    if (token == null) {
      throw ApiException('Sua sessão expirou. Entre de novo.');
    }

    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } on Exception {
      throw ApiException('Não foi possível falar com o servidor da Nesaro.');
    }

    if (response.statusCode == 401) {
      throw ApiException('Sua sessão expirou. Entre de novo.');
    }
    if (response.statusCode >= 400) {
      throw ApiException('Erro no servidor (${response.statusCode}). Tente de novo.');
    }
    return response;
  }
}
