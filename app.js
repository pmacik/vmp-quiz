const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
app.use(express.urlencoded({ extended: true }));

// Middleware to serve images from the /images directory
app.use('/images', express.static(path.join(__dirname, 'images')));
app.use(express.static(path.join(__dirname, 'public')));
app.set('view engine', 'ejs');

let questions = [];
let questionOrder = [];
let currentIndex = 0;
let summary = { correct: 0, successRate: 0.0, incorrect: 0, unanswered: 0 };
let server;

// Load quizzes from the /quizzes directory
const loadQuizFiles = () => {
  return fs.readdirSync('./quizzes')
    .filter(file => file.endsWith('.yaml'))
    .map(file => file.replace('.yaml', ''));
};

// Load questions based on selected filters
const loadQuestions = (quizFile, withImages, textOnly) => {
  const yaml = require('js-yaml');
  const quizData = yaml.load(fs.readFileSync(`./quizzes/${quizFile}.yaml`, 'utf8'));

  // Apply filters for questions with images and text-only questions
  questions = quizData.questions.filter(q => {
    if (withImages && textOnly) return true;
    if (withImages) return q.img != "" || q.answers.some(answer => answer.img != "");
    if (textOnly) return !q.img && q.answers.every(answer => !answer.img);
  });

  questionOrder = Array.from({ length: questions.length }, (_, i) => i);
  shuffleArray(questionOrder);
  summary = { correct: 0, successRate: 0.0, incorrect: 0, unanswered: questions.length };
};

// Shuffle array function (used for questions and answers)
const shuffleArray = (array) => array.sort(() => Math.random() - 0.5);

app.get('/', (req, res) => {
  const quizzes = loadQuizFiles();
  res.render('selectQuiz', { quizzes });
});

app.post('/start', (req, res) => {
  const { quiz, withImages, textOnly } = req.body;
  loadQuestions(quiz, withImages === 'on', textOnly === 'on');
  currentIndex = 0;
  res.redirect('/question');
});

// Route to render each question
app.get('/question', (req, res) => {
  if (currentIndex >= questionOrder.length) {
    return res.redirect('/summary');
  }
  const question = questions[questionOrder[currentIndex]];
  question.answers = shuffleArray(question.answers);

  // Determine the correct answer index for color indication on the client side
  const correctAnswerIndex = question.answers.findIndex(answer => answer.correct === 'true');

  res.render('question', {
    question,
    correctAnswerIndex,
    currentIndex: currentIndex + 1,
    total: questions.length,
    summary
  });
});

// Handle answer submission
app.post('/question', (req, res) => {
  const selectedAnswerIndex = parseInt(req.body.answerIndex, 10);
  const question = questions[questionOrder[currentIndex]];
  const isCorrect = question.answers[selectedAnswerIndex].correct === 'true';

  // Update summary based on whether the answer was correct or not
  if (isCorrect) {
    summary.correct++;
  } else {
    summary.incorrect++;
  }

  summary.successRate = (summary.correct / (summary.correct + summary.incorrect) * 100).toFixed(2);

  summary.unanswered--;
  currentIndex++;
  res.redirect('/question');
});

// Handle restart
app.post('/restart', (req, res) => {
  currentIndex = 0;
  summary = { correct: 0, successRate: 0.0, incorrect: 0, unanswered: questions.length };
  res.redirect('/');
});

app.get('/summary', (req, res) => {
  res.render('summary', { summary });
});

const PORT = 8888;
server = app.listen(PORT, () => {
  console.log(`Quiz app running on http://localhost:${PORT}`);
});


// Graceful shutdown on CTRL+C
process.on("SIGINT", () => {
  console.log("\nShutting down server...");
  server.close(() => {
    console.log("Server closed gracefully.");
    process.exit(0); // Exit with success code
  });
});
