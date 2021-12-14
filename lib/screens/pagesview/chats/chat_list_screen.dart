import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_chat/models/contact.dart';
import 'package:new_chat/provider/user_provider.dart';
import 'package:new_chat/resources/chat_methods.dart';
import 'package:new_chat/screens/call_screen/pickup/pickup_layout.dart';
import 'package:new_chat/screens/pagesview/chats/widgets/contact_view.dart';
import 'package:new_chat/screens/pagesview/chats/widgets/user_circle.dart';
import 'package:new_chat/utils/universal_variables.dart';
import 'package:new_chat/widgets/quiet_box.dart';
import 'package:new_chat/widgets/skype_appbar.dart';
import 'package:provider/provider.dart';

import 'widgets/new_chat_button.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      scaffold: Scaffold(
        backgroundColor: UniversalVariables.blackColor,
        appBar: SkypeAppBar(
          title: UserCircle(),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, "/search_screen");
              },
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ],
        ),
        floatingActionButton: NewChatButton(),
        body: ChatListContainer(),
      ),
    );
  }
}

class ChatListContainer extends StatelessWidget {
  final ChatMethods _chatMethods = ChatMethods();

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);

    return Container(
      child: StreamBuilder<QuerySnapshot>(
          stream: _chatMethods.fetchContacts(
            userId: userProvider.getUser.uid,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var docList = snapshot.data.documents;

              // if (docList.isEmpty) {
              //   return QuietBox(
              //     heading: "This is where all the contacts are listed",
              //     subtitle:
              //         "Search for your friends and family to start calling or chatting with them",
              //   );
              // }
              return ListView.builder(
                padding: EdgeInsets.all(10),
                itemCount: docList.length,
                itemBuilder: (context, index) {
                  Contact contact = Contact.fromMap(docList[index].data);

                  return ContactView(contact);
                },
              );
            }

            return Center(child: CircularProgressIndicator());
          }),
    );
  }
}