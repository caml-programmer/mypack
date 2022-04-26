import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mypack/main.dart';
import 'package:sqflite/sqflite.dart';

class Storage {
  Database? db;

  var master = null;

  void set_master(MyHomePageState new_master) {
    master = new_master;
  }
  MyHomePageState get_master() {
    return master;
  }

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

      // await db!.execute('DELETE FROM groups');
      // await db!.execute('DELETE FROM pack');
      // await db!.execute('INSERT INTO pack (group_id, name, value, position, active) VALUES (?,?,?,?,?)',[1,'AA',1.0,0,0]);
      // await db!.execute('INSERT INTO pack (group_id, name, value, position, active) VALUES (?,?,?,?,?)',[1,'BB',2.0,1,0]);
      // await db!.execute('INSERT INTO pack (group_id, name, value, position, active) VALUES (?,?,?,?,?)',[1,'CC',3.0,2,0]);

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

  Future add_group(String group, void call()) async {
    int position = await group_count();
    await db!.transaction((txn) async {
      int id = await txn.rawInsert(
          'INSERT INTO groups(name,position) VALUES(?,?)', [group, position]);
      print('inserted: $id');
      call();
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

  Future set_total(void call(double total)) async {
    List<Map<String,Object?>> records = await db!.rawQuery('select sum(value) as sum from pack where active = ?', [1]);
    double? total = records.first['sum'] as double?;
    // print('total is ${total}');
    if (total == null) {
      call(0.0);
    }
    else {
      call(total);
    }
  }

  Future update_active(int id, bool value, void call()) async {
    await db!.rawQuery('update pack set active = ? where id = ?', [value ? 1 : 0, id]);
    call();
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

  Future move_down_positions(Transaction txn, int group_id, int min_pos, int cur_pos) async {
    if (cur_pos >= min_pos) {
        await txn.rawQuery('UPDATE pack SET position=? where group_id = ? and position = ?',
            [cur_pos + 1, group_id, cur_pos]);
        await move_down_positions(txn, group_id, min_pos, cur_pos - 1);
    }
  }

  Future move_up_positions(Transaction txn, int group_id, int max_pos, int cur_pos) async {
    if (cur_pos <= max_pos) {
      await txn.rawQuery('UPDATE pack SET position=? where group_id = ? and position = ?',
          [cur_pos - 1, group_id, cur_pos]);
      await move_up_positions(txn, group_id, max_pos, cur_pos + 1);
    }
  }

  Future onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) async {
    print("storage.onItemReorder($oldItemIndex, $oldListIndex, $newItemIndex, $newListIndex)");
    int old_group_id = Sqflite.firstIntValue(await db!.rawQuery('select id from groups where position = ?', [oldListIndex]))!;
    int new_group_id = Sqflite.firstIntValue(await db!.rawQuery('select id from groups where position = ?', [newListIndex]))!;
    int? old_item_id  = Sqflite.firstIntValue(await db!.rawQuery('select id from pack where position = ? and group_id = ?', [oldItemIndex, old_group_id]));
    int? new_item_id  = Sqflite.firstIntValue(await db!.rawQuery('select id from pack where position = ? and group_id = ?', [newItemIndex, new_group_id]));
    print("$old_group_id.$old_item_id -> $new_group_id.$new_item_id");

    if (oldListIndex != newListIndex) {
      int new_max_position = await max_group_position(new_group_id);
      int old_max_position = await max_group_position(old_group_id);

      await db!.transaction((txn) async {
        print("move down positions ${newItemIndex} to ${new_max_position} for group ${new_group_id}");
        await move_down_positions(txn, new_group_id, newItemIndex, new_max_position);
        print("move up positions ${old_max_position} to ${oldItemIndex} for group ${old_group_id}");
        await move_up_positions(txn, old_group_id, old_max_position, oldItemIndex);
        if (old_item_id != null) {
          await txn.rawQuery(
              'UPDATE pack SET group_id=?, position=? where id=?',
              [new_group_id, newItemIndex, old_item_id]);
        }
      });
    }
    else {
      await db!.transaction((txn) async {
        if (old_item_id != null && new_item_id != null) {
          print('swap #$old_item_id[$oldItemIndex] -> #$new_item_id[$newItemIndex]');
          if (oldItemIndex > newItemIndex) {
            print("move down positions ${newItemIndex} to ${oldItemIndex}");
            await move_down_positions(txn, new_group_id, newItemIndex, oldItemIndex);
            print("set position $newItemIndex for id = $old_item_id");
            await txn.rawQuery('UPDATE pack SET position=? where id=?',
                [newItemIndex, old_item_id]);
          }
          if (newItemIndex > oldItemIndex) {
            print("move up positions ${newItemIndex} to ${oldItemIndex}");
            await move_up_positions(txn, new_group_id, newItemIndex, oldItemIndex);
            print("set position $newItemIndex for id = $old_item_id");
            await txn.rawQuery('UPDATE pack SET position=? where id=?',
                [newItemIndex, old_item_id]);
          }
        }
      });
    }
  }

  Future onListReorder(int oldListIndex, int newListIndex) async {
    int old_group_id = Sqflite.firstIntValue(await db!.rawQuery('select id from groups where position = ?', [oldListIndex]))!;
    int new_group_id = Sqflite.firstIntValue(await db!.rawQuery('select id from groups where position = ?', [newListIndex]))!;
    await db!.transaction((txn) async {
      await txn.rawQuery('UPDATE groups SET position = ? where id = ?', [oldListIndex, new_group_id]);
      await txn.rawQuery('UPDATE groups SET position = ? where id = ?', [newListIndex, old_group_id]);
    });
  }

}
