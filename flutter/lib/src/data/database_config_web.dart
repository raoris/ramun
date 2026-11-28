import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

bool _configured = false;

Future<void> configureDatabaseFactory() async {
  if (_configured) return;
  databaseFactory = databaseFactoryFfiWeb;
  _configured = true;
}
