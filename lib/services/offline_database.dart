import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/order_model.dart';

class OfflineDatabase {
  OfflineDatabase._();

  static final OfflineDatabase instance = OfflineDatabase._();
  static const _databaseName = 'lulistrack_offline.db';
  static const _databaseVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final root = await getDatabasesPath();
    final path = p.join(root, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_orders (
            id TEXT PRIMARY KEY,
            tracking_number TEXT NOT NULL,
            client_name TEXT NOT NULL,
            address TEXT NOT NULL,
            colony TEXT NOT NULL,
            estimated_time TEXT NOT NULL,
            status TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            cache_group TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_history (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_deliveries (
            local_id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL,
            photo_path TEXT NOT NULL,
            signature_path TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            sync_started_at TEXT,
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_pending_status ON pending_deliveries(status)',
        );
        await db.execute("""
          CREATE UNIQUE INDEX idx_one_active_delivery_per_order
          ON pending_deliveries(order_id)
          WHERE status != 'duplicate'
        """);
        await db.execute(
          'CREATE INDEX idx_cached_group ON cached_orders(cache_group)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE cached_history (
              id TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              cached_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE pending_deliveries ADD COLUMN sync_started_at TEXT',
          );
          await db.update(
            'pending_deliveries',
            {'status': 'pending', 'sync_started_at': null},
            where: "status = 'syncing'",
          );

          final duplicateGroups = await db.rawQuery("""
            SELECT order_id
            FROM pending_deliveries
            WHERE status != 'duplicate'
            GROUP BY order_id
            HAVING COUNT(*) > 1
          """);
          for (final group in duplicateGroups) {
            final rows = await db.query(
              'pending_deliveries',
              columns: ['local_id'],
              where: 'order_id = ? AND status != ?',
              whereArgs: [group['order_id'], 'duplicate'],
              orderBy: 'created_at ASC, local_id ASC',
            );
            for (final duplicate in rows.skip(1)) {
              await db.update(
                'pending_deliveries',
                {'status': 'duplicate'},
                where: 'local_id = ?',
                whereArgs: [duplicate['local_id']],
              );
            }
          }

          await db.execute("""
            CREATE UNIQUE INDEX idx_one_active_delivery_per_order
            ON pending_deliveries(order_id)
            WHERE status != 'duplicate'
          """);
        }
      },
    );
    return _database!;
  }

  Future<void> cacheOrders(
    List<OrderModel> orders, {
    required String group,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'cached_orders',
        where: 'cache_group = ?',
        whereArgs: [group],
      );

      final batch = txn.batch();
      for (final order in orders) {
        if (order.id.isEmpty) continue;
        batch.insert(
          'cached_orders',
          {
            ...order.toJson(),
            'cache_group': group,
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<OrderModel>> getCachedOrders({
    required String group,
  }) async {
    final db = await database;
    final rows = await db.query(
      'cached_orders',
      where: 'cache_group = ?',
      whereArgs: [group],
      orderBy: 'cached_at DESC',
    );
    return rows.map((row) => OrderModel.fromJson(row)).toList();
  }


  Future<void> cacheCompletedOrders(List<Map<String, dynamic>> orders) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('cached_history');
      final batch = txn.batch();
      for (final order in orders) {
        final rawId = order['id']?.toString() ?? '';
        final id = rawId.trim().isNotEmpty
            ? rawId
            : order['tracking_number']?.toString() ?? '';
        if (id.trim().isEmpty) continue;
        batch.insert(
          'cached_history',
          {'id': id, 'payload': jsonEncode(order), 'cached_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> getCachedCompletedOrders() async {
    final db = await database;
    final rows = await db.query('cached_history', orderBy: 'cached_at DESC');
    return rows
        .map((row) => jsonDecode(row['payload'] as String))
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<bool> enqueueDelivery({
    required String localId,
    required String orderId,
    required String photoPath,
    required String signaturePath,
    required DateTime timestamp,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'pending_deliveries',
        columns: ['local_id'],
        where: 'order_id = ? AND status != ?',
        whereArgs: [orderId, 'duplicate'],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;

      await txn.insert('pending_deliveries', {
        'local_id': localId,
        'order_id': orderId,
        'photo_path': photoPath,
        'signature_path': signaturePath,
        'timestamp': timestamp.toIso8601String(),
        'status': 'pending',
        'sync_started_at': null,
        'attempts': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    });
  }

  Future<Map<String, Object?>?> getDeliveryByOrderId(String orderId) async {
    final db = await database;
    final rows = await db.query(
      'pending_deliveries',
      where: 'order_id = ? AND status != ?',
      whereArgs: [orderId, 'duplicate'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> getPendingDeliveries() async {
    final db = await database;
    return db.query(
      'pending_deliveries',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, Object?>>> claimPendingDeliveries() async {
    final db = await database;
    return db.transaction((txn) async {
      final recoveryLimit = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      await txn.update(
        'pending_deliveries',
        {'status': 'pending', 'sync_started_at': null},
        where: "status = 'syncing' AND sync_started_at < ?",
        whereArgs: [recoveryLimit],
      );

      final rows = await txn.query(
        'pending_deliveries',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );
      final now = DateTime.now().toIso8601String();
      for (final row in rows) {
        await txn.update(
          'pending_deliveries',
          {'status': 'syncing', 'sync_started_at': now},
          where: 'local_id = ? AND status = ?',
          whereArgs: [row['local_id'], 'pending'],
        );
      }
      return rows;
    });
  }

  Future<void> markDeliverySynced(String localId) async {
    final db = await database;
    await db.update(
      'pending_deliveries',
      {'status': 'synced', 'last_error': null, 'sync_started_at': null},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markDeliveryNeedsAttention(
    String localId,
    String error,
  ) async {
    final db = await database;
    await db.update(
      'pending_deliveries',
      {
        'status': 'needs_attention',
        'sync_started_at': null,
        'last_error': error,
        'attempts': 1,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> recordDeliveryFailure(
    String localId,
    String error,
  ) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE pending_deliveries
      SET attempts = attempts + 1,
          last_error = ?,
          status = 'pending',
          sync_started_at = NULL
      WHERE local_id = ?
      ''',
      [error, localId],
    );
  }
}
