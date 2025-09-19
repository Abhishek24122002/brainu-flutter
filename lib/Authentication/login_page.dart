import 'package:brainu/Authentication/Registration.dart';
import 'package:brainu/Authentication/forgot_password_page.dart';
import 'package:brainu/screens/LevelSelectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscure = true;
  String _errorMessage = '';

  void storeUserSession(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/img/Letter_bg.png"), // set your forest/bg
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// Cute Brain Character (like your app mascot)
                  Image.asset(
                    "assets/img/Brainu_icon.png",
                    height: 120,
                  ),
                  SizedBox(height: 10),

                  /// Wooden Signboard (Login Title)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/img/Spoonerism_btn.png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  /// Email Input
                  buildInputField(
                    controller: emailController,
                    hint: "Enter Email",
                    icon: Icons.email,
                  ),

                  SizedBox(height: 15),

                  /// Password Input
                  buildInputField(
                    controller: passwordController,
                    hint: "Enter Password",
                    icon: Icons.lock,
                    isPassword: true,
                  ),

                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  SizedBox(height: 15),

                  /// Login Button
                  /// Login Button
                  buildGameButton(
                    text: "Login",
                    bgImage: "assets/img/brown_btn.png", // for login
                    onTap: () async {
                      try {
                        UserCredential userCredential = await FirebaseAuth
                            .instance
                            .signInWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        storeUserSession(userCredential.user!.uid);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LevelSelectionScreen(user: userCredential.user),
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          _errorMessage =
                              'Incorrect credentials. Please try again.';
                        });
                      }
                    },
                  ),

                  SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage()),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  /// Create Account Button
                  /// Create Account Button
                  buildGameButton(
                    text: "Create New Account",
                    bgImage:
                        "assets/img/Wooden_btn.png", // use a different style
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Styled Input Field
  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.brown, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.brown[600]),
          prefixIcon: Icon(icon, color: Colors.brown[800]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  /// Styled Game Button
  /// Styled Game Button with custom background
  Widget buildGameButton({
    required String text,
    required VoidCallback onTap,
    required String bgImage,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage), // different per button
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                  blurRadius: 2, offset: Offset(1, 1), color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
