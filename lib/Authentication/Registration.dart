import 'package:brainu/Authentication/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  bool _obscurePassword = true;
  String? selectedLanguage;

  bool _isPasswordValid(String password) {
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$])[A-Za-z\d@$]{8,15}$';
    return RegExp(pattern).hasMatch(password);
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
                image: AssetImage("assets/img/Register_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  

                  /// Title
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/img/Spoonerism_btn.png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  /// Fields
                  buildInputField(nameController, "Enter Name", Icons.person),
                  SizedBox(height: 15),
                  buildInputField(emailController, "Enter Email", Icons.email),
                  SizedBox(height: 15),
                  buildPasswordField(),
                  SizedBox(height: 15),
                  buildInputField(ageController, "Enter Age", Icons.cake,
                      isNumber: true),
                  SizedBox(height: 15),

                  /// Language dropdown
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 30),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.brown, width: 2),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      hint: Text("Select Language",
                          style: TextStyle(color: Colors.brown[600])),
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.brown[800]),
                      decoration: InputDecoration(border: InputBorder.none),
                      items: ["English", "Hindi"]
                          .map((lang) => DropdownMenuItem<String>(
                                value: lang,
                                child: Text(lang),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 20),

                  /// Register button
                  buildGameButton(
                    text: "Register",
                    bgImage: "assets/img/brown_btn.png",
                    onTap: () async {
                      if (!_isPasswordValid(passwordController.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Password must be 8–15 chars, include upper/lowercase, number & symbol')),
                        );
                        return;
                      }

                      if (selectedLanguage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please select a language.")),
                        );
                        return;
                      }

                      int? age = int.tryParse(ageController.text.trim());
                      if (age == null || age <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a valid age.')),
                        );
                        return;
                      }

                      try {
                        final userCredential = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        final uid = userCredential.user?.uid;
                        if (uid == null) throw Exception('User UID is null');

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .set({
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'age': age,
                          'language': selectedLanguage,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration Successful!')),
                        );
                        await Future.delayed(Duration(seconds: 2));

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      } on FirebaseAuthException catch (e) {
                        String errorMessage;
                        switch (e.code) {
                          case 'email-already-in-use':
                            errorMessage = 'This email is already registered.';
                            break;
                          case 'invalid-email':
                            errorMessage = 'Invalid email address.';
                            break;
                          case 'weak-password':
                            errorMessage = 'Password is too weak.';
                            break;
                          default:
                            errorMessage =
                                'Registration failed: ${e.message ?? "Unknown error."}';
                        }
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(errorMessage)));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('An unexpected error occurred. Try again.')),
                        );
                      }
                    },
                  ),

                  SizedBox(height: 10),

                  /// Back to Login button (small wooden)
                  buildGameButton(
                    text: "Back to Login",
                    bgImage: "assets/img/Wooden_btn.png",
                    fontSize: 16,
                    margin:
                        EdgeInsets.symmetric(horizontal: 100, vertical: 8),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
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
  Widget buildInputField(TextEditingController controller, String hint,
      IconData icon,
      {bool isNumber = false}) {
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
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.brown[600]),
          prefixIcon: Icon(icon, color: Colors.brown[800]),
        ),
      ),
    );
  }

  /// Styled Password Field
  Widget buildPasswordField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.brown, width: 2),
      ),
      child: TextField(
        controller: passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Enter Password",
          hintStyle: TextStyle(color: Colors.brown[600]),
          prefixIcon: Icon(Icons.lock, color: Colors.brown[800]),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.brown[800],
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  /// Reusable Game Button
  Widget buildGameButton({
    required String text,
    required String bgImage,
    required VoidCallback onTap,
    double fontSize = 20,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 12),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 2,
                offset: Offset(1, 1),
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );  
  }
}
