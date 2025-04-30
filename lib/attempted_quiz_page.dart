import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttemptDetailsPage extends StatelessWidget {
  final String docId;

  AttemptDetailsPage({required this.docId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in.")),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  "https://plus.unsplash.com/premium_photo-1701679745692-3715eeefa614?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection(user.uid)
                .doc(docId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("No quiz data found."));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final attempt = data?['attemptedQuizPage'];
              if (attempt == null) {
                return const Center(child: Text("No quiz data found."));
              }

              final questions = List<String>.from(attempt['questions']);
              final optionsMap = attempt['options'] as Map<String, dynamic>;

              final options = questions.map((questionText) {
                final matchingEntry = optionsMap.entries.firstWhere(
                  (entry) =>
                      questions.indexOf(questionText) ==
                      int.parse(entry.key.replaceAll(RegExp(r'[^\d]'), '')) - 1,
                  orElse: () => MapEntry('', []),
                );
                return List<String>.from(matchingEntry.value);
              }).toList();

              final selectedAnswers =
                  List<String?>.from(attempt['selectedAnswers']);
              final correctAnswers =
                  List<String>.from(attempt['correctAnswerList']);

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 70, 12, 12),
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Q${index + 1}: ${questions[index]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...options[index].map((opt) {
                                final isSelected =
                                    opt == selectedAnswers[index];
                                final isCorrect = opt == correctAnswers[index];
                                return Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isCorrect
                                          ? Colors.green
                                          : isSelected
                                              ? Colors.red
                                              : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      opt,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.purple
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              const SizedBox(height: 6),
                              Text(
                                "✅ Correct: ${correctAnswers[index]}",
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "📝 Your Answer: ${selectedAnswers[index] ?? 'N/A'}",
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
