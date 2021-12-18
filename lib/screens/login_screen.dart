// import 'package:email_password_login/screens/home_screen.dart';
// import 'package:email_password_login/screens/registration_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:new_chat/resources/auth_methods.dart';
import 'package:new_chat/screens/home_screen.dart';
import 'package:new_chat/screens/regisation_screen.dart';
import 'package:new_chat/utils/universal_variables.dart';
import 'package:shimmer/shimmer.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  
  // form key
  final _formKey = GlobalKey<FormState>();

  // editing controller
  final TextEditingController emailController = new TextEditingController();
  final TextEditingController passwordController = new TextEditingController();

  // firebase
  final _auth = FirebaseAuth.instance;
  final AuthMethods _authMethods = AuthMethods();
  bool isLoginPressed = false;
  
  // string for displaying the error Message
  String errorMessage;

  @override
  Widget build(BuildContext context) {
    //email field
    final emailField = TextFormField(
        autofocus: false,
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value.isEmpty) {
            return ("Email không được để trống");
          }
          // reg expression for email validation
          if (!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]")
              .hasMatch(value)) {
            return ("Email không hợp lệ!");
          }
          return null;
        },
        onSaved: (value) {
          emailController.text = value;
        },
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.mail),
          contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Email",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
      );

    //password field
    final passwordField = TextFormField(
        autofocus: false,
        controller: passwordController,
        obscureText: true,
        // ignore: missing_return
        validator: (value) {
          RegExp regex = new RegExp(r'^.{6,}$');
          if (value.isEmpty) {
            return ("Vui lòng nhập password !");
          }
          if (!regex.hasMatch(value)) {
            return ("Mật khẩu phả trên 6 ký tự !");
          }
        },
        onSaved: (value) {
          passwordController.text = value;
        },
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.vpn_key),
          contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Password",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));

    final loginButton = Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(30),
      color: Colors.redAccent,
      child: MaterialButton(
          padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          minWidth: MediaQuery.of(context).size.width,
          onPressed: () {
            signIn(emailController.text, passwordController.text);
          },
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: UniversalVariables.senderColor,
            child: Text(
              "Login",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold
              ),
            )
          )
      ),
    );

    final textOr = Text(
      'Or',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20
      ),
    );

    final loginGoogle = Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(30),
      color: Colors.redAccent,
      child: MaterialButton(
          padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          minWidth: MediaQuery.of(context).size.width,
          onPressed: () => performLogin(),
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: UniversalVariables.senderColor,
            child: Text(
                "Login with Google",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          )
      )
    );
    

    return Scaffold(
      // backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                        height: 200,
                        child: Image.asset(
                          "assets/logo/new_chat_logo.png",
                          fit: BoxFit.contain,
                        )),
                    SizedBox(height: 45),
                    emailField,
                    SizedBox(height: 25),
                    passwordField,
                    SizedBox(height: 35),
                    loginButton,
                    SizedBox(height: 15),
                    textOr,
                    SizedBox(height: 15),
                    loginGoogle,
                    SizedBox(height: 15),

                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Bạn không có tài khoản ? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          RegistrationScreen()));
                            },
                            child: Text(
                              "Đăng Ký",
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          )
                        ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // login function
  void signIn(String email, String password) async {
    if (_formKey.currentState.validate()) {
      try {
        await _auth
            .signInWithEmailAndPassword(email: email, password: password)
            .then((uid) => {
                  Fluttertoast.showToast(msg: "Đăng nhập thành công"),
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen())),
                });
      } on AuthException catch (error) {
        switch (error.code) {
          case "invalid-email":
            errorMessage = "Email không đúng định dạng.";
            break;
          case "wrong-password":
            errorMessage = "Sai mật khẩu";
            break;
          case "user-not-found":
            errorMessage = "Người dùng không tồn tại!";
            break;
          case "user-disabled":
            errorMessage = "Email bị vô hiệu hoá!";
            break;
          case "too-many-requests":
            errorMessage = "Quá nhiều yêu cầu vui lòng đợi...";
            break;
          case "operation-not-allowed":
            errorMessage = "Đăng nhập bằng Email và Mật khẩu không được bật.";
            break;
          default:
            errorMessage = "Lỗi không xác định";
        }
        Fluttertoast.showToast(msg: errorMessage);
        print(error.code + 'adasdsd');
      }
    }
  }
  //loginGoogle Function
  void performLogin() {
    print("tring to perform login");

    setState(() {
      isLoginPressed = true;
    });

    _authMethods.signIn().then((FirebaseUser user) {
      print("something");
      if (user != null) {
        authenticateUser(user);
      } else {
        print("There was an error");
      }
    });
  }

  void authenticateUser(FirebaseUser user) {
    _authMethods.authenticateUser(user).then((isNewUser) {
      setState(() {
        isLoginPressed = false;
      });

      if (isNewUser) {
        _authMethods.addDataToDb(user).then((value) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) {
            return HomeScreen();
          }));
        });
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return HomeScreen();
        }));
      }
    });
  }
}
