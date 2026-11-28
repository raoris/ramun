import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

const _configUrl =
    'https://raw.githubusercontent.com/raoris/ramun/main/config/app_config.json';
const _signatureUrl =
    'https://raw.githubusercontent.com/raoris/ramun/main/config/app_config.sig';
const _bundledConfig = 'assets/default_config.json';
const _payloadKey = 'alsefa.config.payload';
const _etagKey = 'alsefa.config.etag';

const _publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7YSgJtCM10wGraoZOgId
YorPxjoSItEzWL5I1P4+qIKmh+0ceJqilxEPMzBxIiC+Zg+piX7VJRvgytMkYs2O
0mUJdTFXG/AtDJk2HeY4q/YXlmdEuSMH4HYgsJG2zaCeFLXxJ6dWqlx79V9H6qF5
K8dgUUVsQs4Rqyb2ujjGz5oaMfoXzBTGbJ56K97G1K6NrFzuaK58PzxNA2Za/OO6
rSQXr7TmQGSibE+XMIoaSq/PX16jjTe9Pg7gnvTaZILLQEJNm8I4U/pVdkyNKg2z
YA2dMZUp4ba4nSPMDFZ6YU7gdpXoKQPdoZH8m5OfwllDXSjEVWHX17cIvufeBdiF
SQIDAQAB
-----END PUBLIC KEY-----
''';

bool verifyConfigSignature(String payload, String signatureBase64) {
  try {
    final key = RSAKeyParser().parse(_publicKeyPem) as RSAPublicKey;
    final signature = RSASignature(
      Uint8List.fromList(base64.decode(signatureBase64.trim())),
    );
    final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(key));
    return verifier.verifySignature(
      Uint8List.fromList(utf8.encode(payload)),
      signature,
    );
  } catch (_) {
    return false;
  }
}

class RemoteConfigService {
  RemoteConfigService(this._preferences, {http.Client? client})
      : _client = client ?? http.Client();

  final SharedPreferences _preferences;
  final http.Client _client;

  Future<RemoteConfig> load({bool forceRefresh = false}) async {
    RemoteConfig? cached;
    final cachedPayload = _preferences.getString(_payloadKey);
    if (cachedPayload != null) {
      try {
        cached = RemoteConfig.fromPayload(cachedPayload);
      } catch (_) {
        cached = null;
      }
    }

    try {
      final headers = <String, String>{};
      if (!forceRefresh) {
        final etag = _preferences.getString(_etagKey);
        if (etag != null) headers['If-None-Match'] = etag;
      }
      final response = await _client
          .get(Uri.parse(_configUrl), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 304 && cached != null) return cached;
      if (response.statusCode != 200) {
        throw Exception('Config request failed: ${response.statusCode}');
      }

      final signatureResponse = await _client
          .get(Uri.parse(_signatureUrl))
          .timeout(const Duration(seconds: 15));
      if (signatureResponse.statusCode != 200) {
        throw Exception('Signature request failed: ${signatureResponse.statusCode}');
      }
      if (!verifyConfigSignature(response.body, signatureResponse.body)) {
        throw Exception('Config signature verification failed');
      }

      final parsed = RemoteConfig.fromPayload(response.body);
      if (parsed.schemaVersion < 1 || parsed.schemaVersion > 2) {
        throw Exception('Unsupported config schema: ${parsed.schemaVersion}');
      }

      await _preferences.setString(_payloadKey, response.body);
      final etag = response.headers['etag'];
      if (etag != null) await _preferences.setString(_etagKey, etag);
      return parsed;
    } catch (_) {
      if (cached != null) return cached;
      return bundled();
    }
  }

  Future<RemoteConfig> bundled() async {
    final payload = await rootBundle.loadString(_bundledConfig);
    return RemoteConfig.fromPayload(payload);
  }

  void dispose() => _client.close();
}
