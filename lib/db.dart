import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class Storage {
  Database? db;

  bool connected() {
    return (db != null);
  }

  connect(void call()) {
    if (this.connected()) {
      call();
    }
    else {
      create().then((_) {
        call();
      });
    }
  }

  void after_connect(void call()) {
    if (this.connected()) {
      call();
    }
    else {
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (this.connected()) {
          call();
          timer.cancel();
        }
      });
    }
  }

  Future create() async {
    if (db == null) {
      print('open database');
      Database database = await openDatabase(
        "mypack.db",
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE groups(id INTEGER PRIMARY KEY, name TEXT, position INTEGER)');
          await db.execute(
              'CREATE TABLE pack(id INTEGER PRIMARY KEY, group_id INTEGER REFERENCES groups(id), name TEXT, value REAL, position INTEGER, active INTEGER)');
        },
      );
      print('set database');
      this.db = database;
    }
  }

  Future<List<Map>> groups() async {
    return await db!.rawQuery('select id,name from groups order by position asc');
  }

  Future group_count() async {
    return Sqflite.firstIntValue(await db!.rawQuery('select count(*) from groups'))!;
  }

  Future group_id(String group) async {
    return Sqflite.firstIntValue(await db!.rawQuery('select id from groups where name = ?', [group]))!;
  }

  Future add_group(String group) async {
    int position = await group_count();
    await db!.transaction((txn) async {
      int id = await txn.rawInsert(
          'INSERT INTO groups(name,position) VALUES(?,?)', [group, position]);
      print('inserted: $id');
    });
  }

  Future remove_group(int group_id) async {
    await db!.rawQuery('DELETE FROM groups where id = ?', [group_id]);
  }

  Future max_group_position(int group_id) async {
    int? pos = Sqflite.firstIntValue(await db!.rawQuery('select max(position) from pack where group_id = ?', [group_id]));
    if (pos == null) {
      return -1;
    }
    else {
      return pos;
    }
  }

  Future<int> add_item(int group_id, String item, double value) async {
    print("try to add item: $group_id $item $value");
    int position = await max_group_position(group_id);
    position++;
    return await db!.transaction((txn) async {
      int id = await txn.rawInsert(
          'INSERT INTO pack(group_id, name, value, position, active) VALUES(?,?,?,?,?)',
          [group_id, item, value, position, 0]);
      print('inserted: $id');
      return id;
    });
  }

  Future<List<Map>> items(int group_id) async {
    return await db!.rawQuery('select id,name,value,active from pack where group_id = ? order by position asc', [group_id]);
  }

  Future remove_item(int item_id) async {
    await db!.rawQuery('DELETE FROM pack where id = ?', [item_id]);
  }

  // TODO: Drag And Drop positions.
  // TODO: Active flag handling
}
