import 'package:flutter/material.dart';
import 'package:new_chat/provider/user_provider.dart';
import 'package:new_chat/screens/pagesview/chats/widgets/user_details_container.dart';
import 'package:new_chat/utils/ultilities.dart';
import 'package:new_chat/utils/universal_variables.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class UserCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        backgroundColor: UniversalVariables.blackColor,
        builder: (context) => UserDetailsContainer(),
      ),
      child: Container(
        height: 40,
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: UniversalVariables.separatorColor,
        ),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Shimmer.fromColors(
                baseColor: UniversalVariables.blackColor,
                highlightColor: Colors.lightBlue,
                child: Text(
                  userProvider.getUser.name.isEmpty  
                ? Utils.getInitials(userProvider.getUser.name)
                : 'Hồ sơ người dùng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
                period: Duration(seconds: 1),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: UniversalVariables.blackColor, width: 2),
                  color: UniversalVariables.onlineDotColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}