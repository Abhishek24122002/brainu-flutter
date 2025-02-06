import 'package:brainu/Authentication/Registration.dart';
import 'package:brainu/Authentication/forgot_password_page.dart';
import 'package:brainu/screens/LevelSelectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 94, 114, 228),
              Color.fromARGB(255, 158, 124, 193)
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(33, 255, 255, 255),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: emailController,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15.0),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(34, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: passwordController,
                            obscureText: _isObscure,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.0),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        UserCredential userCredential = await FirebaseAuth
                            .instance
                            .signInWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        storeUserSession(
                            userCredential.user!.uid); // Store UID

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LevelSelectionScreen(
                                  user: userCredential.user)),
                        );
                      } catch (e) {
                        print('Login Error: $e');
                        setState(() {
                          _errorMessage =
                              'Incorrect credentials. Please try again.';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    ),
                    child: Text('Login'),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20.0),
                Container(
                  padding: EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationPage()),
                      );
                    },
                    child: Text('Create New Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
