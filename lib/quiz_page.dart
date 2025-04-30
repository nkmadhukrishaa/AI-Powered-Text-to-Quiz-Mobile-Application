import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  final List<String> questions;
  final List<List<String>> options;
  final List<String> correctAnswers;
  final String userdocId;

  QuizPage({
    required this.questions,
    required this.options,
    required this.correctAnswers,
    required this.userdocId,
  });

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<String?> selectedAnswers;

  @override
  void initState() {
    super.initState();
    _resetQuiz();
  }

  void _resetQuiz() {
    selectedAnswers = List.filled(widget.questions.length, null);
    for (int i = 0; i < widget.options.length; i++) {
      widget.options[i].shuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Quiz',
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
          ListView.builder(
            padding: EdgeInsets.only(
                top: kToolbarHeight + 16, bottom: screenHeight * 0.15),
            itemCount: widget.questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(
                  context, index, screenWidth, screenHeight);
            },
          ),
          _buildSubmitButton(context, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, int index, double screenWidth,
      double screenHeight) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${index + 1}. ${widget.questions[index]}",
              style: GoogleFonts.lato(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Column(
              children: widget.options[index].map((opt) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAnswers[index] = opt;
                    });
                  },
                  child: _buildOption(opt, index, screenWidth, screenHeight),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      String opt, int index, double screenWidth, double screenHeight) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.015,
        horizontal: screenWidth * 0.04,
      ),
      decoration: BoxDecoration(
        color: selectedAnswers[index] == opt
            ? Colors.blueAccent.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              selectedAnswers[index] == opt ? Colors.blue : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          opt,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w500,
            color:
                selectedAnswers[index] == opt ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
      BuildContext context, double screenWidth, double screenHeight) {
    return Positioned(
      bottom: screenHeight * 0.05,
      right: screenWidth * 0.05,
      child: FloatingActionButton.extended(
        onPressed: _submitQuiz,
        backgroundColor: Colors.blueAccent,
        label: Text(
          'Submit Quiz',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white, // Set text color to white
            fontSize: screenWidth * 0.045,
          ),
        ),
        icon: Icon(
          Icons.check,
          color: Colors.white,
          size: screenWidth * 0.06,
        ),
      ),
    );
  }

  void _submitQuiz() {
    int correctCount = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (selectedAnswers[i] == widget.correctAnswers[i]) {
        correctCount++;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          correctAnswers: correctCount,
          totalQuestions: widget.questions.length,
          questions: widget.questions,
          options: widget.options,
          selectedAnswers: selectedAnswers,
          correctAnswerList: widget.correctAnswers,
          userdocID: widget.userdocId,
        ),
      ),
    );
  }
}
