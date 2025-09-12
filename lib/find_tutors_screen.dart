// student ui: for viewing available tutors for applying, teachers they have applied to, teachers they have been accepted by. with option to cancel request and leave.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FindTutorsScreen extends StatefulWidget {
  @override
  _FindTutorsScreenState createState() => _FindTutorsScreenState();
}

class _FindTutorsScreenState extends State<FindTutorsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _pendingExpanded = false;
  bool _acceptedExpanded = false;

  void applyToTutor(
    String tutorId,
    String tutorName,
    BuildContext context,
  ) async {
    final studentId = currentUser.uid;
    final studentDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(studentId)
        .get();

    await FirebaseFirestore.instance
        .collection("tutorApplications")
        .doc(tutorId)
        .collection("requests")
        .doc(studentId)
        .set({
          "studentId": studentId,
          "studentName": studentDoc['fullName'],
          "status": "pending",
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Applied to $tutorName")));
  }

  void cancelRequest(String tutorId, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("tutorApplications")
        .doc(tutorId)
        .collection("requests")
        .doc(currentUser.uid)
        .delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Request cancelled")));
  }

  void leaveTutor(String tutorId, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("tutorApplications")
        .doc(tutorId)
        .collection("requests")
        .doc(currentUser.uid)
        .update({"status": "removed"});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Left tutor")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Tutors",
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
              .collection("users")
              .where("role", isEqualTo: "tutor")
              .snapshots(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());

            final tutors = snapshot.data!.docs;
            if (tutors.isEmpty)
              return Center(
                child: Text(
                  "No tutors found",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  // Requested Tutors
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Theme(
                      data: ThemeData(
                        dividerColor: Colors.transparent,
                        textTheme: TextTheme(
                          titleMedium: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          "Requested Tutors",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: _pendingExpanded,
                        onExpansionChanged: (exp) =>
                            setState(() => _pendingExpanded = exp),
                        children: tutors.map((tutor) {
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("tutorApplications")
                                .doc(tutor.id)
                                .collection("requests")
                                .doc(currentUser.uid)
                                .snapshots(),
                            builder: (ctx2, reqSnap) {
                              if (!reqSnap.hasData) return SizedBox.shrink();

                              final status = reqSnap.data!.exists
                                  ? (reqSnap.data!['status'] == 'pending'
                                        ? 'pending'
                                        : (reqSnap.data!['status'] == 'accepted'
                                              ? 'accepted'
                                              : 'none'))
                                  : 'none';
                              if (status != "pending") return SizedBox.shrink();

                              return ListTile(
                                title: Text(
                                  tutor['fullName'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  "${tutor['country']} • Hours: ${tutor['availableHours']} • Age: ${tutor['age'] ?? 'N/A'}",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text("Cancel"),
                                  onPressed: () =>
                                      cancelRequest(tutor.id, context),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Divider(),

                  // My Tutors
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Theme(
                      data: ThemeData(
                        dividerColor: Colors.transparent,
                        textTheme: TextTheme(
                          titleMedium: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          "My Tutors",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: _acceptedExpanded,
                        onExpansionChanged: (exp) =>
                            setState(() => _acceptedExpanded = exp),
                        children: tutors.map((tutor) {
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("tutorApplications")
                                .doc(tutor.id)
                                .collection("requests")
                                .doc(currentUser.uid)
                                .snapshots(),
                            builder: (ctx2, reqSnap) {
                              if (!reqSnap.hasData) return SizedBox.shrink();

                              final status = reqSnap.data!.exists
                                  ? (reqSnap.data!['status'] == 'pending'
                                        ? 'pending'
                                        : (reqSnap.data!['status'] == 'accepted'
                                              ? 'accepted'
                                              : 'none'))
                                  : 'none';
                              if (status != "accepted")
                                return SizedBox.shrink();

                              return ListTile(
                                title: Text(
                                  tutor['fullName'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  "${tutor['country']} • Hours: ${tutor['availableHours']} • Age: ${tutor['age'] ?? 'N/A'}",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text("Leave"),
                                  onPressed: () =>
                                      leaveTutor(tutor.id, context),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Divider(),

                  // Available Tutors
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Available Tutors",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                  ...tutors.map((tutor) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("tutorApplications")
                          .doc(tutor.id)
                          .collection("requests")
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (ctx2, reqSnap) {
                        final status = reqSnap.hasData && reqSnap.data!.exists
                            ? (reqSnap.data!['status'] == 'pending'
                                  ? 'pending'
                                  : (reqSnap.data!['status'] == 'accepted'
                                        ? 'accepted'
                                        : 'none'))
                            : 'none';
                        if (status != "none") return SizedBox.shrink();

                        return Card(
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            title: Text(
                              tutor['fullName'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              "${tutor['country']} • Hours: ${tutor['availableHours']} • Age: ${tutor['age'] ?? 'N/A'}",
                              style: TextStyle(color: Colors.black54),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text("Apply"),
                              onPressed: () => applyToTutor(
                                tutor.id,
                                tutor['fullName'],
                                context,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
