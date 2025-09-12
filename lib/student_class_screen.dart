// student ui: containing list of all classroooms they are added in.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'class_details_screen.dart';

class StudentClassScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Classes",
          style: TextStyle(
            fontSize: 28,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("classes")
              .where("students", arrayContains: currentUser.uid)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());

            final classes = snapshot.data!.docs;
            if (classes.isEmpty)
              return Center(
                child: Text(
                  "You are not enrolled in any class yet.",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              );

            return ListView(
              padding: EdgeInsets.all(16),
              children: classes.map((doc) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    title: Text(
                      doc["title"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      doc["description"] ?? "",
                      style: TextStyle(color: Colors.black54),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassDetailsScreen(
                            classId: doc.id,
                            classTitle: doc["title"],
                            tutorId: doc["tutorId"],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
