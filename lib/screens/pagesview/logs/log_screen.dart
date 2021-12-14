import 'package:flutter/material.dart';
import 'package:new_chat/screens/call_screen/pickup/pickup_layout.dart';
import 'package:new_chat/screens/pagesview/logs/widgets/floating_column.dart';
import 'package:new_chat/utils/universal_variables.dart';
import 'package:new_chat/widgets/skype_appbar.dart';


class LogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      scaffold: Scaffold(
        backgroundColor: UniversalVariables.blackColor,
        appBar: SkypeAppBar(
          title: "Nhật Ký cuộc gọi",
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pushNamed(context, "/search_screen"),
            ),
          ],
        ),
        floatingActionButton: FloatingColumn(),
        body: Padding(
          padding: EdgeInsets.only(left: 15),
          // child: LogListContainer(),
        ),
      ),
    );
  }
}