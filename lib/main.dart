import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load local .env if it exists
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Silently continue; production uses --dart-define
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
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
      ),
      home: const HomePage(),
    );
  }
}
