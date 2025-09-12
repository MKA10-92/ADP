// student ui: for checking contents of classes they are added in.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classId;
  final String classTitle;
  final String tutorId;

  const ClassDetailsScreen({
    required this.classId,
    required this.classTitle,
    required this.tutorId,
    Key? key,
  }) : super(key: key);

  @override
  _ClassDetailsScreenState createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  bool _studentsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final classRef = FirebaseFirestore.instance
        .collection("classes")
        .doc(widget.classId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.classTitle,
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Info
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.tutorId)
                    .get(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) return SizedBox();
                  final teacherData = snapshot.data!;
                  return Text(
                    "Teacher: ${teacherData["fullName"] ?? "Unknown"}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Students List (Expandable)
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    textTheme: TextTheme(
                      titleMedium: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      "Students",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _studentsExpanded,
                    onExpansionChanged: (expanded) =>
                        setState(() => _studentsExpanded = expanded),
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: classRef.snapshots(),
                        builder: (ctx, snapshot) {
                          if (!snapshot.hasData)
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );

                          final students = List.from(
                            snapshot.data!.get("students") ?? [],
                          );
                          if (students.isEmpty)
                            return ListTile(
                              title: Text(
                                "No students yet",
                                style: TextStyle(color: Colors.black54),
                              ),
                            );

                          return Column(
                            children: students.map<Widget>((studentId) {
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(studentId)
                                    .get(),
                                builder: (ctx2, studentSnap) {
                                  if (!studentSnap.hasData)
                                    return SizedBox.shrink();
                                  final studentData = studentSnap.data!;
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      title: Text(
                                        studentData["fullName"] ?? studentId,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Announcements
              Text(
                "Announcements",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue[900],
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: classRef
                    .collection("announcements")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData)
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );

                  final announcements = snapshot.data!.docs;
                  if (announcements.isEmpty)
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "No announcements yet",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );

                  return Column(
                    children: announcements.map<Widget>((doc) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            doc["text"],
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            doc["createdAt"]?.toDate().toString() ?? "",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
