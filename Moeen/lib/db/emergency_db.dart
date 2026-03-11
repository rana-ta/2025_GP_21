import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'emergency_card_model.dart';

/// Database helper responsible for creating and managing the local database
class EmergencyDB {
  // Singleton pattern: ensures one database instance across the app
  EmergencyDB._internal();
  static final EmergencyDB instance = EmergencyDB._internal();

// Database object (initialized after opening)
  static Database? _db;

  /// Name of the database file stored on the device
  static const String _dbName = 'emergency_db.db';

  /// Table name
  static const String _table = 'emergency_card';

  /// Getter that ensures the database is initialized before use
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  /// Initialize / open the database
  Future<Database> _initDB() async {
// Correct storage path depending on the operating system
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Open database (created automatically the first time)
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

  }

  /// Create tables (runs only the first time the database is created)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
  CREATE TABLE $_table (
    uid TEXT PRIMARY KEY,   
    fullName TEXT NOT NULL,
    idNumber TEXT,
    bloodType TEXT,
    age TEXT,
    nationality TEXT,
    allergies TEXT,
    chronic TEXT,
    meds TEXT,
    emergencyContact TEXT,
    emergencyPhone TEXT
  )
''');


// Note: No default data inserted here.
// Data will be saved when the user presses "Save" for the first time.
  }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $_table');
      await _onCreate(db, newVersion);
    }
  }

  /// Read the emergency card data
  /// Returns null if no record exists
  Future<EmergencyCardModel?> getCard(String uid) async {
    final db = await database;

    final res = await db.query(
      _table,
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (res.isEmpty) return null;
    return EmergencyCardModel.fromMap(res.first);
  }

  /// Save or update the emergency card
  /// conflictAlgorithm.replace replaces the existing record if it exists
  Future<void> saveCard(EmergencyCardModel card) async {
    final db = await database;

    await db.insert(
      _table,
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete the emergency card (optional reset)
  Future<void> deleteCard(String uid) async {
    final db = await database;
    await db.delete(_table, where: 'uid = ?', whereArgs: [uid]);
  }

}
