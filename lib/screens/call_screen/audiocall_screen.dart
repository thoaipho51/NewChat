import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:new_chat/models/user.dart';
import 'package:new_chat/screens/call_screen/pickup/pickup_screen.dart';
import 'package:provider/provider.dart';
import 'package:new_chat/configs/api_key.dart';
import 'package:new_chat/models/call.dart';
import 'package:new_chat/provider/user_provider.dart';
import 'package:new_chat/resources/call_methods.dart';

class AudioCallScreen extends StatefulWidget {
  final Call call;

  AudioCallScreen({
    @required this.call,
  });

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final CallMethods callMethods = CallMethods();

  UserProvider userProvider;
  StreamSubscription callStreamSubscription;

  // Agora
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool volClick = false;
  int vol = 0;

  // static const maxSeconds = 60;
  int seconds = 0;
  int minute = 0;
  int hour = 0;
  Timer timer;



  void startTimer(){
    timer = Timer.periodic(Duration(seconds: 1), (_) { 
      setState(() {
        seconds++;
        if(seconds >= 60){
          seconds = 0;
          minute += 1;
          if(minute >= 60){
            hour += 1;
            minute = 0;
          }
        }

      }); 
    });
  }


  void _startCall(){
    final isRunning = timer == null? false : timer.isActive;

    isRunning ? false :  startTimer();
  }

  void _stopCall(){
    timer.cancel();
  }


  @override
  void initState() {
    super.initState();
    addPostFrameCallback();
    initializeAgora(); // --
  }


  
  // --begin Agora code
  Future<void> initializeAgora() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'Lỗi APP_ID, Ứng dụng sẽ sớm được cập nhật xin lỗi vì sự bất tiện này',
        );
        _infoStrings.add('Agora Engine không khởi động');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await AgoraRtcEngine.enableWebSdkInteroperability(true);
    await AgoraRtcEngine.setParameters(
        '''{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}''');
    await AgoraRtcEngine.joinChannel(null, widget.call.channelId, null, 0);
    
  }

  addPostFrameCallback() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      userProvider = Provider.of<UserProvider>(context, listen: false);

      callStreamSubscription = callMethods
          .callStream(uid: userProvider.getUser.uid)
          .listen((DocumentSnapshot ds) {
        // định nghĩa logic
        switch (ds.data) {
          case null:
            // snapshot là null có nghĩa là cuộc gọi kết thúc và các dữ liệu trong db sẽ bị xóa
            Navigator.pop(context);
            break;

          default:
            break;
        }
      });
    });
  }

  /// trả về list user call
  List<Widget> _checkUserList() {
    final List<AgoraRenderWidget> list = [
      AgoraRenderWidget(0, local: true, preview: true),
    ];
    _users.forEach((int uid) => list.add(AgoraRenderWidget(uid)));
    list.length >= 2 ? _startCall(): false ; //Xử lý kết thúc gọi
    return list;
  }


  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    await AgoraRtcEngine.create(APP_ID);
    // await AgoraRtcEngine.enableVideo();
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onError = (dynamic code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onJoinChannelSuccess = (
      String channel,
      int uid,
      int elapsed,
    ) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
      setState(() {
        final info = 'onUserJoined: $uid';
        _infoStrings.add(info);
        _users.add(uid);
      });
    };

    AgoraRtcEngine.onUpdatedUserInfo = (AgoraUserInfo userInfo, int i) {
      setState(() {
        final info = 'onUpdatedUserInfo: ${userInfo.toString()}';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onRejoinChannelSuccess = (String string, int a, int b) {
      setState(() {
        final info = 'onRejoinChannelSuccess: $string';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onUserOffline = (int a, int b) {
      callMethods.endCall(call: widget.call);
      setState(() {
        final info = 'onUserOffline: a: ${a.toString()}, b: ${b.toString()}';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onRegisteredLocalUser = (String s, int i) {
      setState(() {
        final info = 'onRegisteredLocalUser: string: s, i: ${i.toString()}';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onLeaveChannel = () {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _users.clear();
      });
    };

    AgoraRtcEngine.onConnectionLost = () {
      setState(() {
        final info = 'onConnectionLost';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
      // if call was picked
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        _users.remove(uid);
      });
    };
    
    AgoraRtcEngine.onFirstRemoteVideoFrame = (
      int uid,
      int width,
      int height,
      int elapsed,
    ) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    };
  }

  

  /// Màn hình đơn
  Widget _videoView(view) {
    return Expanded(
      child: Container(
        child: PickupScreen()
      )
    );
  }

  /// Bảng ghi nhật ký cuộc gọi
  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return null;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    AgoraRtcEngine.muteLocalAudioStream(muted);
  }
  void _onToggleMuteVol() {
    setState(() {
      volClick = !volClick;
      volClick ? vol = 100 : vol = 50;
    });
    // AgoraRtcEngine.disableAudio();
    AgoraRtcEngine.adjustPlaybackSignalVolume(vol);
  }

  // 
  Widget _audioScreen(){
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        Image.network(
          "https://dotobjyajpegd.cloudfront.net/photo/5d3a66f962710e25dc99ffa3",
          fit: BoxFit.cover,
        ),        // Black Layer
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jemmy \nWilliams",
                  style: Theme.of(context)
                      .textTheme
                      .headline3
                      .copyWith(color: Colors.white),
                ),
                SizedBox(height: 10,),
                Text(
                  _checkUserList().length >= 2 
                  ? "Đang gọi:" + '$hour'+':'+'$minute'+':'+'$seconds'.toUpperCase() : 'Đang chờ...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RawMaterialButton(
                      onPressed: _onToggleMute,
                      child: Icon(
                        muted ? CupertinoIcons.mic_off : CupertinoIcons.mic,
                        color: muted ? Colors.red: Colors.white,
                        size: 30.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2.0,
                      fillColor:  Colors.black26,
                      padding: const EdgeInsets.all(12.0),
                    ),
                    RawMaterialButton(
                      onPressed: () => callMethods.endCall(
                        call: widget.call,
                      ),
                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 40.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2.0,
                      fillColor: Colors.redAccent,
                      padding: const EdgeInsets.all(15.0),
                    ),
                    RawMaterialButton(
                      onPressed: _onToggleMuteVol,
                      child: Icon(
                        volClick ? CupertinoIcons.volume_off : CupertinoIcons.volume_down,
                        color: volClick ? Colors.red: Colors.white,
                        size: 30.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2.0,
                      fillColor:  Colors.black26,
                      padding: const EdgeInsets.all(12.0),
                    ),
                    
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    AgoraRtcEngine.leaveChannel();
    AgoraRtcEngine.destroy();
    callStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _audioScreen(),
          ],
        ),
      ),
    );
  }
}


// Widget _toolbar() {
//     return Container(
//       alignment: Alignment.bottomCenter,
//       padding: const EdgeInsets.symmetric(vertical: 48),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           RawMaterialButton(
//             onPressed: _onToggleMute,
//             child: Icon(
//               muted ? CupertinoIcons.mic_off : CupertinoIcons.mic,
//               color: muted ? Colors.red: Colors.white,
//               size: 30.0,
//             ),
//             shape: CircleBorder(),
//             elevation: 2.0,
//             fillColor:  Colors.black26,
//             padding: const EdgeInsets.all(12.0),
//           ),
//           RawMaterialButton(
//             onPressed: () => callMethods.endCall(
//               call: widget.call,
//             ),
//             child: Icon(
//               Icons.call_end,
//               color: Colors.white,
//               size: 40.0,
//             ),
//             shape: CircleBorder(),
//             elevation: 2.0,
//             fillColor: Colors.redAccent,
//             padding: const EdgeInsets.all(15.0),
//           ),
//         ],
//       ),
//     );
//   }