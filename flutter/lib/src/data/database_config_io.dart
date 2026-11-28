import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _configured = false;

Future<void> configureDatabaseFactory() async {
  if (_configured) return;
  if (Platform.isAndroid || Platform.isIOS) {
    _configured = true;
    return;
  }
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _configured = true;
}
