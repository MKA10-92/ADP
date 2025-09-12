// teacher ui: for managing their created classs (adding students from theri accepted student list, removing students from class, make and delete annpuncements)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageClassScreen extends StatefulWidget {
  final String classId;
  final String classTitle;

  const ManageClassScreen({
    required this.classId,
    required this.classTitle,
    Key? key,
  }) : super(key: key);

  @override
  _ManageClassScreenState createState() => _ManageClassScreenState();
}

class _ManageClassScreenState extends State<ManageClassScreen> {
  final _announcementController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;

  bool _addStudentsExpanded = false;
  bool _acceptedStudentsExpanded = false;

  void _addStudent(String studentId) async {
    final classRef = FirebaseFirestore.instance
        .collection("classes")
        .doc(widget.classId);

    await classRef.update({
      "students": FieldValue.arrayUnion([studentId]),
    });
  }

  void _removeStudent(String studentId) async {
    final classRef = FirebaseFirestore.instance
        .collection("classes")
        .doc(widget.classId);

    await classRef.update({
      "students": FieldValue.arrayRemove([studentId]),
    });
  }

  void _addAnnouncement() async {
    if (_announcementController.text.isEmpty) return;

    final announcement = {
      "text": _announcementController.text,
      "createdAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("classes")
        .doc(widget.classId)
        .collection("announcements")
        .add(announcement);

    _announcementController.clear();
  }

  void _deleteAnnouncement(String announcementId) async {
    await FirebaseFirestore.instance
        .collection("classes")
        .doc(widget.classId)
        .collection("announcements")
        .doc(announcementId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final classRef = FirebaseFirestore.instance
        .collection("classes")
        .doc(widget.classId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.classTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Students Section (white card)
                Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      "Add Students",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    initiallyExpanded: _addStudentsExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _addStudentsExpanded = expanded;
                      });
                    },
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .where("role", isEqualTo: "student")
                            .snapshots(),
                        builder: (ctx, snapshot) {
                          if (!snapshot.hasData)
                            return Center(child: CircularProgressIndicator());

                          final allStudents = snapshot.data!.docs;

                          return Column(
                            children: allStudents.map<Widget>((doc) {
                              final studentId = doc.id;

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection("tutorApplications")
                                    .doc(currentUser.uid)
                                    .collection("requests")
                                    .doc(studentId)
                                    .get(),
                                builder: (ctx2, tutorSnap) {
                                  if (!tutorSnap.hasData)
                                    return SizedBox.shrink();

                                  final accepted =
                                      tutorSnap.data!.exists &&
                                      tutorSnap.data!["status"] == "accepted";

                                  if (!accepted) return SizedBox.shrink();

                                  return StreamBuilder<DocumentSnapshot>(
                                    stream: classRef.snapshots(),
                                    builder: (ctx3, classSnap) {
                                      if (!classSnap.hasData)
                                        return SizedBox.shrink();

                                      final classStudents = List.from(
                                        classSnap.data!.get("students") ?? [],
                                      );

                                      if (classStudents.contains(studentId))
                                        return SizedBox.shrink();

                                      return ListTile(
                                        title: Text(
                                          doc["fullName"] ?? studentId,
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () =>
                                              _addStudent(studentId),
                                        ),
                                      );
                                    },
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
                Divider(height: 30),

                // Accepted Students Section (white card)
                Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      "Added Students",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    initiallyExpanded: _acceptedStudentsExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _acceptedStudentsExpanded = expanded;
                      });
                    },
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: classRef.snapshots(),
                        builder: (ctx, snapshot) {
                          if (!snapshot.hasData)
                            return Center(child: CircularProgressIndicator());

                          final students = List.from(
                            snapshot.data!.get("students") ?? [],
                          );
                          if (students.isEmpty) return Text("No students yet");

                          return Column(
                            children: students.map<Widget>((studentId) {
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection("tutorApplications")
                                    .doc(currentUser.uid)
                                    .collection("requests")
                                    .doc(studentId)
                                    .get(),
                                builder: (ctx2, tutorSnap) {
                                  if (!tutorSnap.hasData)
                                    return SizedBox.shrink();

                                  final stillAccepted =
                                      tutorSnap.data!.exists &&
                                      tutorSnap.data!["status"] == "accepted";

                                  if (!stillAccepted) {
                                    _removeStudent(studentId);
                                    return SizedBox.shrink();
                                  }

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(studentId)
                                        .get(),
                                    builder: (ctx3, studentSnap) {
                                      if (!studentSnap.hasData)
                                        return SizedBox.shrink();

                                      final studentData = studentSnap.data!;
                                      return ListTile(
                                        title: Text(
                                          studentData.get("fullName") ??
                                              studentId,
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.remove_circle),
                                          onPressed: () =>
                                              _removeStudent(studentId),
                                        ),
                                      );
                                    },
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
                Divider(height: 30),

                // Add Announcement Section (styled)
                Text(
                  "Add Announcement",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _announcementController,
                            decoration: InputDecoration(
                              hintText: "Enter announcement",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Icon(Icons.send),
                          onPressed: _addAnnouncement,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Announcements Section (title outside, each announcement in white card)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Announcements",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.blue[800],
                    ),
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
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "No announcements yet",
                          style: TextStyle(color: Colors.black),
                        ),
                      );

                    return Column(
                      children: announcements.map<Widget>((doc) {
                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              doc["text"],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              doc["createdAt"]?.toDate().toString() ?? "",
                              style: TextStyle(color: Colors.black54),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAnnouncement(doc.id),
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
      ),
    );
  }
}
