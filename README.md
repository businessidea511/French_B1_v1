# French B1 Learning App 🇫🇷

A comprehensive Flutter web application for learning French at the B1 level, featuring grammar lessons, interactive exercises, flashcards, and verb conjugation practice with AI-powered features via DeepSeek API.

## ✨ Features

### 📚 Grammar Lessons
9 comprehensive topics with simple "for dummies" style explanations:
- **Passé Composé** - Completed past actions
- **Imparfait** - Ongoing past actions and descriptions
- **Plus-que-parfait** - Past perfect tense
- **Conditionnel** - Conditional mood (would/could/should)
- **Complex Negation** - Never, nothing, nobody, no more
- **Futur Proche** - Near future (going to)
- **Futur Simple** - Simple future (will)
- **COD/COI** - Direct and indirect object pronouns
- **Si seulement** - "If only" phrases

### ✍️ Exercises
- Interactive quizzes for each grammar topic
- Multiple choice questions with explanations
- Score tracking and instant feedback
- Progress monitoring

### 🎴 Flashcards
- Animated flip cards for memorization
- Topic-based card decks
- Shuffle functionality
- Spaced repetition practice

### 🔄 Verb Conjugation
- Conjugation tables for all major tenses
- Common French verbs (être, avoir, aller, faire, parler, finir)
- Easy verb and tense selection
- Clear formatting for learning

### Robust Exercise Randomization & Uniqueness

Ensure that exercises are pedagogical, unique, and randomized to prevent predictable patterns.

## Proposed Changes

### [DeepSeek Service](file:///c:/Users/ahmad/Desktop/B1%20French%20Flutter/french_course_b1/lib/services/deepseek_service.dart)
- Update the `generateExercises` prompt to explicitly demand 4 **unique** options.
- Add a requirement for the AI to vary the correct answer index (redundant but helpful for variety).
- Increase the temperature slightly to encourage diverse distractors.

### [Exercises Page](file:///c:/Users/ahmad/Desktop/B1%20French%20Flutter/french_course_b1/lib/pages/exercises/exercises_page.dart)
- Implement a `_shuffleAndSanitize` method in `_ExercisesPageState`.
- This method will:
    - **Shuffle** the options array for each question.
    - **Recalculate** the `correct` index to point to the new location.
    - **Filter** out duplicate options by generating new ones or asking the student to "skip" (though unique prompt should fix this).
- Call this method in `_startAIExercises` before setting the state.

## Verification Plan
- Run 5 exercise generations.
- Confirm the correct answer is at a different index (0, 1, 2, or 3) for each question.
- Visually inspect options to ensure no duplicates.

### 🤖 AI Integration
- DeepSeek API for dynamic exercise generation
- AI-powered grammar explanations
- Intelligent answer checking and feedback

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.6.0 or higher)
- DeepSeek API key ([Get one here](https://platform.deepseek.com/))

### Installation

1. **Clone the repository**
```bash
cd "C:\Users\ahmad\Desktop\B1 French Flutter\french_course_b1"
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up environment variables**

Create a `.env` file in the project root:
```env
DEEPSEEK_API_KEY=your_actual_api_key_here
```

**⚠️ IMPORTANT:** Replace `your_actual_api_key_here` with your real DeepSeek API key!

4. **Run the app locally**
```bash
flutter run -d chrome
```

## 📦 Building for Production

### Build for Web
```bash
flutter build web --release
```

The build output will be in `build/web/`

## 🌐 Deploy to Vercel

### Method 1: Vercel CLI
```bash
npm install -g vercel
vercel
```

### Method 2: GitHub Integration
1. Push your code to GitHub
2. Go to [vercel.com](https://vercel.com)
3. Import your repository
4. Add environment variable: `DEEPSEEK_API_KEY`
5. Deploy!

### Method 3: Vercel Dashboard
1. Go to vercel.com and sign in
2. Click "Add New Project"
3. Import your Git repository
4. Vercel will auto-detect the `vercel.json` config
5. Add your `DEEPSEEK_API_KEY` in Environment Variables
6. Click "Deploy"

**Environment Variable Setup in Vercel:**
- Go to Project Settings > Environment Variables
- Add: `DEEPSEEK_API_KEY` = your_api_key_here
- Save and redeploy

## 🎨 Design Features
- Modern dark theme with vibrant gradients
- Smooth animations and transitions
- Responsive layout for all screen sizes
- Premium aesthetic with glassmorphism effects
- Color-coded topics for easy navigation

## 📱 Tech Stack
- **Framework:** Flutter Web
- **Language:** Dart
- **State Management:** Provider
- **API:** DeepSeek AI
- **Storage:** SharedPreferences
- **Animations:** Flutter Animations package
- **Deployment:** Vercel

## 🗂️ Project Structure
```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # App-wide theme configuration
├── models/
│   └── grammar_topic.dart   # Grammar topic data model
├── services/
│   └── deepseek_service.dart # DeepSeek API integration
├── pages/
│   ├── home_page.dart       # Main navigation page
│   ├── grammar/
│   │   ├── grammar_page.dart
│   │   └── lessons/          # Individual grammar lessons
│   ├── exercises/
│   │   └── exercises_page.dart
│   ├── flashcards/
│   │   └── flashcards_page.dart
│   └── verbs/
│       └── verbs_page.dart
└── widgets/
    └── lesson_template.dart  # Reusable lesson components
```

## 📝 Adding More Content

### Adding Exercises
Edit `lib/pages/exercises/exercises_page.dart` and add to `exercisesByTopic`:
```dart
'topic_id': [
  {
    'question': 'Your question?',
    'options': ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
    'correct': 0,  // Index of correct answer
    'explanation': 'Why this is correct',
  },
],
```

### Adding Flashcards
Edit `lib/pages/flashcards/flashcards_page.dart` and add to `flashcardsByTopic`:
```dart
'topic_id': [
  {'front': 'Question', 'back': 'Answer'},
],
```

### Adding Verbs
Edit `lib/pages/verbs/verbs_page.dart` and add to `conjugations` map.

## 🔑 API Key Security
- **Never** commit your `.env` file
- **Always** use environment variables
- **Gitignore** already excludes `.env` files
- For production, set environment variables in Vercel dashboard

## 🐛 Troubleshooting

### "API Key must be set" error
- Check that `.env` file exists in project root
- Verify `DEEPSEEK_API_KEY` is set correctly
- In Vercel, check Environment Variables in project settings

### Flutter build fails
```bash
flutter clean
flutter pub get
flutter doctor
```

### Vercel deployment fails
- Check `vercel.json` is in project root
- Ensure Git repository is properly connected
- Verify build command in Vercel settings

## 📄 License
This project is for educational purposes.

## 🤝 Contributing
Feel free to add more:
- Grammar topics
- Exercises and quizzes
- Flashcard content
- Verb conjugations
- UI improvements

## 📧 Support
For issues or questions, check the DeepSeek API documentation at [platform.deepseek.com](https://platform.deepseek.com/)

---

**Happy Learning! 🎉 Bonne chance! 🇫🇷**
