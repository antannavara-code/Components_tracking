import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'seed_data.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qr_asset_tracker.db');
    return openDatabase(
      path,
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE assets ADD COLUMN photo_path TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              created_at TEXT
            )
          ''');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE employees (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT,
            department TEXT,
            phone TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE drones (
            id INTEGER PRIMARY KEY,
            drone_id TEXT NOT NULL,
            name TEXT NOT NULL,
            model TEXT,
            status TEXT NOT NULL,
            description TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            building TEXT,
            room TEXT,
            description TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE projects (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE assets (
            id INTEGER PRIMARY KEY,
            asset_id TEXT NOT NULL,
            category TEXT NOT NULL,
            name TEXT NOT NULL,
            serial_number TEXT,
            model TEXT,
            status TEXT NOT NULL,
            condition_type TEXT NOT NULL,
            current_user_id INTEGER,
            current_location_id INTEGER,
            current_drone_id INTEGER,
            project_id INTEGER,
            remarks TEXT,
            photo_path TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (current_user_id) REFERENCES employees(id),
            FOREIGN KEY (current_location_id) REFERENCES locations(id),
            FOREIGN KEY (current_drone_id) REFERENCES drones(id),
            FOREIGN KEY (project_id) REFERENCES projects(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            from_user_id INTEGER,
            to_user_id INTEGER,
            from_location_id INTEGER,
            to_location_id INTEGER,
            from_drone_id INTEGER,
            to_drone_id INTEGER,
            from_status TEXT,
            to_status TEXT,
            purpose TEXT,
            remarks TEXT,
            performed_by INTEGER,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            created_at TEXT
          )
        ''');
      },
    );
  }

  Future<bool> seedIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM assets')) ??
        0;
    if (count > 0) return false;

    await db.transaction((txn) async {
      for (final e in SeedData.employees()) {
        await txn.insert('employees', e, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final d in SeedData.drones()) {
        await txn.insert('drones', d, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final l in SeedData.locations()) {
        await txn.insert('locations', l, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final p in SeedData.projects()) {
        await txn.insert('projects', p, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final a in SeedData.assets()) {
        await txn.insert('assets', a, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final m in SeedData.movements()) {
        await txn.insert('movements', m, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return true;
  }

  /// Deletes all rows from every table so the app starts empty. Rows are
  /// removed in foreign-key-safe order. Demo data will NOT be re-seeded.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('movements');
      await txn.delete('assets');
      await txn.delete('employees');
      await txn.delete('drones');
      await txn.delete('locations');
      await txn.delete('projects');
    });
  }

  String _now() =>
      DateTime.now().toIso8601String().replaceFirst('T', ' ').substring(0, 19);

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row);
  }

  Future<int> update(String table, Map<String, dynamic> row, int id) async {
    final db = await database;
    return db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes an asset together with all of its movement history so no orphan
  /// rows are left behind.
  Future<void> deleteAssetWithHistory(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('movements', where: 'asset_id = ?', whereArgs: [id]);
      await txn.delete('assets', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ============ ASSETS ============

  Future<List<Map<String, dynamic>>> fetchAssets({
    String? search,
    String? status,
    String? category,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      where.add('(asset_id LIKE ? OR name LIKE ? OR category LIKE ?)');
      final pat = '%$search%';
      args.addAll([pat, pat, pat]);
    }
    if (status != null && status.isNotEmpty) {
      where.add('status = ?');
      args.add(status);
    }
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }
    final q = where.isEmpty
        ? 'SELECT * FROM assets ORDER BY id'
        : 'SELECT * FROM assets WHERE ${where.join(' AND ')} ORDER BY id';
    final rows = await db.rawQuery(q, args);
    return _withRelations(rows);
  }

  Future<List<Map<String, dynamic>>> _withRelations(
      List<Map<String, dynamic>> rows) async {
    final db = await database;
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final m = Map<String, dynamic>.from(row);
      if (m['current_user_id'] != null) {
        final u = await db.query('employees',
            where: 'id = ?', whereArgs: [m['current_user_id']]);
        if (u.isNotEmpty) {
          m['current_user'] = {
            'id': u.first['id'],
            'name': u.first['name'],
            'email': u.first['email'],
            'department': u.first['department'],
            'phone': u.first['phone'],
          };
        }
      }
      if (m['current_location_id'] != null) {
        final l = await db.query('locations',
            where: 'id = ?', whereArgs: [m['current_location_id']]);
        if (l.isNotEmpty) {
          m['current_location'] = {
            'id': l.first['id'],
            'name': l.first['name'],
            'building': l.first['building'],
            'room': l.first['room'],
            'description': l.first['description'],
          };
        }
      }
      if (m['current_drone_id'] != null) {
        final d = await db.query('drones',
            where: 'id = ?', whereArgs: [m['current_drone_id']]);
        if (d.isNotEmpty) {
          m['current_drone'] = {
            'id': d.first['id'],
            'drone_id': d.first['drone_id'],
            'name': d.first['name'],
            'model': d.first['model'],
            'status': d.first['status'],
            'description': d.first['description'],
          };
        }
      }
      if (m['project_id'] != null) {
        final p = await db.query('projects',
            where: 'id = ?', whereArgs: [m['project_id']]);
        if (p.isNotEmpty) {
          m['project'] = {
            'id': p.first['id'],
            'name': p.first['name'],
            'description': p.first['description'],
            'status': p.first['status'],
          };
        }
      }
      result.add(m);
    }
    return result;
  }

  Future<Map<String, dynamic>?> fetchAssetById(int id) async {
    final db = await database;
    final rows = await db.query('assets', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final res = await _withRelations(rows);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> fetchByAssetId(String assetId) async {
    final db = await database;
    final rows =
        await db.query('assets', where: 'asset_id = ?', whereArgs: [assetId]);
    if (rows.isEmpty) return null;
    final res = await _withRelations(rows);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>> createAsset(Map<String, dynamic> base) async {
    final db = await database;
    final now = _now();
    final row = Map<String, dynamic>.from(base);
    row['created_at'] = now;
    row['updated_at'] = now;
    row['status'] ??= 'available';
    row['condition_type'] ??= 'good';
    final id = await db.insert('assets', row);
    await insertMovement(id, action: 'created', toStatus: row['status']);
    final created = await fetchAssetById(id);
    return created!;
  }

  Future<void> updateAsset(int id, Map<String, dynamic> data) async {
    final db = await database;
    final row = Map<String, dynamic>.from(data);
    row['updated_at'] = _now();
    row.remove('id');
    await db.update('assets', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAssetPhoto(int id, String? photoPath) async {
    final db = await database;
    await db.update('assets', {'photo_path': photoPath, 'updated_at': _now()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> logMovement(
    int assetId, {
    required String action,
    int? fromUserId,
    int? toUserId,
    int? fromLocationId,
    int? toLocationId,
    int? fromDroneId,
    int? toDroneId,
    String? fromStatus,
    String? toStatus,
    String? purpose,
    String? remarks,
  }) async {
    await insertMovement(
      assetId,
      action: action,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromLocationId: fromLocationId,
      toLocationId: toLocationId,
      fromDroneId: fromDroneId,
      toDroneId: toDroneId,
      fromStatus: fromStatus,
      toStatus: toStatus,
      purpose: purpose,
      remarks: remarks,
    );
  }

  Future<int> insertMovement(
    int assetId, {
    required String action,
    int? fromUserId,
    int? toUserId,
    int? fromLocationId,
    int? toLocationId,
    int? fromDroneId,
    int? toDroneId,
    String? fromStatus,
    String? toStatus,
    String? purpose,
    String? remarks,
    int? performedBy,
  }) async {
    final db = await database;
    return db.insert('movements', {
      'asset_id': assetId,
      'action': action,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'from_drone_id': fromDroneId,
      'to_drone_id': toDroneId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'purpose': purpose,
      'remarks': remarks,
      'performed_by': performedBy,
      'created_at': _now(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchMovements(int assetId) async {
    final db = await database;
    final rows = await db.query('movements',
        where: 'asset_id = ?',
        whereArgs: [assetId],
        orderBy: 'id DESC');
    return _resolveMovementNames(rows);
  }

  Future<List<Map<String, dynamic>>> _resolveMovementNames(
      List<Map<String, dynamic>> rows) async {
    final db = await database;
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final m = Map<String, dynamic>.from(row);
      for (final c in [
        'from_user_id',
        'to_user_id',
        'from_drone_id',
        'to_drone_id',
        'from_location_id',
        'to_location_id',
      ]) {
        final id = m[c];
        if (id == null) {
          m[c == 'from_user_id'
                  ? 'from_user_name'
                  : c == 'to_user_id'
                      ? 'to_user_name'
                      : c == 'from_drone_id'
                          ? 'from_drone_name'
                          : c == 'to_drone_id'
                              ? 'to_drone_name'
                              : c == 'from_location_id'
                                  ? 'from_location_name'
                                  : 'to_location_name'] = null;
          continue;
        }
        final table = (c.contains('user'))
            ? 'employees'
            : (c.contains('drone')) ? 'drones' : 'locations';
        final nameCol = (c.contains('user'))
            ? 'name'
            : (c.contains('drone')) ? 'name' : 'name';
        final res = await db.query(table,
            columns: [nameCol], where: 'id = ?', whereArgs: [id]);
        final name =
            res.isNotEmpty ? res.first[nameCol] as String? : null;
        m[c == 'from_user_id'
                ? 'from_user_name'
                : c == 'to_user_id'
                    ? 'to_user_name'
                    : c == 'from_drone_id'
                        ? 'from_drone_name'
                        : c == 'to_drone_id'
                            ? 'to_drone_name'
                            : c == 'from_location_id'
                                ? 'from_location_name'
                                : 'to_location_name'] = name;
      }
      result.add(m);
    }
    return result;
  }

  Future<List<String>> fetchCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM assets ORDER BY category COLLATE NOCASE');
    return rows.map((r) => r['category'] as String).where((c) => c.isNotEmpty).toList();
  }

  /// Creates a named category that exists on its own (no assets required).
  Future<int> createCategory(String name) async {
    final db = await database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 0;
    return db.insert('categories', {
      'name': trimmed,
      'created_at': _now(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  /// Names of categories stored via "Add Category" (plus asset-derived ones
  /// users may have added as custom categories are handled by the UI union).
  Future<List<String>> fetchStoredCategories() async {
    final db = await database;
    final rows = await db.query('categories',
        orderBy: 'name COLLATE NOCASE');
    return rows
        .map((r) => r['name'] as String)
        .where((c) => c.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchRecentMovements() async {
    final db = await database;
    final rows = await db.query('movements', orderBy: 'id DESC', limit: 50);
    return rows;
  }

  // ============ EMPLOYEES ============

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final db = await database;
    return db.query('employees', orderBy: 'name');
  }

  Future<int> createEmployee(Map<String, dynamic> data) async {
    final db = await database;
    final maxId = Sqflite.firstIntValue(
            await db.rawQuery('SELECT MAX(id) FROM employees')) ??
        0;
    final row = Map<String, dynamic>.from(data);
    row['id'] = maxId + 1;
    return db.insert('employees', row);
  }

  Future<List<Map<String, dynamic>>> fetchEmployeeAssets(int employeeId) async {
    final db = await database;
    final rows = await db
        .query('assets', where: 'current_user_id = ?', whereArgs: [employeeId]);
    return _withRelations(rows);
  }

  // ============ DRONES ============

  Future<List<Map<String, dynamic>>> fetchDrones() async {
    final db = await database;
    return db.query('drones', orderBy: 'name');
  }

  Future<int> createDrone(Map<String, dynamic> data) async {
    final db = await database;
    final maxId = Sqflite.firstIntValue(
            await db.rawQuery('SELECT MAX(id) FROM drones')) ??
        0;
    final row = Map<String, dynamic>.from(data);
    row['id'] = maxId + 1;
    row['status'] ??= 'active';
    return db.insert('drones', row);
  }

  Future<List<Map<String, dynamic>>> fetchDroneAssets(int droneId) async {
    final db = await database;
    final rows = await db
        .query('assets', where: 'current_drone_id = ?', whereArgs: [droneId]);
    return _withRelations(rows);
  }

  // ============ LOCATIONS ============

  Future<List<Map<String, dynamic>>> fetchLocations() async {
    final db = await database;
    return db.query('locations', orderBy: 'name');
  }

  Future<int> createLocation(Map<String, dynamic> data) async {
    final db = await database;
    final maxId = Sqflite.firstIntValue(
            await db.rawQuery('SELECT MAX(id) FROM locations')) ??
        0;
    final row = Map<String, dynamic>.from(data);
    row['id'] = maxId + 1;
    return db.insert('locations', row);
  }

  Future<List<Map<String, dynamic>>> fetchLocationAssets(int locationId) async {
    final db = await database;
    final rows = await db.query('assets',
        where: 'current_location_id = ?', whereArgs: [locationId]);
    return _withRelations(rows);
  }

  // ============ PROJECTS ============

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final db = await database;
    return db.query('projects', orderBy: 'name');
  }

  Future<int> createProject(Map<String, dynamic> data) async {
    final db = await database;
    final maxId = Sqflite.firstIntValue(
            await db.rawQuery('SELECT MAX(id) FROM projects')) ??
        0;
    final row = Map<String, dynamic>.from(data);
    row['id'] = maxId + 1;
    return db.insert('projects', row);
  }

  Future<List<Map<String, dynamic>>> fetchProjectAssets(int projectId) async {
    final db = await database;
    final rows =
        await db.query('assets', where: 'project_id = ?', whereArgs: [projectId]);
    return _withRelations(rows);
  }

  // ============ DASHBOARD ============

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final db = await database;
    Future<int> count(String status) async =>
        Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM assets WHERE status = ?', [status])) ??
        0;
    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM assets')) ??
        0;
    return {
      'total_assets': total,
      'available': await count('available'),
      'assigned': await count('assigned'),
      'in_drone': await count('in_drone'),
      'testing': await count('testing'),
      'maintenance': await count('maintenance'),
      'missing': await count('missing'),
      'damaged': await count('damaged'),
    };
  }
}
