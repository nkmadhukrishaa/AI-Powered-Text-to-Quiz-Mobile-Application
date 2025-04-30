import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard_page.dart';

class ResultPage extends StatefulWidget {
  final int correctAnswers;
  final int totalQuestions;
  final List<String> questions;
  final List<List<String>> options;
  final List<String?> selectedAnswers;
  final List<String> correctAnswerList;
  final String userdocID;

  ResultPage({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.questions,
    required this.options,
    required this.selectedAnswers,
    required this.correctAnswerList,
    required this.userdocID,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Set<int> revealedAnswers = {};

  Future<void> saveQuizResult({
    required int correctAnswers,
    required int totalQuestions,
    required List<String> questions,
    required List<List<String>> options,
    required List<String?> selectedAnswers,
    required List<String> correctAnswerList,
    required String docId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final resultData = {
      'text': 'You scored $correctAnswers/$totalQuestions',
      'attemptedQuizPage': {
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'questions': questions,
        'options': options
            .asMap()
            .map((index, optList) => MapEntry('Q${index + 1}', optList)),
        'selectedAnswers': selectedAnswers,
        'correctAnswerList': correctAnswerList,
      },
      'timestamp': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection(uid)
          .doc(docId)
          .set(resultData, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Results saved!')),
      );
    } catch (e) {
      print("Firestore save failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save results')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scorePercentage =
    (widget.correctAnswers / widget.totalQuestions).clamp(0.0, 1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Your Score',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  "https://plus.unsplash.com/premium_photo-1701679745692-3715eeefa614?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: screenWidth * 0.25,
                  lineWidth: screenWidth * 0.05,
                  animation: true,
                  percent: scorePercentage,
                  center: Text(
                    "${(scorePercentage * 100).toInt()}%",
                    style: GoogleFonts.montserrat(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: Colors.blueAccent,
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
                SizedBox(height: screenHeight * 0.03),
                Container(
                  height: screenHeight * 0.4,
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(widget.questions.length, (index) {
                        final isCorrect = widget.selectedAnswers[index] ==
                            widget.correctAnswerList[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.005),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCorrect ? "✅" : "❌",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Expanded(
                                    child: Text(
                                      "Q${index + 1}. ${widget.questions[index]}",
                                      style: GoogleFonts.lato(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                "Your Answer: ${widget.selectedAnswers[index] ?? "No Answer"}",
                                style: GoogleFonts.lato(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                              if (!isCorrect)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      revealedAnswers.add(index);
                                    });
                                  },
                                  child: Text(
                                    revealedAnswers.contains(index)
                                        ? "Correct Answer: ${widget.correctAnswerList[index]}"
                                        : "Click to Reveal Answer",
                                    style: GoogleFonts.lato(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.w500,
                                      color: revealedAnswers.contains(index)
                                          ? Colors.green
                                          : Colors.blueAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        saveQuizResult(
                          correctAnswers: widget.correctAnswers,
                          totalQuestions: widget.totalQuestions,
                          questions: widget.questions,
                          options: widget.options,
                          selectedAnswers: widget.selectedAnswers,
                          correctAnswerList: widget.correctAnswerList,
                          docId: widget.userdocID,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Results saved successfully!')),
                        );
                      },
                      child: Text("Save Results"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DashboardScreen(userMail: "example@mail.com")), // Pass userMail accordingly
                        );
                      },
                      child: Text("⬅️ Dashboard"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}