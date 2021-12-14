import 'package:flutter/material.dart';
import 'package:new_chat/utils/universal_variables.dart';
import 'package:shimmer/shimmer.dart';
import 'package:new_chat/utils/universal_variables.dart';

class ShimmeringLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      child: Shimmer.fromColors(
        baseColor: UniversalVariables.blackColor,
        highlightColor: Colors.white,
        child: Image.network("https://pid.com.vn/wp-content/uploads/2019/07/Logo-LS.png"),
        period: Duration(seconds: 1),
      ),
    );
  }
}