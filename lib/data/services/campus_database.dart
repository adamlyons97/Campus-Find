import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/campus_item.dart';
import '../models/item_claim.dart';
import '../models/profile.dart';
import '../repositories/campus_store.dart';

class CampusDatabase implements CampusStore {
  CampusDatabase._();

  static final CampusDatabase instance = CampusDatabase._();

  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, 'campusfind.db');
    final opened = await openDatabase(
      databasePath,
      version: 6,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    _database = opened;
    return opened;
  }

  @override
  Future<void> init() async {
    await _db;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        campus TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        status TEXT NOT NULL,
        report_type TEXT NOT NULL DEFAULT 'lost',
        owner_uid TEXT NOT NULL DEFAULT '',
        reporter_name TEXT NOT NULL,
        contact TEXT NOT NULL,
        image_data TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE claims (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        claimant_uid TEXT NOT NULL DEFAULT '',
        claimant_name TEXT NOT NULL,
        contact TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.insert('profile', Profile.fallback.toMap());
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE items ADD COLUMN image_data TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE items ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE items ADD COLUMN longitude REAL');
    }
    if (oldVersion < 4) {
      await _removeSampleItems(db);
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE items ADD COLUMN owner_uid TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE claims ADD COLUMN claimant_uid TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE items ADD COLUMN report_type TEXT NOT NULL DEFAULT 'lost'",
      );
      await db.execute(
        "UPDATE items SET report_type = status WHERE status IN ('lost', 'found')",
      );
    }
  }

  Future<void> _removeSampleItems(Database db) async {
    await db.delete(
      'items',
      where: '''
        (title = ? AND contact = ?) OR
        (title = ? AND contact = ?) OR
        (title = ? AND contact = ?)
      ''',
      whereArgs: [
        'Black Hydro Flask',
        'helpdesk@campus.edu',
        'Student ID Card',
        'security@campus.edu',
        'Wireless Earbuds Case',
        'student@campus.edu',
      ],
    );
  }

  @override
  Future<Profile> getProfile() async {
    final db = await _db;
    final rows = await db.query('profile', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      await saveProfile(Profile.fallback);
      return Profile.fallback;
    }
    return Profile.fromMap(rows.first);
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    final db = await _db;
    await db.insert(
      'profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<CampusItem>> getItems({
    String query = '',
    ItemStatus? status,
  }) async {
    final db = await _db;
    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (status != null) {
      whereParts.add('status = ?');
      whereArgs.add(status.databaseValue);
    }

    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) {
      whereParts.add('''
        (
          title LIKE ? OR
          description LIKE ? OR
          category LIKE ? OR
          location LIKE ?
        )
      ''');
      final likeQuery = '%$normalizedQuery%';
      whereArgs.addAll([likeQuery, likeQuery, likeQuery, likeQuery]);
    }

    final rows = await db.query(
      'items',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
    );

    return rows.map(CampusItem.fromMap).toList();
  }

  @override
  Future<CampusItem> createItem(CampusItem item) async {
    final db = await _db;
    final id = await db.insert('items', item.toMap()..remove('id'));
    return item.copyWith(id: id);
  }

  @override
  Future<void> updateItem(CampusItem item) async {
    final id = item.id;
    if (id == null) {
      throw ArgumentError('Cannot update an item without an id.');
    }

    final db = await _db;
    await db.update(
      'items',
      item.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteItem(int id) async {
    final db = await _db;
    await db.delete('claims', where: 'item_id = ?', whereArgs: [id]);
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ItemClaim>> getClaims() async {
    final db = await _db;
    final rows = await db.query('claims', orderBy: 'created_at DESC');
    return rows.map(ItemClaim.fromMap).toList();
  }

  @override
  Future<ItemClaim> createClaim(ItemClaim claim) async {
    final db = await _db;
    final id = await db.insert('claims', claim.toMap()..remove('id'));
    return claim.copyWith(id: id);
  }

  @override
  Future<void> updateClaim(ItemClaim claim) async {
    final id = claim.id;
    if (id == null) {
      throw ArgumentError('Cannot update a claim without an id.');
    }

    final db = await _db;
    await db.update(
      'claims',
      claim.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
