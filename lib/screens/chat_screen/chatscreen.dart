import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker/emoji_lists.dart';
import 'package:emoji_picker/emoji_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:new_chat/constant/strings.dart';
import 'package:new_chat/enum/view_state.dart';
import 'package:new_chat/models/massage.dart';
import 'package:new_chat/models/user.dart';
import 'package:new_chat/provider/image_upload_provider.dart';
import 'package:new_chat/resources/auth_methods.dart';
import 'package:new_chat/screens/arcore_screen.dart';
import 'package:new_chat/screens/chat_screen/filter_screen.dart';
import 'package:new_chat/screens/chat_screen/widget/cached_image.dart';
import 'package:new_chat/screens/full_Image.dart';
import 'package:new_chat/utils/call_ultilities.dart';
import 'package:new_chat/utils/permissions.dart';
import 'package:new_chat/utils/ultilities.dart';
import 'package:new_chat/utils/universal_variables.dart';
import 'package:new_chat/widgets/appbar.dart';
import 'package:new_chat/widgets/custom_tile.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:new_chat/resources/chat_methods.dart';
import 'package:new_chat/resources/storage_methods.dart';


class ChatScreen extends StatefulWidget {
  final User receiver;

  ChatScreen({this.receiver});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController textFieldController = TextEditingController();
  final StorageMethods _storageMethods = StorageMethods();
  final ChatMethods _chatMethods = ChatMethods();
  final AuthMethods _authMethods = AuthMethods();
  var vitriTinNhan = 0;

  //Trình đk scroll
  ScrollController _listScrollController = ScrollController();
  

  //Khởi tạo lớp providerimage
  ImageUploadProvider _imageUploadProvider;

  User sender;

  String _currentUserId;

  FocusNode textFieldFocus = FocusNode();

  bool isWriting = false;
  bool showEmojiPicker = false;
  

  @override
  void initState() {  
    super.initState();
    
    
    _authMethods.getCurrentUser().then((user) {
      _currentUserId = user.uid;

      setState(() {
        sender = User(
          uid: user.uid,
          name: user.displayName,
          profilePhoto: user.photoUrl,
        );
      });
    });
  }

  showKeyboard() => textFieldFocus.requestFocus();

  hideKeyboard() => textFieldFocus.unfocus();

  hideEmojiContainer() {
    setState(() {
      showEmojiPicker = false;
    });
  }

  showEmojiContainer() {
    setState(() {
      showEmojiPicker = true;
    });
  }

  @override
  Widget build(BuildContext context) {

    _imageUploadProvider = Provider.of<ImageUploadProvider>(context);

    return Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      appBar: customAppBar(context),
      body: Column(
        children: <Widget>[
         
          Flexible(
            child: messageList(),
          ),
          _imageUploadProvider.getViewState == ViewState.LOADING 
          ? Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(right: 15),
            child: CircularProgressIndicator()
          )
          : Container(),
          chatControls(),
          showEmojiPicker ? Container(child: emojiContainer()): Container(),
        ],
      ),
    );
  }

   emojiContainer() {
    return EmojiPicker(
      bgColor: UniversalVariables.separatorColor,
      indicatorColor: UniversalVariables.blueColor,
      rows: 3,
      columns: 7,
      onEmojiSelected: (emoji, category) {
        setState(() {
          isWriting = true;
        });

        textFieldController.text = textFieldController.text + emoji.emoji;
      },
      recommendKeywords: ["face", "happy", "party", "sad"],
      numRecommended: 50,
    );
  }

  Widget messageList() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection(MESSAGES_COLLECTION)
          .document(_currentUserId)
          .collection(widget.receiver.uid)
          .orderBy(TIMESTAMP_FIELD, descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.data == null) {
          return Center(child: CircularProgressIndicator());
        }
        
      // Cuộn về cuối danh sách khi reload 
      //(Ví dụ người dùng nhập tin nhắn nó sẽ auto cuộn về vị trí cuối list)
      //Nhưng cũng gây một số bất tiện vs một số người dùng - tạm thời cm
      //  SchedulerBinding.instance.addPostFrameCallback((_) {
      //     _listScrollController.animateTo(
      //       _listScrollController.position.minScrollExtent,
      //       duration: Duration(milliseconds: 250),
      //       curve: Curves.easeInOut,
      //     );
      //   });

        return ListView.builder(
          padding: EdgeInsets.all(10),
          reverse: true,
          controller: _listScrollController,
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
            vitriTinNhan = index;
            return chatMessageItem(snapshot.data.documents[index]);
            
          },
        );
      },
    );
  }
 

   Widget chatMessageItem(DocumentSnapshot snapshot) {
    Message _message = Message.fromMap(snapshot.data);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Container(
        alignment: _message.senderId == _currentUserId
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: _message.senderId == _currentUserId
            ? senderLayout(_message)
            : receiverLayout(_message),
      ),
    );
  }

  Widget senderLayout(Message message) {
    
    Radius messageRadius = Radius.circular(10);

    //Trả về khối tin nhắn sender
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          constraints:
              // Đoạn này giữ cho đoạn tin nhắn không vượt quá giá trị <ở đây là 65% màn hình>
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
          decoration: BoxDecoration(
            color: UniversalVariables.senderColor,
            borderRadius: BorderRadius.only(
              topLeft: messageRadius,
              topRight: messageRadius,
              bottomLeft: messageRadius,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(10),
            child:  getMessage(message),
          ),
        ),
        Container(
          padding: EdgeInsets.all(5),
          
          child:Text(
            partTime(message.timestamp),
              style: TextStyle(color: Colors.white, fontSize: 12)
            // message.timestamp.toDate().month.toString()
          ),
        ),
        
      ],
    );
  }

  //Phương thức này để lấy dữ liệu tin nhắn từ user nhập thông qua DB
  getMessage(Message message) {

    return message.type != MESSAGE_TYPE_IMAGE ?

    Text(
      message != null ? message.message : "",
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.0,
      ),
    ) : message.photoUrl != null 
    ? GestureDetector(
      child: CachedImage(
        message.photoUrl,
        width: 250,
        height: 250,
        radius: 5,
      ),
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>FullImageScreen(photoUrl: message.photoUrl)));
      },
    )
    : Text('No picture');
  }

  // Widget bố cục tin nhắn phía người nhận
  Widget receiverLayout(Message message ) {
    Radius messageRadius = Radius.circular(10);
    bool flag = null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          // onDoubleTap: (){},
          child: Container(
            margin: EdgeInsets.only(top: 12),
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
            decoration: BoxDecoration(
              color: UniversalVariables.receiverColor,
              borderRadius: BorderRadius.only(
                bottomRight: messageRadius,
                topRight: messageRadius,
                bottomLeft: messageRadius,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(10),
              child:  getMessage(message),
            ),
          ),
        ),
        Container(
            padding: EdgeInsets.all(5),
            
            child:Text(
              partTime(message.timestamp),
              style: TextStyle(color: Colors.white, fontSize: 12)
              // message.timestamp.toDate().month.toString()
            ),
          ),

      ],
    );
  }
  pickImage({@required ImageSource source}) async {
      File selectedImage = await Utils.pickImage(source: source);
      _storageMethods.uploadImage(
        image: selectedImage,
        receiverId: widget.receiver.uid,
        senderId: _currentUserId,
        imageUploadProvider: _imageUploadProvider 
      );

    }

  //Widget chatcontrok
  Widget chatControls() {
    setWritingTo(bool val) {
      setState(() {
        isWriting = val;
      });
    }

    //cấu hình contain thêm các Media vào hội thoại
    addMediaModal(context) {
      showModalBottomSheet(
          context: context,
          elevation: 0,
          backgroundColor: UniversalVariables.blackColor,
          builder: (context) {
            return Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: <Widget>[
                      FlatButton(
                        child: Icon(
                          Icons.close,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "PHƯƠNG THỨC GỬI",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    children: <Widget>[
                      ModalTile(
                        title: "Ảnh",
                        subtitle: "Chia sẻ ảnh thư viện",
                        icon: Icons.image,
                        onTap:()=> pickImage(source: ImageSource.gallery) ,
                      ),
                      ModalTile(
                        title: "File",
                        subtitle: "Chọn một file",
                        icon: Icons.tab),
                    ModalTile(
                        title: "Liên Hệ",
                        subtitle: "Gửi danh thiếp bạn bè",
                        icon: Icons.contacts_sharp),
                    ModalTile(
                        title: "Vị trí",
                        subtitle: "Chia sẻ vị trí của bạn",
                        icon: Icons.add_location),
                    ModalTile(
                        title: "Lịch",
                        subtitle: "Sắp xếp một cuộc gọi và nhận lời nhắc",
                        icon: Icons.schedule),
                    ModalTile(
                        title: "Tạo bình chọn",
                        subtitle: "Tạo một cuộc bình chọn",
                        icon: Icons.poll)
                    ],
                  ),
                ),
              ],
            );
          });
    }

    sendMessage() {
      var text = textFieldController.text;

      Message _message = Message(
        receiverId: widget.receiver.uid,
        senderId: sender.uid,
        message: text,
        timestamp: Timestamp.now(),
        type: 'text',
      );

      setState(() {
        isWriting = false;
      });

      textFieldController.text = "";

      _chatMethods.addMessageToDb(_message, sender, widget.receiver);
    }

    //Widget điều khiển thanh chat
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => addMediaModal(context),
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: UniversalVariables.fabGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add),
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: textFieldController,
                  focusNode: textFieldFocus,
                  onTap: () => hideEmojiContainer(),
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  onChanged: (val) {
                    (val.length > 0 && val.trim() != "")
                        ? setWritingTo(true)
                        : setWritingTo(false);
                  },
                  decoration: InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    hintStyle: TextStyle(
                      color: UniversalVariables.greyColor,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(50.0),
                        ),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    filled: true,
                    fillColor: UniversalVariables.separatorColor,
                  ),
                ),
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    if (!showEmojiPicker) {
                      // keyboard is visible
                      hideKeyboard();
                      showEmojiContainer();
                    } else {
                      //keyboard is hidden
                      showKeyboard();
                      hideEmojiContainer();
                    }
                  },
                  icon: Icon(CupertinoIcons.smiley),
                ),
              ],
            ),
          ),
          isWriting
              ? Container()
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    child: Icon(CupertinoIcons.wand_stars,),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>FillterScreen()));
                    } 
                  ),
                ),
          isWriting 
              ? Container()
              : GestureDetector(
                  child: Icon(Icons.camera_alt),
                  onTap: () => pickImage(source: ImageSource.camera),
                ),
          isWriting
              ? Container(
                  margin: EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                      gradient: UniversalVariables.fabGradient,
                      shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      size: 15,
                    ),
                    onPressed: () => sendMessage(),
                  ))
              : Container()
        ],
      ),
    );
  }

  
  
  CustomAppBar customAppBar(context) {
    return CustomAppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      centerTitle: false,
      title: Text(
        widget.receiver.name,
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            CupertinoIcons.ant,
            size: 20,
          ),
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>ArrCoreScreen()));
          }
        ),

        IconButton(
          icon: Icon(
            CupertinoIcons.video_camera,
            size: 30,
          ),
          onPressed: () async => await Permissions.cameraAndMicrophonePermissionsGranted() 
          ? CallUtils.dial(
            from: sender,
            to: widget.receiver,
            context: context
          ):{},
        ),
        
        IconButton(
          icon: Icon(
            CupertinoIcons.phone,
          ),
         onPressed: () async => await Permissions.cameraAndMicrophonePermissionsGranted() 
          ? CallUtils.dialAudio(
            from: sender,
            to: widget.receiver,
            context: context
          ):{},
        )
      ],
    );
  }

  String partTime(Timestamp time){
    var day = time.toDate().day.toString();
    var month=  time.toDate().month.toString();
    var year = time.toDate().year.toString();
    var h = time.toDate().hour.toString();
    var p = time.toDate().minute.toString();
    var s = time.toDate().second.toString();
    // String a = 'Ngày '+ day + '/' + month + '/' + year + ' | '+h+':'+p;
    String a = h+':'+p;
    return a;
  }
}

class ModalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Function onTap;

  const ModalTile({
    @required this.title,
    @required this.subtitle,
    @required this.icon,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: CustomTile(
        mini: false,
        onTap: onTap,
        leading: Container(
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: UniversalVariables.receiverColor,
          ),
          padding: EdgeInsets.all(10),
          child: Icon(
            icon,
            color: UniversalVariables.greyColor,
            size: 38,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: UniversalVariables.greyColor,
            fontSize: 14,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}