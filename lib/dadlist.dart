import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:mypack/db.dart';

class DadList extends StatefulWidget {
  DadList({Key? key}) : super(key: key);

  var storage, state;

  void setStorage(Storage s) {
    storage = s;
  }

  Storage getStorage() {
    return storage;
  }

  DadListState getState() {
    return state;
  }

  @override
  DadListState createState() {
    state = DadListState(storage);
    return state;
  }
}

class DadListState extends State<DadList> {
  var storage;
  var _contents = <DragAndDropList>[];
  var group_positions = [];
  var active_map = HashMap();

  DadListState(this.storage);

  Widget make_dad_value(int item_id, String item_name, double item_value) {
    return Container(
      width: 300,
      child:
      Dismissible(key: Key(item_id.toString()),
          background: Container(color: Colors.red),
          direction: DismissDirection.horizontal,
          onDismissed: ((direction) {
            storage.remove_item(item_id).then((_) {
              //_contents[new_group_positions.length - 1].children.removeAt(item_position);
              this.setContents();
            });
          }),
          child: Text('${item_name} ${item_value}')),
    );
  }

  Widget make_checkbox(int item_id) {
    return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
      return Checkbox(value: active_map[item_id],
          onChanged: ((value) {
            // print('Checkbox #${item_id} (${active_map[item_id]}) changed to $value');
            setState(() {
              active_map[item_id] = value;
              storage.update_active(item_id, value, (() {
                // print('Update total');
                storage.set_total(storage.get_master().update_total);
              }));
            });
          }));
    });
  }

  Widget make_header(int group_id, String group_name) {
    return Container(width: 300,
                     child: Dismissible(key: Key(group_id.toString()),
                                  background: Container(color: Colors.red),
                                  direction: DismissDirection.horizontal,
                                  onDismissed: ((direction) {
                                    storage.remove_group(group_id).then((_) {
                                      this.setContents();
                                    });
                                  }),
                                  child: Column(children: <Widget>[
                                                Row(children: [
                                                    Padding(padding: EdgeInsets.only(left: 8, bottom: 4),
                                                            child:
                                                              Text('${group_name}',
                                                                style: TextStyle(fontWeight: FontWeight.bold,
                                                                fontSize: 16))),
                                                    ]),
                                                ])));
  }

  void setContents() {
        //print('SetContents');
        var new_contents = <DragAndDropList>[];
        var new_group_positions = [];
        storage.after_connect(() {
          //print('SetContents: conntected');
          storage.groups().then((groups) {
            setState(() {
              groups.forEach((g) {
                var group_id = g['id'];
                var group_name = g['name'];
                var children = <DragAndDropItem>[];
                new_group_positions.add(group_id);
                //print('SetContents: add group $group_name');
                storage.items(group_id).then((items) {
                  items.forEach((e) {
                    var item_id = e['id'];
                    var item_name = e['name'];
                    var item_value = e['value'];
                    var item_active = e['active'];
                    var item_position = e['position'];
                    bool active = (item_active == 1);
                    active_map[item_id] = active;
                    //print('SetContents: add item $item_name');
                    children.add(DragAndDropItem(child: Row(
                        children: [
                          this.make_checkbox(item_id),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: this.make_dad_value(item_id, item_name, item_value)
                          ),
                        ])));
                  });
                });
                new_contents.add(DragAndDropList(
                    header: make_header(group_id, group_name),
                    children: children
                ));
              });
              //print('SetContents: set new content');
              _contents = new_contents;
              group_positions = new_group_positions;
            });
          });
        });
  }

  void add_item(int group_id, int id, String name, double value) {
    active_map[id] = false;
    var item = DragAndDropItem(child: Row(
        children: [
          this.make_checkbox(id),
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: 8, horizontal: 12),
            child: this.make_dad_value(id, name, value),
          ),
        ]));

    // search of group position
    var group_pos = 0;
    for(var i=0; i<group_positions.length; i++) {
      if (group_positions[i] == group_id) {
        group_pos = i;
      }
    }
    var count = _contents[group_pos].children.length;
    setState(() {
      _contents[group_pos].children.insert(count, item);
    });
  }

  @override
  void initState() {
    //print('initState');
    super.initState();
    this.setContents();
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor = Color.fromARGB(255, 243, 242, 248);
    return DragAndDropLists(
        children: _contents,
        onItemReorder: _onItemReorder,
        onListReorder: _onListReorder,
        listPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemDivider: Divider(
          thickness: 2,
          height: 2,
          color: backgroundColor,
        ),
        itemDecorationWhileDragging: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 3,
              offset: Offset(0, 0), // changes position of shadow
            ),
          ],
        ),
        listInnerDecoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        lastItemTargetHeight: 8,
        addLastItemTargetHeightToTop: true,
        lastListTargetSize: 40,
        listDragHandle: DragHandle(
          verticalAlignment: DragHandleVerticalAlignment.top,
          child: Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(
              Icons.menu,
              color: Colors.black26,
            ),
          ),
        ),
        itemDragHandle: DragHandle(
          child: Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(
              Icons.menu,
              color: Colors.blueGrey,
            ),
          ),
        ),
      );
  }

  _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      var movedItem = _contents[oldListIndex].children.removeAt(oldItemIndex);
      _contents[newListIndex].children.insert(newItemIndex, movedItem);
      storage.onItemReorder(oldItemIndex, oldListIndex, newItemIndex, newListIndex);
    });
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = _contents.removeAt(oldListIndex);
      _contents.insert(newListIndex, movedList);
      storage.onListReorder(oldListIndex, newListIndex);
    });

  }
}
