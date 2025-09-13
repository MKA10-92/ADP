// // student ui: containing list of all classroooms they are added in.

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
              children: classes.map((classDoc) {
                final tutorId = classDoc["tutorId"];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(tutorId)
                      .get(),
                  builder: (ctx2, tutorSnap) {
                    String tutorName = "Unknown Tutor";
                    if (tutorSnap.hasData && tutorSnap.data!.exists) {
                      tutorName = tutorSnap.data!["fullName"] ?? tutorName;
                    }

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
                          classDoc["title"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (classDoc["description"] != null)
                              Text(
                                classDoc["description"],
                                style: TextStyle(color: Colors.black54),
                              ),
                            SizedBox(height: 4),
                            Text(
                              "Teacher: $tutorName",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClassDetailsScreen(
                                classId: classDoc.id,
                                classTitle: classDoc["title"],
                                tutorId: tutorId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
