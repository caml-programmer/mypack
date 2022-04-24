import 'package:sqflite/sqflite.dart';

class Storage {
  Database? db;

  Storage() {
    create().then((_) {});
  }

  Future create() async {
    Database database = await openDatabase(
      "mypack.db",
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE groups(id INTEGER PRIMARY KEY, name TEXT, position INTEGER)');
        await db.execute(
            'CREATE TABLE pack(id INTEGER PRIMARY KEY, group_id INTEGER REFERENCES groups(id), name TEXT, value REAL, position INTEGER)');
      },
    );
    this.db = database;
  }

  Future add_group(String group, int position) async {
    await db!.transaction((txn) async {
      int id = await txn.rawInsert(
          'INSERT INTO groups(name,position) VALUES(?,?)', [group, position]);
      print('inserted: $id');
    });
  }

  Future add_item(String item, String group,
      int position) async {
    int group_id = Sqflite.firstIntValue(await db!.rawQuery(
        'select id from groups where name = ?', [group]))!;
    await db!.transaction((txn) async {
      int id = await txn.rawInsert(
          'INSERT INTO pack(group, position) VALUES(?,?)',
          [group_id, position]);
      print('inserted: $id');
    });
  }
}