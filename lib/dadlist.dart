import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:mypack/db.dart';

class DadList extends StatefulWidget {
  DadList({Key? key}) : super(key: key);

  var storage;
  var state_refresh = (() {});

  void setStorage(Storage s) {
    storage = s;
    s.create().then((_) {});
  }

  Storage getStorage() {
    return storage;
  }

  void refresh() {
    state_refresh();
  }

  @override
  DadListState createState() {
    var state = DadListState(storage);
    state_refresh = (() { state.refresh(); });
    return state;
  }
}

class DadListState extends State<DadList> {
  var storage;
  var _contents = <DragAndDropList>[];

  DadListState(this.storage) {
      setContents();
  }

  void setContents() {
        print('SetContents');
        storage.connect(() {
          storage.groups().then((groups) {
            _contents.clear();
            groups.forEach((g) {
              var group_id = g['id'];
              var group_name = g['name'];
              var children = <DragAndDropItem>[];
              storage.items(group_id).then((items) {
                  items.forEach((e) {
                  var item_name = e['name'];
                  var item_value = e['value'];
                  var item_active = e['active'];
                  bool active = (item_active == 1);
                  children.add(DragAndDropItem(child: Row(
                      children: [
                        Checkbox(value: active, onChanged: ((_) {}),),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Text('${item_name} ${item_value}'),
                        ),
                      ])));
                });
              });

              _contents.add(DragAndDropList(
                  header: Column(children: <Widget>[
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 4),
                          child: Text('${group_name}',
                            style: TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  children: children
              ));
            });
          });

        });
  }

  void refresh() {
    setState(() {
      this.setContents();
    });
  }

  @override
  void initState() {
    print('initState');
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
    });
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = _contents.removeAt(oldListIndex);
      _contents.insert(newListIndex, movedList);
    });
  }
}