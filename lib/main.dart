import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables gracefully
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('.env file loaded successfully');
  } catch (e) {
    debugPrint(
        'Note: Initializing without .env file. AI features will require you to add your DeepSeek API key to a .env file based on .env.example.');
  }

  runApp(const FrenchB1App());
}

class FrenchB1App extends StatelessWidget {
  const FrenchB1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'French B1 Learning',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
