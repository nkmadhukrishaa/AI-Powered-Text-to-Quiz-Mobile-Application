import 'dart:convert';
import 'dart:ui';
import 'package:dashboard/quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';
import 'history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  String userMail;

  DashboardScreen({
    required this.userMail,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? inputText;
  bool isLoading = false;
  String id = '';

  Future<void> saveInputtext(String text) async {
    setState(() {
      inputText = text;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final promptdata = {
          'prompt': inputText,
        };

        print("Saving prompt-text for UID: ${user.uid}");

        DocumentReference docRef = await FirebaseFirestore.instance
            .collection(user.uid)
            .add(promptdata);

        print("Prompt saved to Firestore! Doc ID: ${docRef.id}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Prompt saved to Firestore")),
        );

        setState(() {
          id = docRef.id;
        });
      } else {
        print("User not logged in.");
      }
    } catch (e) {
      print("Firestore save failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving result: $e")),
      );
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Logged out successfully")));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AuthPage()));
    } catch (e) {
      print("Logout Error: $e");
    }
  }

  Future<void> generateQuiz() async {
    if (inputText == null || inputText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No text input provided to generate a quiz.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("Gemini API key not found in environment variables");
      }

      final geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        ],
      );

      final prompt = """
      Generate a quiz with 5, 10, 15 or 20 questions (according to the length of the text) about the following text in the exact JSON format specified below.
      Each question must have exactly 4 options and one correct answer.
      
      Required JSON format:
      {
        "questions": ["Question 1", "Question 2"],
        "options": [
          ["Option 1", "Option 2", "Option 3", "Option 4"],
          ["Option 1", "Option 2", "Option 3", "Option 4"]
        ],
        "correctAnswers": ["Correct answer 1", "Correct answer 2"]
      }

      Rules:
      1. Questions should test comprehension of the text
      2. Options should be plausible but only one correct
      3. Correct answers must be exact matches to one of the options
      4. Return ONLY the JSON, no additional text or markdown

      Text to generate quiz from:
      $inputText
      """;

      final response = await geminiModel.generateContent(
        [Content.text(prompt)],
      );

      final rawText = response.text;

      if (rawText == null || rawText.isEmpty) {
        throw Exception("No response from Gemini API");
      }

      String jsonText =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      if (jsonText.startsWith('json')) {
        jsonText = jsonText.substring(4).trim();
      }

      final quizData = jsonDecode(jsonText) as Map<String, dynamic>;
      final questions =
          (quizData['questions'] as List).map((e) => e.toString()).toList();

      final options = (quizData['options'] as List).map((optionList) {
        return (optionList as List).map((opt) => opt.toString()).toList();
      }).toList();

      final correctAnswers = (quizData['correctAnswers'] as List)
          .map((e) => e.toString())
          .toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            questions: questions,
            options: options,
            correctAnswers: correctAnswers,
            userdocId: id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating quiz: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double containerWidth = MediaQuery.of(context).size.width > 600
        ? MediaQuery.of(context).size.width * 0.35
        : MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("",
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.userMail, style: GoogleFonts.lato()),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.indigoAccent),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigoAccent, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.black),
              title: Text("History", style: GoogleFonts.lato(fontSize: 16)),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => HistoryPage())),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.black),
              title: Text("Logout", style: GoogleFonts.lato(fontSize: 16)),
              onTap: () {
                logout();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          "DASHBOARD",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
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
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: containerWidth,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 60,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(height: 30),
                      Text(
                        "Input Text:",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Enter your text here",
                          hintStyle: GoogleFonts.lato(
                              color: Colors.white.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                        ),
                        style: GoogleFonts.lato(color: Colors.white),
                        onChanged: (value) {
                          saveInputtext(value);
                        },
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : generateQuiz,
                          icon: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Icon(Icons.quiz),
                          label: isLoading
                              ? Text("Generating...")
                              : Text("Generate Quiz"),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.white,
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
    );
  }
}

class QuizResultsScreen extends StatelessWidget {
  final Map<String, dynamic> quizData;

  const QuizResultsScreen({Key? key, required this.quizData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Generated Quiz"),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: (quizData['questions'] as List).length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question ${index + 1}: ${quizData['questions'][index]}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ...List.generate(
                    (quizData['options'][index] as List).length,
                    (optionIndex) => RadioListTile(
                      title: Text(quizData['options'][index][optionIndex]),
                      value: quizData['options'][index][optionIndex],
                      groupValue: quizData['correctAnswers'][index],
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Correct answer: ${quizData['correctAnswers'][index]}",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
