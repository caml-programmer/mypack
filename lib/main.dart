import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mypack/entity.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:mypack/db.dart';
import 'package:sqflite/sqflite.dart';

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
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Storage storage = Storage();

  List<Entity> entities = [
    Entity('A', 1.3),
    Entity('B', 2.8),
    Entity('C', 0.9),
  ];

  TextField nameField = TextField(controller: TextEditingController());
  TextField weightField = TextField(controller: TextEditingController());

  void showAddDialog(BuildContext context) {
    AlertDialog addDialog = AlertDialog(
      title: Text('Add Entity?'),
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
                child: Text('Weight')),
            Expanded(
                flex: 2,
                child : weightField
            )
          ]),

        ],
        )
        ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            nameField.controller!.clear();
            weightField.controller!.clear();
          },
          child: Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            add_entity(nameField, weightField);
            Navigator.pop(context);
          },
          child: Text('ADD'),
        ),
      ],
    );
    showDialog(context: context, builder: (context) => addDialog);
  }

  void add_entity(TextField name, TextField weight) {
    setState(() {
      entities.add(Entity(name.controller!.text,
                          double.parse(weight.controller!.text)));
      name.controller!.clear();
      weight.controller!.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: entities.map((e) => Text('${e.name} - ${e.weight}')).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddDialog(context);
        },
        tooltip: 'Add entity',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
