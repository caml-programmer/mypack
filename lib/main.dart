import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mypack/entity.dart';
import 'package:mypack/db.dart';
import 'package:mypack/dadlist.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "My Pack",
      home: MyHomePage(title: 'MY PACK')
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
  Storage storage = Storage();

  TextField groupField = TextField(controller: TextEditingController());
  TextField nameField = TextField(controller: TextEditingController());
  TextField valueField = TextField(controller: TextEditingController());

  late int group_count;
  late List<Map> groups;
  var selected_group = null;

  MyHomePageState() {
    storage.create().then((_) {
      print('Storage conntection created');
      updateGroups();
    });
  }

  void updateGroups() {
    storage.group_count().then((group_count) {
      print('Group count is $group_count');
      storage.groups().then((groups) {
        this.group_count = group_count;
        this.groups = groups;
        print('Groups: $groups');
      });
    });
  }

  List<Map> getGroups() {
    print('Get groups');
    if (groups == null) {
      updateGroups();
    }
    return groups;
  }

  void showAddGroupDialog(BuildContext context) {
    AlertDialog addDialog = AlertDialog(
      title: Text('Add group'),
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
            storage.add_group(groupField.controller!.text.toString());
            Navigator.pop(context);
          },
          child: Text('ADD'),
        ),
      ],
    );
    showDialog(context: context, builder: (context) => addDialog);
  }

  void showAddEntityDialog(BuildContext context) {
        var groups = getGroups();
        var def_value = (groups.length > 0) ? groups[0]['name'] : null;
        var group_selector = DropdownButton(
            value: def_value,
            items: groups.map((group) =>
                DropdownMenuItem(child: Text(group['name']),
                                 value: group['name'])).toList(),
            onChanged: (new_value) {
              setState(() {
                selected_group = new_value;
                print('Group $selected_group has been selected');
              });
        });

        AlertDialog addDialog = AlertDialog(
          title: Text('Add entity'),
          backgroundColor: Colors.blueGrey[200],
          content:
          Container (
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
                        child : nameField
                    )
                  ]),
                  Row(children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: Text('Value')),
                    Expanded(
                        flex: 2,
                        child : valueField
                    )
                  ]),
                  Row(children: [
                    Expanded(flex: 1, child: Text('To')),
                    Expanded(flex: 2, child: group_selector)
                  ]),

                ],
              )
          ),
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
                if (selected_group != null) {
                  add_entity(selected_group['id'], nameField, valueField);
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
    setState(() {
      storage.add_item(group_id, name.controller!.text, double.parse(value.controller!.text));
      name.controller!.clear();
      value.controller!.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    var dad = DadList();
    dad.setStorage(storage);
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
            tooltip: 'Add entity',
            child: Icon(Icons.add),),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: dad,
      floatingActionButton: fab2
    );
  }
}
