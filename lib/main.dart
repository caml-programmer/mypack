import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mypack/db.dart';
import 'package:mypack/dadlist.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "My Pack",
      home: const MyHomePage(title: 'My Pack')
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();

}

class MyHomePageState extends State<MyHomePage> {
  final storage = Storage();

  var total_value = 0.0;

  MyHomePageState() {
    storage.set_master(this);
    storage.after_connect(() {
      this.updateGroups();
      storage.set_total(this.update_total);
    });
  }

  TextField groupField = TextField(controller: TextEditingController());
  TextField nameField = TextField(controller: TextEditingController());
  TextField valueField = TextField(controller: TextEditingController());

  late int group_count;
  late List<Map> groups;
  var selected_group_id = null;

  var dad = DadList();

  @override
  void initState() {
    super.initState();
    dad.setStorage(storage);
  }

  void updateGroups() {
    storage.group_count().then((group_count) {
      // print('Group count is $group_count');
      storage.groups().then((groups) {
        this.group_count = group_count;
        this.groups = groups;
        // print('Groups: $groups');
      });
    });
  }

  void showAddGroupDialog(BuildContext context) {
    AlertDialog addDialog = AlertDialog(
      title: Text('ADD GROUP'),
      backgroundColor: Colors.blueGrey[200],
      content:
      Container (
          padding: EdgeInsets.all(20.0),
          color: Colors.blueGrey[100],
          height: 100,
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Text('Name')),
                Expanded(
                    flex: 2,
                    child : groupField
                )
              ])
            ],
          )
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            groupField.controller!.clear();
          },
          child: Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            storage.add_group(groupField.controller!.text.toString(), () {
              this.updateGroups();
              this.dad_refresh();
            });
            //groups.add(groupField.controller!.text.toString());
            groupField.controller!.clear();
            Navigator.pop(context);
          },
          child: Text('ADD'),
        ),
      ],
    );
    showDialog(context: context, builder: (context) => addDialog);
  }

  void showAddEntityDialog(BuildContext context) {
    selected_group_id = (groups.length > 0) ? groups[0]['id'] : null;
    // print('Group-Id $selected_group_id has been selected on start dialog');

    AlertDialog addDialog = AlertDialog(
      title: Text('ADD ITEM'),
      backgroundColor: Colors.blueGrey[200],
      content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            var group_selector = DropdownButton<int>(
                value: selected_group_id,
                items: groups.map((group) =>
                    DropdownMenuItem<int>(child: Text(group['name']),
                        value: group['id'])).toList(),
                onChanged: (int? new_value) {
                  setState(() {
                    selected_group_id = new_value;
                    // print('Group-Id $selected_group_id has been selected');
                  });
                }
            );

            return Container(
                padding: EdgeInsets.all(20.0),
                color: Colors.blueGrey[100],
                height: 200,
                child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(children: <Widget>[
                      Expanded(
                          flex: 1,
                          child: Text('Name')),
                      Expanded(
                          flex: 2,
                          child: nameField
                      )
                    ]),
                    Row(children: <Widget>[
                      Expanded(
                          flex: 1,
                          child: Text('Value')),
                      Expanded(
                          flex: 2,
                          child: valueField
                      )
                    ]),
                    Row(children: [
                      Expanded(flex: 1, child: Text('To')),
                      Expanded(flex: 2, child: group_selector)
                    ]),

                  ],
                )
            );
          }),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            nameField.controller!.clear();
            valueField.controller!.clear();
          },
          child: Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            // print("Selected group-id ${selected_group_id}");
            if (selected_group_id != null) {
              add_entity(selected_group_id, nameField, valueField);
            }
            Navigator.pop(context);
          },
          child: Text('ADD'),
        ),
      ],
    );
    showDialog(context: context, builder: (context) => addDialog);
  }

  void add_entity(int group_id, TextField name, TextField value) {
    // print("add item $name ($value) to group #${group_id}");
    var val = double.parse(value.controller!.text);
    Future<int> f = storage.add_item(group_id, name.controller!.text, val);
    f.then((id) {
      dad.getState().add_item(group_id, id, name.controller!.text, val);
      //this.dad_refresh();
      name.controller!.clear();
      value.controller!.clear();
    });
  }

  void update_total(double new_value) {
    setState(() {
      total_value = new_value;
    });
  }

  void dad_refresh() {
    storage.after_connect(() {
      dad.getState().setContents();
    });
  }

  Future<String> dump_path() async {
    Directory sup_dir = await getApplicationSupportDirectory();
    Directory? ext_dir = await getExternalStorageDirectory();
    // print('ext-dir: ${ext_dir}');
    if (ext_dir == null) {
      return '${sup_dir.path}/mypack.json';
    }
    else {
      return '${ext_dir.path}/mypack.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    dad.setStorage(storage);
    storage.connect(() {}); // start connection
    //Future.delayed(Duration(seconds: 10), () {
    //  this.dad_refresh();
    //});

    Timer.periodic(Duration(seconds: 5), (timer) {
      if (storage.connected()) {
        storage.export().then((dump) {
          this.dump_path().then((path) {
            var dump_file = File(path);
            dump_file.create(recursive: true);
            var writer = dump_file.openWrite();
            writer.write(dump);
            writer.close();
            writer.done.then(((_) {
              var snackBar = SnackBar(content: Text('Writing a backup to ${path}'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }));
            timer.cancel();
          });
        });
      }
    });

    var fab2 = Stack(
      children: <Widget>[
        Padding(padding: EdgeInsets.only(left:31),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FloatingActionButton(
            onPressed: () { showAddGroupDialog(context); },
            tooltip: 'Add group',
            child: Icon(Icons.add_photo_alternate),),
        ),),

        Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            onPressed: () { showAddEntityDialog(context); },
            tooltip: 'Add item',
            child: Icon(Icons.add),),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: dad,
      bottomNavigationBar: Center(
          child: Text('Total: ${total_value.toStringAsPrecision(3)} kg',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
          ),
          heightFactor: 3,
          widthFactor: 100,
      ),
      floatingActionButton: fab2
    );
  }
}
