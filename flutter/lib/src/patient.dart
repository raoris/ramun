import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _legacyPatientsKey = 'alsefa.patients';

class LegacyPatientStore {
  LegacyPatientStore(this._preferences);

  final SharedPreferences _preferences;

  List<Map<String, dynamic>> records() {
    final stored = _preferences.getString(_legacyPatientsKey);
    if (stored == null) return const <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> clear() =>
      _preferences.remove(_legacyPatientsKey);
}
