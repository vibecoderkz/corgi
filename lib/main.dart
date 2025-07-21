import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';
import 'main_navigation.dart';
import 'screens/course_details_screen.dart';
import 'screens/module_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await AuthService.initialize();
    runApp(const MyApp());
  } catch (e) {
    print('Initialization error: $e');
    // Run app with error screen or basic fallback
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corgi AI Edu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ru', 'RU'),
      ],
      locale: const Locale('ru', 'RU'),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/main': (context) => const MainNavigation(),
        '/courses': (context) => const MainNavigation(initialIndex: 1),
        '/community': (context) => const MainNavigation(initialIndex: 3),
      },
    );
  }
}

