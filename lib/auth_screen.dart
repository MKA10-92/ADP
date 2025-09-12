// student-teacher ui: for login and account creat screen

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  String role = "student"; // default role
  String email = "";
  String password = "";
  String fullName = "";
  String country = "";
  String age = "";
  String availableHours = "";
  String certificateUrl = ""; // later for tutor upload

  void _submitForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    try {
      UserCredential userCredential;
      if (isLogin) {
        // LOGIN
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // REGISTER
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save extra data in Firestore
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .set({
              "role": role,
              "fullName": fullName,
              "country": country,
              "age": age,
              "availableHours": role == "tutor" ? availableHours : null,
              "certificateUrl": role == "tutor" ? certificateUrl : null,
              "email": email,
            });
      }
      Navigator.of(context).pushReplacementNamed("/home");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "HifzConnect",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30),
              Text(
                isLogin ? "LOGIN" : "CREATE ACCOUNT",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Theme(
                data: ThemeData(
                  primarySwatch: Colors.blue,
                  primaryColor: Colors.blue,
                  colorScheme: ColorScheme.fromSwatch(
                    primarySwatch: Colors.blue,
                  ).copyWith(secondary: Colors.blue),
                  inputDecorationTheme: InputDecorationTheme(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                  ),
                ),
                child: Card(
                  margin: EdgeInsets.all(20),
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Role Selector
                          if (!isLogin)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Student",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Radio(
                                  activeColor: Colors.blue,
                                  value: "student",
                                  groupValue: role,
                                  onChanged: (value) {
                                    setState(() {
                                      role = value.toString();
                                    });
                                  },
                                ),
                                Text(
                                  "Tutor",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Radio(
                                  activeColor: Colors.blue,
                                  value: "tutor",
                                  groupValue: role,
                                  onChanged: (value) {
                                    setState(() {
                                      role = value.toString();
                                    });
                                  },
                                ),
                              ],
                            ),

                          // Email
                          TextFormField(
                            key: ValueKey("email"),
                            decoration: InputDecoration(labelText: "Email"),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value!.isEmpty ? "Enter email" : null,
                            onSaved: (value) => email = value!,
                          ),

                          // Password
                          SizedBox(height: 10),
                          TextFormField(
                            key: ValueKey("password"),
                            decoration: InputDecoration(labelText: "Password"),
                            obscureText: true,
                            validator: (value) =>
                                value!.length < 6 ? "Password too short" : null,
                            onSaved: (value) => password = value!,
                          ),

                          if (!isLogin) ...[
                            SizedBox(height: 10),
                            TextFormField(
                              key: ValueKey("fullName"),
                              decoration: InputDecoration(
                                labelText: "Full Name",
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? "Enter full name" : null,
                              onSaved: (value) => fullName = value!,
                            ),

                            SizedBox(height: 10),
                            TextFormField(
                              key: ValueKey("country"),
                              decoration: InputDecoration(labelText: "Country"),
                              validator: (value) =>
                                  value!.isEmpty ? "Enter country" : null,
                              onSaved: (value) => country = value!,
                            ),

                            SizedBox(height: 10),
                            TextFormField(
                              key: ValueKey("age"),
                              decoration: InputDecoration(labelText: "Age"),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value!.isEmpty ? "Enter age" : null,
                              onSaved: (value) => age = value!,
                            ),

                            if (role == "tutor") ...[
                              SizedBox(height: 10),
                              TextFormField(
                                key: ValueKey("hours"),
                                decoration: InputDecoration(
                                  labelText: "Available Hours",
                                ),
                                validator: (value) => value!.isEmpty
                                    ? "Enter available hours"
                                    : null,
                                onSaved: (value) => availableHours = value!,
                              ),
                            ],
                          ],

                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor:
                                  Colors.white, // <-- button text color
                            ),
                            onPressed: _submitForm,
                            child: Text(
                              isLogin ? "Login" : "Register",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isLogin = !isLogin;
                              });
                            },
                            child: Text(
                              isLogin
                                  ? "Create new account"
                                  : "Login to my account",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
