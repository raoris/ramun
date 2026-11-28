import 'dart:convert';

import 'package:uuid/uuid.dart';

final Uuid _uuid = Uuid();

String nowIso() => DateTime.now().toUtc().toIso8601String();

String dateKey([DateTime? value]) {
  final selected = value ?? DateTime.now();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${selected.year.toString().padLeft(4, '0')}-${two(selected.month)}-${two(selected.day)}';
}

String newId() => _uuid.v4();

String _text(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String _requiredText(Object? value, String fallback) {
  final text = _text(value);
  return text.trim().isEmpty ? fallback : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) {
    final result = value.toDouble();
    return result.isFinite ? result : fallback;
  }
  if (value is String) {
    final result = double.tryParse(value.trim());
    if (result != null && result.isFinite) return result;
  }
  return fallback;
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
  }
  return fallback;
}

List<String> _listString(Object? value) {
  if (value is List) {
    return value.map((item) => _text(item)).toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => _text(item)).toList();
      }
    } catch (_) {
      return <String>[];
    }
  }
  return <String>[];
}

class Patient {
  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bp,
    required this.address,
    required this.phone,
    required this.weightKg,
    required this.diagnosis,
    required this.regularFee,
    required this.firstFee,
    required this.initialPayment,
    required this.preferredTime,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    final created = _requiredText(
      json['createdAt'] ?? json['recordedAt'],
      nowIso(),
    );
    final updated = _requiredText(json['updatedAt'], created);
    return Patient(
      id: _requiredText(json['id'], newId()),
      name: _text(json['name']),
      age: _int(json['age']),
      gender: _text(json['gender'] ?? json['sex']),
      bp: _text(json['bp'] ?? json['bloodPressure']),
      address: _text(json['address']),
      phone: _text(json['phone']),
      weightKg: _double(json['weightKg'] ?? json['weight']),
      diagnosis: _text(json['diagnosis']),
      regularFee: _double(json['regularFee']),
      firstFee: _double(json['firstFee'], fallback: 300),
      initialPayment: _double(json['initialPayment']),
      preferredTime: _text(json['preferredTime']),
      createdAt: created,
      updatedAt: updated,
      syncStatus: _requiredText(json['syncStatus'], 'pending'),
    );
  }

  final String id;
  final String name;
  final int age;
  final String gender;
  final String bp;
  final String address;
  final String phone;
  final double weightKg;
  final String diagnosis;
  final double regularFee;
  final double firstFee;
  final double initialPayment;
  final String preferredTime;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'bp': bp,
        'address': address,
        'phone': phone,
        'weightKg': weightKg,
        'diagnosis': diagnosis,
        'regularFee': regularFee,
        'firstFee': firstFee,
        'initialPayment': initialPayment,
        'preferredTime': preferredTime,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'syncStatus': syncStatus,
      };

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? bp,
    String? address,
    String? phone,
    double? weightKg,
    String? diagnosis,
    double? regularFee,
    double? firstFee,
    double? initialPayment,
    String? preferredTime,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      Patient(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        bp: bp ?? this.bp,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        weightKg: weightKg ?? this.weightKg,
        diagnosis: diagnosis ?? this.diagnosis,
        regularFee: regularFee ?? this.regularFee,
        firstFee: firstFee ?? this.firstFee,
        initialPayment: initialPayment ?? this.initialPayment,
        preferredTime: preferredTime ?? this.preferredTime,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}

class DocumentRecord {
  DocumentRecord({
    String? id,
    String? patientId,
    String? name,
    String? path,
    String? mimeType,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  })  : id = _requiredText(id, newId()),
        patientId = patientId ?? '',
        name = name ?? '',
        path = path ?? '',
        mimeType = mimeType ?? '',
        createdAt = _requiredText(createdAt, nowIso()),
        updatedAt = _requiredText(updatedAt, _requiredText(createdAt, nowIso())),
        syncStatus = _requiredText(syncStatus, 'pending');

  factory DocumentRecord.fromJson(Map<String, dynamic> json) {
    final created = _requiredText(json['createdAt'], nowIso());
    return DocumentRecord(
      id: _requiredText(json['id'], newId()),
      patientId: _text(json['patientId']),
      name: _text(json['name']),
      path: _text(json['path']),
      mimeType: _text(json['mimeType']),
      createdAt: created,
      updatedAt: _requiredText(json['updatedAt'], created),
      syncStatus: _requiredText(json['syncStatus'], 'pending'),
    );
  }

  final String id;
  final String patientId;
  final String name;
  final String path;
  final String mimeType;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'patientId': patientId,
        'name': name,
        'path': path,
        'mimeType': mimeType,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'syncStatus': syncStatus,
      };

  DocumentRecord copyWith({
    String? id,
    String? patientId,
    String? name,
    String? path,
    String? mimeType,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      DocumentRecord(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        name: name ?? this.name,
        path: path ?? this.path,
        mimeType: mimeType ?? this.mimeType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}

class Visit {
  Visit({
    String? id,
    String? patientId,
    String? arrivedAt,
    String? sessionAt,
    String? status,
    bool? isRushHour,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  })  : id = _requiredText(id, newId()),
        patientId = patientId ?? '',
        arrivedAt = arrivedAt ?? '',
        sessionAt = sessionAt ?? '',
        status = status ?? 'scheduled',
        isRushHour = isRushHour ?? false,
        notes = notes ?? '',
        createdAt = _requiredText(createdAt, nowIso()),
        updatedAt = _requiredText(updatedAt, _requiredText(createdAt, nowIso())),
        syncStatus = _requiredText(syncStatus, 'pending');

  factory Visit.fromJson(Map<String, dynamic> json) {
    final created = _requiredText(json['createdAt'], nowIso());
    return Visit(
      id: _requiredText(json['id'], newId()),
      patientId: _text(json['patientId']),
      arrivedAt: _text(json['arrivedAt']),
      sessionAt: _text(json['sessionAt']),
      status: _requiredText(json['status'], 'scheduled'),
      isRushHour: _bool(json['isRushHour']),
      notes: _text(json['notes']),
      createdAt: created,
      updatedAt: _requiredText(json['updatedAt'], created),
      syncStatus: _requiredText(json['syncStatus'], 'pending'),
    );
  }

  final String id;
  final String patientId;
  final String arrivedAt;
  final String sessionAt;
  final String status;
  final bool isRushHour;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'patientId': patientId,
        'arrivedAt': arrivedAt,
        'sessionAt': sessionAt,
        'status': status,
        'isRushHour': isRushHour,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'syncStatus': syncStatus,
      };

  Visit copyWith({
    String? id,
    String? patientId,
    String? arrivedAt,
    String? sessionAt,
    String? status,
    bool? isRushHour,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      Visit(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        arrivedAt: arrivedAt ?? this.arrivedAt,
        sessionAt: sessionAt ?? this.sessionAt,
        status: status ?? this.status,
        isRushHour: isRushHour ?? this.isRushHour,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}

class Treatment {
  Treatment({
    String? id,
    String? patientId,
    String? assessment,
    String? plan,
    List<String>? checklist,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  })  : id = _requiredText(id, newId()),
        patientId = patientId ?? '',
        assessment = assessment ?? '',
        plan = plan ?? '',
        checklist = List<String>.from(_listString(checklist)),
        createdAt = _requiredText(createdAt, nowIso()),
        updatedAt = _requiredText(updatedAt, _requiredText(createdAt, nowIso())),
        syncStatus = _requiredText(syncStatus, 'pending');

  factory Treatment.fromJson(Map<String, dynamic> json) {
    final created = _requiredText(json['createdAt'], nowIso());
    return Treatment(
      id: _requiredText(json['id'], newId()),
      patientId: _text(json['patientId']),
      assessment: _text(json['assessment']),
      plan: _text(json['plan']),
      checklist: _listString(json['checklist']),
      createdAt: created,
      updatedAt: _requiredText(json['updatedAt'], created),
      syncStatus: _requiredText(json['syncStatus'], 'pending'),
    );
  }

  final String id;
  final String patientId;
  final String assessment;
  final String plan;
  final List<String> checklist;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'patientId': patientId,
        'assessment': assessment,
        'plan': plan,
        'checklist': List<String>.from(checklist),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'syncStatus': syncStatus,
      };

  Treatment copyWith({
    String? id,
    String? patientId,
    String? assessment,
    String? plan,
    List<String>? checklist,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      Treatment(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        assessment: assessment ?? this.assessment,
        plan: plan ?? this.plan,
        checklist: checklist ?? this.checklist,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}

class SessionRecord {
  SessionRecord({
    String? id,
    String? patientId,
    String? treatmentId,
    String? dateKey,
    bool? completed,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  })  : id = _requiredText(id, newId()),
        patientId = patientId ?? '',
        treatmentId = treatmentId ?? '',
        dateKey = dateKey ?? '',
        completed = completed ?? false,
        notes = notes ?? '',
        createdAt = _requiredText(createdAt, nowIso()),
        updatedAt = _requiredText(updatedAt, _requiredText(createdAt, nowIso())),
        syncStatus = _requiredText(syncStatus, 'pending');

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    final created = _requiredText(json['createdAt'], nowIso());
    return SessionRecord(
      id: _requiredText(json['id'], newId()),
      patientId: _text(json['patientId']),
      treatmentId: _text(json['treatmentId']),
      dateKey: _requiredText(json['dateKey'] ?? json['date'], dateKey()),
      completed: _bool(json['completed']),
      notes: _text(json['notes']),
      createdAt: created,
      updatedAt: _requiredText(json['updatedAt'], created),
      syncStatus: _requiredText(json['syncStatus'], 'pending'),
    );
  }

  final String id;
  final String patientId;
  final String treatmentId;
  final String dateKey;
  final bool completed;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'patientId': patientId,
        'treatmentId': treatmentId,
        'dateKey': dateKey,
        'completed': completed,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'syncStatus': syncStatus,
      };

  SessionRecord copyWith({
    String? id,
    String? patientId,
    String? treatmentId,
    String? dateKey,
    bool? completed,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      SessionRecord(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        treatmentId: treatmentId ?? this.treatmentId,
        dateKey: dateKey ?? this.dateKey,
        completed: completed ?? this.completed,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}

class LedgerEntry {
  LedgerEntry({
    String? id,
    this.patientId,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.occurredAt,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  })  : id = _requiredText(id, newId()),
        createdAt = _requiredText(createdAt, nowIso()),
        updatedAt = _requiredText(updatedAt, _requiredText(createdAt, nowIso())),
        syncStatus = _requiredText(syncStatus, 'pending');

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final created = _requiredText(json['createdAt'], nowIso());
    return LedgerEntry(
      id: _requiredText(json['id'], newId()),
      patientId: json['patientId'] == null ? null : _text(json['patientId']),
      type: _text(json['type']),
      category: _text(json['category']),
      description: _text(json['description']),
      amount: _double(json['amount']),
      occurredAt: _requiredText(json['occurredAt'], nowIso()),
      createdAt: created,
      updatedAt: _requiredText(json['updatedAt'], created),
      syncStatus: _requiredText(json['syncStatus'], 'pending'),
    );
  }

  final String id;
  final String? patientId;
  final String type;
  final String category;
  final String description;
  final double amount;
  final String occurredAt;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'patientId': patientId,
        'type': type,
        'category': category,
        'description': description,
        'amount': amount,
        'occurredAt': occurredAt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'syncStatus': syncStatus,
      };

  LedgerEntry copyWith({
    String? id,
    String? patientId,
    String? type,
    String? category,
    String? description,
    double? amount,
    String? occurredAt,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      LedgerEntry(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        type: type ?? this.type,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        occurredAt: occurredAt ?? this.occurredAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}

class SyncQueueItem {
  SyncQueueItem({
    String? id,
    String? entity,
    String? entityId,
    String? operation,
    String? payload,
    String? createdAt,
    Object? synced,
  })  : id = _requiredText(id, newId()),
        entity = entity ?? '',
        entityId = entityId ?? '',
        operation = operation ?? 'upsert',
        payload = payload ?? '{}',
        createdAt = _requiredText(createdAt, nowIso()),
        synced = _bool(synced);

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: _requiredText(json['id'], newId()),
        entity: _text(json['entity']),
        entityId: _text(json['entityId']),
        operation: _requiredText(json['operation'], 'upsert'),
        payload: _requiredText(json['payload'], '{}'),
        createdAt: _requiredText(json['createdAt'], nowIso()),
        synced: json['synced'],
      );

  final String id;
  final String entity;
  final String entityId;
  final String operation;
  final String payload;
  final String createdAt;
  final bool synced;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'entity': entity,
        'entityId': entityId,
        'operation': operation,
        'payload': payload,
        'createdAt': createdAt,
        'synced': synced,
      };

  SyncQueueItem copyWith({
    String? id,
    String? entity,
    String? entityId,
    String? operation,
    String? payload,
    String? createdAt,
    Object? synced,
  }) =>
      SyncQueueItem(
        id: id ?? this.id,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
}

class AppUser {
  AppUser({
    String? id,
    String? name,
    String? email,
    String? role,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  })  : id = _requiredText(id, newId()),
        name = name ?? '',
        email = email ?? '',
        role = role ?? '',
        createdAt = _requiredText(createdAt, nowIso()),
        updatedAt = _requiredText(updatedAt, _requiredText(createdAt, nowIso())),
        syncStatus = _requiredText(syncStatus, 'pending');

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final created = _requiredText(json['createdAt'], nowIso());
    return AppUser(
      id: _requiredText(json['id'], newId()),
      name: _text(json['name']),
      email: _text(json['email']),
      role: _requiredText(json['role'], 'staff'),
      createdAt: created,
      updatedAt: _requiredText(json['updatedAt'], created),
      syncStatus: _requiredText(json['syncStatus'], 'pending'),
    );
  }

  final String id;
  final String name;
  final String email;
  final String role;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'syncStatus': syncStatus,
      };

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) =>
      AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}
