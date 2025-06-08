import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive.dart';

class DatabaseHelper {
  static Database? _database;
  static Database? _cosmeticsDatabase;

  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get cosmeticsDatabase async {
    if (_cosmeticsDatabase != null) return _cosmeticsDatabase!;
    _cosmeticsDatabase =
        await _initDB('cosmetics.db', 'lib/assets/cosmetics.db.gz');
    return _cosmeticsDatabase!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database =
        await _initDB('vegan_products.db', 'lib/assets/vegan_products.db.gz');
    return _database!;
  }

  Future<Database> _initDB(String dbFileName, String assetPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, dbFileName);
    final file = File(dbPath);

    // Load and decompress the gzipped database
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();
    List<int> decompressedBytes = GZipDecoder().decodeBytes(bytes);
    await file.writeAsBytes(decompressedBytes);

    return await openDatabase(dbPath, version: 1);
  }

  Future<List<Map<String, dynamic>>> queryProduct(String barcode) async {
    final db = await instance.database;
    return await db.query('products', where: 'code = ?', whereArgs: [barcode]);
  }

  Future<List<Map<String, dynamic>>> queryCosmeticByName(String name) async {
    final db = await instance.cosmeticsDatabase;
    return await db.query(
      'cosmetics',
      where: 'brand LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'INSTR(LOWER(brand), LOWER("$name")), brand',
      limit: 100,
    );
  }
}
