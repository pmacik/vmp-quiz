const express = require("express");
const fs = require("fs");
const yaml = require("js-yaml");
const path = require("path");

const app = express();
const PORT = 8888;

let questions = [];
let questionOrder = [];
let currentIndex = 0;
let summary = { correct: 0, incorrect: 0, unanswered: 0 };
let server;
let quizFile = "questions.yaml"; // Default quiz file

const quizzesDir = path.join(__dirname, "quizzes"); // Directory for quiz files

function listQuizFiles() {
  return fs
    .readdirSync(quizzesDir)
    .filter((file) => file.endsWith(".yaml"))
    .map((file) => file.replace(".yaml", "")); // Remove file extension
}

function loadQuestions(quizFileName) {
  try {
    const filePath = path.join(quizzesDir, `${quizFileName}.yaml`);
    const fileContents = fs.readFileSync(filePath, "utf8");
    const data = yaml.load(fileContents);
    questions = data.questions;
    resetQuiz();
  } catch (e) {
    console.error(`Failed to load quiz file ${quizFileName}.yaml`, e);
  }
}

function resetQuiz() {
  questionOrder = [...Array(questions.length).keys()].sort(
    () => Math.random() - 0.5
  );
  currentIndex = 0;
  summary = { correct: 0, incorrect: 0, unanswered: questions.length };
}

function shuffleArray(array) {
  return array.sort(() => Math.random() - 0.5);
}

app.set("view engine", "ejs");
app.use(express.static(path.join(__dirname, "public")));
app.use(express.urlencoded({ extended: true }));
app.use('/images', express.static(path.join(__dirname, 'images')));


app.get("/", (req, res) => {
  const quizzes = listQuizFiles();
  res.render("index", { quizzes });
});

app.post("/start", (req, res) => {
  quizFile = req.body.quiz;
  loadQuestions(quizFile);
  res.redirect("/question");
});

app.get('/question', (req, res) => {
  if (currentIndex >= questionOrder.length) {
    return res.redirect('/summary');
  }
  const question = questions[questionOrder[currentIndex]];
  question.answers = shuffleArray(question.answers);  // Shuffle answers

  // Determine the correct answer index to send to the client
  const correctAnswerIndex = question.answers.findIndex(answer => answer.correct === 'true');

  res.render('question', {
    question,
    correctAnswerIndex,
    currentIndex: currentIndex + 1,
    total: questions.length,
    summary
  });
});

app.post("/question", (req, res) => {
  const { answerIndex } = req.body;
  const question = questions[questionOrder[currentIndex]];
  const isCorrect = question.answers[answerIndex].correct === "true";

  if (isCorrect) {
    summary.correct++;
  } else {
    summary.incorrect++;
  }
  summary.unanswered--;
  currentIndex++;
  res.redirect("/question");
});

app.get("/summary", (req, res) => {
  res.render("summary", { summary });
});

app.post("/restart", (req, res) => {
  resetQuiz(); // Reset the quiz state
  loadQuestions(quizFile); // Reload the questions from the current quiz file
  res.redirect("/question");
});

server = app.listen(PORT, () => {
  console.log(`App running on http://localhost:${PORT}`);
});

// Graceful shutdown on CTRL+C
process.on("SIGINT", () => {
  console.log("\nShutting down server...");
  server.close(() => {
    console.log("Server closed gracefully.");
    process.exit(0); // Exit with success code
  });
});
