import 'package:flutter/material.dart';
import 'package:new_chat/constant/strings.dart';
import 'package:new_chat/models/log.dart';
import 'package:new_chat/resources/local_db/repository/log_repository.dart';
import 'package:new_chat/screens/chat_screen/widget/cached_image.dart';
import 'package:new_chat/screens/pagesview/chats/widgets/quiex_box.dart';
import 'package:new_chat/utils/ultilities.dart';
import 'package:new_chat/widgets/custom_tile.dart';

class LogListContainer extends StatefulWidget {
  @override
  _LogListContainerState createState() => _LogListContainerState();
}

class _LogListContainerState extends State<LogListContainer> {
  getIcon(String callStatus) {
    Icon _icon;
    double _iconSize = 15;

    switch (callStatus) {
      case CALL_STATUS_DIALLED:
        _icon = Icon(
          Icons.call_made,
          size: _iconSize,
          color: Colors.green,
        );
        break;

      case CALL_STATUS_MISSED:
        _icon = Icon(
          Icons.call_missed,
          color: Colors.red,
          size: _iconSize,
        );
        break;

      default:
        _icon = Icon(
          Icons.call_received,
          size: _iconSize,
          color: Colors.grey,
        );
        break;
    }

    return Container(
      margin: EdgeInsets.only(right: 5),
      child: _icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: LogRepository.getLogs(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          List<dynamic> logList = snapshot.data;

          if (logList.isNotEmpty) {
            return ListView.builder(
              itemCount: logList.length,
              itemBuilder: (context, i) {
                Log _log = logList[i];
                bool hasDialled = _log.callStatus == CALL_STATUS_DIALLED;

                return CustomTile(
                  leading: CachedImage(
                    hasDialled ? _log.receiverPic : _log.callerPic,
                    isRound: true,
                    radius: 45,
                    height: 50,
                    width: 50,
                  ),
                  mini: false,
                  onLongPress: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Align(
                        alignment: Alignment.topCenter,
                        child: Text("Nhắc nhở !!")
                        ),
                      titleTextStyle: TextStyle(fontSize: 30, color: Colors.red[400],), 
                      content:
                          Text("Bạn muốn xoá nhật ký này ?"),
                          contentTextStyle: TextStyle(fontSize: 20),
                      actions: [
                        FlatButton(
                          child: Text("Xoá"),
                          textColor: Colors.red,
                          onPressed: () async {
                            Navigator.maybePop(context);
                            await LogRepository.deleteLogs(i);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                        FlatButton(
                          child: Text("Trở Lại"),
                          textColor: Colors.green,
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    hasDialled ? _log.receiverName : _log.callerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  icon: getIcon(_log.callStatus),
                  subtitle: Text(
                    Utils.formatDateString(_log.timestamp),
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                );
              },
            );
          }
          return QuietBox(
            heading: "Nhật Ký Hiện Đang Trống",
            subtitle: "Tìm kiếm bạn và gọi cho họ ngay nào!",
          );
        }

        return QuietBox(
          heading: "Nhật Ký Hiện Đang Trống",
          subtitle: "Tìm kiếm bạn và gọi cho họ ngay nào!",
        );
      },
    );
  }
}