import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/month_model.dart';
import '../models/class_model.dart';
import '../models/transaction_model.dart';
import '../models/ledger_model.dart';
import '../models/savings_model.dart';

class DbHelper {
  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expy.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE months (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_year TEXT NOT NULL UNIQUE,
        initial_balance REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_id INTEGER NOT NULL,
        class_name TEXT NOT NULL,
        FOREIGN KEY (month_id) REFERENCES months(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_id INTEGER NOT NULL,
        entity_name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        original_month_year TEXT NOT NULL,
        note TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (month_id) REFERENCES months(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE savings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (month_id) REFERENCES months(id)
      )
    ''');
  }

  // ─── MONTHS ───────────────────────────────────────────────────────────────

  Future<List<MonthModel>> getAllMonths() async {
    final db = await database;
    final rows = await db.query('months', orderBy: 'id DESC');
    return rows.map((r) => MonthModel.fromMap(r)).toList();
  }

  Future<MonthModel?> getMonth(String monthYear) async {
    final db = await database;
    final rows = await db.query(
      'months',
      where: 'month_year = ?',
      whereArgs: [monthYear],
    );
    if (rows.isEmpty) return null;
    return MonthModel.fromMap(rows.first);
  }

  Future<int> insertMonth(MonthModel m) async {
    final db = await database;
    return await db.insert('months', m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ─── CLASSES ──────────────────────────────────────────────────────────────

  Future<List<ClassModel>> getClassesForMonth(int monthId) async {
    final db = await database;
    final rows = await db.query(
      'classes',
      where: 'month_id = ?',
      whereArgs: [monthId],
      orderBy: 'id ASC',
    );
    return rows.map((r) => ClassModel.fromMap(r)).toList();
  }

  Future<int> insertClass(ClassModel c) async {
    final db = await database;
    return await db.insert('classes', c.toMap());
  }

  Future<void> deleteClass(int classId) async {
    final db = await database;
    await db.delete('transactions', where: 'class_id = ?', whereArgs: [classId]);
    await db.delete('classes', where: 'id = ?', whereArgs: [classId]);
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactionsForClass(int classId) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'timestamp DESC',
    );
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<double> getTotalSpentForClass(int classId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE class_id = ?',
      [classId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalSpentForMonth(int monthId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(t.amount) as total
      FROM transactions t
      JOIN classes c ON t.class_id = c.id
      WHERE c.month_id = ?
    ''', [monthId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    return await db.insert('transactions', t.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ─── LEDGER ───────────────────────────────────────────────────────────────

  Future<List<LedgerModel>> getLedgerForMonth(int monthId) async {
    final db = await database;
    final rows = await db.query(
      'ledger',
      where: 'month_id = ?',
      whereArgs: [monthId],
      orderBy: 'timestamp DESC',
    );
    return rows.map((r) => LedgerModel.fromMap(r)).toList();
  }

  Future<int> insertLedger(LedgerModel l) async {
    final db = await database;
    return await db.insert('ledger', l.toMap());
  }

  Future<void> settleLedger(int id) async {
    final db = await database;
    await db.update(
      'ledger',
      {'is_settled': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteLedger(int id) async {
    final db = await database;
    await db.delete('ledger', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> carryForwardUnsettledLedger(int currentMonthId, String currentMonthYear) async {
    final db = await database;
    // Get all unsettled ledger entries from ALL other months
    final rows = await db.rawQuery('''
      SELECT l.* FROM ledger l
      JOIN months m ON l.month_id = m.id
      WHERE l.is_settled = 0
        AND l.month_id != ?
    ''', [currentMonthId]);

    for (final row in rows) {
      final originalMonthYear = row['original_month_year'] as String;
      final entityName = row['entity_name'] as String;
      final timestamp = row['timestamp'] as String;

      // Check for duplicate
      final existing = await db.query(
        'ledger',
        where: 'month_id = ? AND original_month_year = ? AND entity_name = ? AND timestamp = ?',
        whereArgs: [currentMonthId, originalMonthYear, entityName, timestamp],
      );
      if (existing.isEmpty) {
        await db.insert('ledger', {
          'month_id': currentMonthId,
          'entity_name': entityName,
          'amount': row['amount'],
          'type': row['type'],
          'is_settled': 0,
          'original_month_year': originalMonthYear,
          'note': row['note'],
          'timestamp': timestamp,
        });
      }
    }
  }

  // ─── SAVINGS ──────────────────────────────────────────────────────────────

  Future<List<SavingsModel>> getSavingsForMonth(int monthId) async {
    final db = await database;
    final rows = await db.query(
      'savings',
      where: 'month_id = ?',
      whereArgs: [monthId],
      orderBy: 'timestamp DESC',
    );
    return rows.map((r) => SavingsModel.fromMap(r)).toList();
  }

  Future<double> getNetSavingsForMonth(int monthId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN type = 'deposit' THEN amount ELSE 0 END) -
        SUM(CASE WHEN type = 'withdraw' THEN amount ELSE 0 END) as net
      FROM savings WHERE month_id = ?
    ''', [monthId]);
    return (result.first['net'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> insertSavings(SavingsModel s) async {
    final db = await database;
    return await db.insert('savings', s.toMap());
  }

  Future<void> deleteSavings(int id) async {
    final db = await database;
    await db.delete('savings', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CLEANUP ──────────────────────────────────────────────────────────────

  Future<void> cleanOldData() async {
    final db = await database;
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month - 11, 1);
    
        '${cutoff.month.toString().padLeft(2, '0')}-${cutoff.year}';

    // Get months older than 12 months
    final oldMonths = await db.rawQuery('''
      SELECT id, month_year FROM months
    ''');

    for (final row in oldMonths) {
      final my = row['month_year'] as String;
      final parts = my.split('-');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final y = int.tryParse(parts[1]) ?? 0;
        final monthDate = DateTime(y, m, 1);
        if (monthDate.isBefore(cutoff)) {
          final id = row['id'] as int;
          // Delete in order: transactions, classes, ledger, savings, months
          final classes = await db.query('classes', where: 'month_id = ?', whereArgs: [id]);
          for (final c in classes) {
            await db.delete('transactions', where: 'class_id = ?', whereArgs: [c['id']]);
          }
          await db.delete('classes', where: 'month_id = ?', whereArgs: [id]);
          await db.delete('ledger', where: 'month_id = ?', whereArgs: [id]);
          await db.delete('savings', where: 'month_id = ?', whereArgs: [id]);
          await db.delete('months', where: 'id = ?', whereArgs: [id]);
        }
      }
    }
    // suppress unused variable warning
    
  }
}
