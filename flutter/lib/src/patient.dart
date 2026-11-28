import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

const _patientsKey = 'alsefa.patients';

class Patient {
  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodPressure,
    required this.address,
    required this.phone,
    required this.weightKg,
    required this.recordedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: asString(json['id']),
        name: asString(json['name']),
        age: asInt(json['age']),
        bloodPressure: asString(json['bloodPressure']),
        address: asString(json['address']),
        phone: asString(json['phone']),
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        recordedAt: asString(json['recordedAt']),
      );

  final String id;
  final String name;
  final int age;
  final String bloodPressure;
  final String address;
  final String phone;
  final double weightKg;
  final String recordedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'bloodPressure': bloodPressure,
        'address': address,
        'phone': phone,
        'weightKg': weightKg,
        'recordedAt': recordedAt,
      };
}

class PatientStore {
  PatientStore(this._preferences);

  final SharedPreferences _preferences;

  List<Patient> all() {
    final stored = _preferences.getString(_patientsKey);
    if (stored == null) return const <Patient>[];
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      return decoded
          .map((item) => Patient.fromJson(asMap(item)))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return const <Patient>[];
    }
  }

  Future<void> add(Patient patient) async {
    final updated = [...all(), patient];
    await _preferences.setString(
      _patientsKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  static String timestamp([DateTime? value]) {
    final now = value ?? DateTime.now();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${now.year.toString().padLeft(4, '0')}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}';
  }
}
