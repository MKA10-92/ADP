// teacher ui: for vewing list of student applications, acecpted students

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewStudentsScreen extends StatefulWidget {
  @override
  _ViewStudentsScreenState createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _appsExpanded = false;
  bool _acceptedExpanded = false;

  void updateStatus(
    String studentId,
    String status,
    BuildContext context,
  ) async {
    await FirebaseFirestore.instance
        .collection("tutorApplications")
        .doc(currentUser.uid)
        .collection("requests")
        .doc(studentId)
        .update({"status": status});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Student $status")));
  }

  void removeAcceptedStudent(String studentId, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("tutorApplications")
        .doc(currentUser.uid)
        .collection("requests")
        .doc(studentId)
        .update({"status": "removed"});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Student removed")));
  }

  @override
  Widget build(BuildContext context) {
    final requestsRef = FirebaseFirestore.instance
        .collection("tutorApplications")
        .doc(currentUser.uid)
        .collection("requests");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Students",
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
        child: StreamBuilder<QuerySnapshot>(
          stream: requestsRef.snapshots(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());

            final allRequests = snapshot.data!.docs;

            final pending = allRequests
                .where((r) => r['status'] == "pending")
                .toList();
            final accepted = allRequests
                .where((r) => r['status'] == "accepted")
                .toList();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Theme(
                      data: ThemeData(
                        primarySwatch: Colors.blue,
                        primaryColor: Colors.blue,
                        colorScheme: ColorScheme.fromSwatch(
                          primarySwatch: Colors.blue,
                        ).copyWith(secondary: Colors.blue),
                      ),
                      child: Card(
                        color: Colors.white,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: ExpansionTile(
                          title: Text(
                            "Applications",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                          initiallyExpanded: _appsExpanded,
                          onExpansionChanged: (exp) =>
                              setState(() => _appsExpanded = exp),
                          children: pending.isEmpty
                              ? [
                                  ListTile(
                                    title: Text("No pending applications"),
                                  ),
                                ]
                              : pending.map((student) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(student['studentId'])
                                        .get(),
                                    builder: (ctx, userSnap) {
                                      if (!userSnap.hasData)
                                        return SizedBox.shrink();

                                      final studentData =
                                          userSnap.data!.data()
                                              as Map<String, dynamic>;

                                      final age = studentData['age'] ?? 'N/A';
                                      final country =
                                          studentData['country'] ?? 'N/A';

                                      return ListTile(
                                        title: Text(
                                          student['studentName'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Age: $age, Country: $country",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                              onPressed: () => updateStatus(
                                                student.id,
                                                "accepted",
                                                context,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => updateStatus(
                                                student.id,
                                                "rejected",
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                        ),
                      ),
                    ),
                    Divider(),

                    Theme(
                      data: ThemeData(
                        primarySwatch: Colors.blue,
                        primaryColor: Colors.blue,
                        colorScheme: ColorScheme.fromSwatch(
                          primarySwatch: Colors.blue,
                        ).copyWith(secondary: Colors.blue),
                      ),
                      child: Card(
                        color: Colors.white,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: ExpansionTile(
                          title: Text(
                            "My Students",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                          initiallyExpanded: _acceptedExpanded,
                          onExpansionChanged: (exp) =>
                              setState(() => _acceptedExpanded = exp),
                          children: accepted.isEmpty
                              ? [ListTile(title: Text("No accepted students"))]
                              : accepted.map((student) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(student['studentId'])
                                        .get(),
                                    builder: (ctx, userSnap) {
                                      if (!userSnap.hasData)
                                        return SizedBox.shrink();

                                      final studentData =
                                          userSnap.data!.data()
                                              as Map<String, dynamic>;
                                      final age = studentData['age'] ?? 'N/A';
                                      final country =
                                          studentData['country'] ?? 'N/A';

                                      return ListTile(
                                        title: Text(
                                          student['studentName'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Age: $age, Country: $country",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              removeAcceptedStudent(
                                                student.id,
                                                context,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
