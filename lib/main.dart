import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_chat/provider/image_upload_provider.dart';
import 'package:new_chat/provider/user_provider.dart';
import 'package:new_chat/resources/auth_methods.dart';
import 'package:new_chat/screens/home_screen.dart';
import 'package:new_chat/screens/login_screen.dart';
import 'package:new_chat/screens/search_screen.dart';
import 'package:provider/provider.dart';


void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthMethods _authMethods = AuthMethods();

  @override
  Widget build(BuildContext context) {

    //test đăng xuất
    // ko bỏ dồng này sẽ bị đăng xuất vĩnh viễn =))
    // _repository.signOut();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageUploadProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider())
      ],
      child: MaterialApp(
        title: "New_Chat",
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/search_screen': (context) => SearchScreen(),
        },
        theme: ThemeData(
            brightness: Brightness.dark
        ),
        home: FutureBuilder(
          future: _authMethods.getCurrentUser(),
          builder: (context, AsyncSnapshot<FirebaseUser> snapshot) {
            if (snapshot.hasData) {
              return HomeScreen();
            } else {
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
// test