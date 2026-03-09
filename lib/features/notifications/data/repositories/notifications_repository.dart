import '../../../../core/services/db/db_helper.dart';
import '../models/notification_model.dart';

abstract class NotificationsRepository {
  Future<List<NotificationModel>> fetchPage({
    required int limit,
    required int offset,
  });

  Future<int> countUnread();

  Future<void> markAsRead(String id);

  Future<void> deleteById(String id);

  Future<void> clearAll();
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  static const String _table = 'notifications';

  final DbHelper _db;

  NotificationsRepositoryImpl(this._db);

  @override
  Future<List<NotificationModel>> fetchPage({
    required int limit,
    required int offset,
  }) async {
    final rows = await _db.rawSelect(
      sql: '''
        SELECT *
        FROM $_table
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?;
      ''',
      params: [limit, offset],
    );

    return rows.map(NotificationModel.fromDbMap).toList();
  }

  @override
  Future<int> countUnread() async {
    return _db.countRows(
      table: _table,
      condition: 'is_read = 0',
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    await _db.update(
      table: _table,
      obj: {'is_read': 1},
      condition: 'id = ?',
      conditionParams: [id],
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await _db.delete(
      table: _table,
      condition: 'id = ?',
      conditionParams: [id],
    );
  }

  @override
  Future<void> clearAll() async {
    await _db.execute(sql: 'DELETE FROM $_table;');
  }
}
