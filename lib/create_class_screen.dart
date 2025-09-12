// teacher ui: for creating new clss + button for page showing list of classes they have created.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_class_screen.dart';

class CreateClassScreen extends StatefulWidget {
  @override
  _CreateClassScreenState createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  String classTitle = "";
  String classDescription = "";
  final currentUser = FirebaseAuth.instance.currentUser!;

  void _createClass() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    _formKey.currentState!.save();

    await FirebaseFirestore.instance.collection("classes").add({
      "title": classTitle,
      "description": classDescription,
      "tutorId": currentUser.uid,
      "students": [],
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Class created successfully!")));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Classroom",
          style: TextStyle(
            fontSize: 30,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Theme(
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
                color: Colors.white,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: "Class Title"),
                          validator: (value) =>
                              value!.isEmpty ? "Enter a class title" : null,
                          onSaved: (value) => classTitle = value!,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: "Class Description",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Enter a description" : null,
                          onSaved: (value) => classDescription = value!,
                        ),
                        SizedBox(height: 20),

                        // Create Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _createClass,
                          child: Text(
                            "Create New Class",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),

                        SizedBox(height: 20),

                        // My Classes Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            "My Classes",
                            style: TextStyle(fontSize: 18),
                          ),
                          onPressed: () async {
                            final classesSnapshot = await FirebaseFirestore
                                .instance
                                .collection("classes")
                                .where(
                                  "tutorId",
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser!.uid,
                                )
                                .get();

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => Scaffold(
                                  appBar: AppBar(
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    centerTitle: true,
                                    title: Text(
                                      "My Classes",
                                      style: TextStyle(
                                        fontSize: 30,
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
                                        colors: [
                                          Colors.lightBlueAccent,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: ListView(
                                      children: classesSnapshot.docs.map((doc) {
                                        return Card(
                                          color: Colors.white,
                                          margin: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              doc["title"],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            subtitle: Text(
                                              doc["description"] ?? "",
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ManageClassScreen(
                                                        classId: doc.id,
                                                        classTitle:
                                                            doc["title"],
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
