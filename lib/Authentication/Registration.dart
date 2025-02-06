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
  bool _passwordValidated = true;
  String? selectedLanguage; // Store selected language

  bool _isPasswordValid(String password) {
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$])[A-Za-z\d@$]{8,15}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 94, 114, 228),
                    Color.fromARGB(255, 158, 124, 193),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 150),
                      // Name field
                      buildInputField(nameController, "Name"),
                      SizedBox(height: 20),
                      // Email field
                      buildInputField(emailController, "Email"),
                      SizedBox(height: 20),
                      // Password field
                      buildPasswordField(),
                      SizedBox(height: 20),
                      // Age field
                      buildInputField(ageController, "Age", isNumber: true),
                      SizedBox(height: 20),
                      // Language dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Align(
                              alignment: Alignment
                                  .centerLeft, // Aligns dropdown to the left
                              child: SizedBox(
                                width: 200, // Adjust width as needed
                                child: Container(
                                  decoration: BoxDecoration(
                                    // color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: DropdownButtonFormField<String>(
                                      value: selectedLanguage,
                                      hint: Text(
                                        "Select Language",
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                      dropdownColor: Colors.blueAccent,
                                      style: TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                      ),
                                      items: [
                                        "English",
                                        "Hindi",
                                        "Urdu",
                                        "Persian",
                                        "Marathi"
                                      ]
                                          .map((lang) =>
                                              DropdownMenuItem<String>(
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
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_isPasswordValid(passwordController.text)) {
                            setState(() {
                              _passwordValidated = false;
                            });
                            return;
                          }

                          if (selectedLanguage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Please select a language.")),
                            );
                            return;
                          }

                          try {
                            int? age = int.tryParse(ageController.text.trim());
                            if (age == null || age <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Please enter a valid age.')),
                              );
                              return;
                            }

                            UserCredential userCredential = await FirebaseAuth
                                .instance
                                .createUserWithEmailAndPassword(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                            );

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCredential.user!.uid)
                                .set({
                              'name': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              'age': age,
                              'language': selectedLanguage,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Registration Successful!')),
                            );
                          } catch (e) {
                            print('Registration Error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Registration failed. Please try again later.')),
                            );
                          }
                        },
                        child: Text('Register'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputField(TextEditingController controller, String hint,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.white54),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
