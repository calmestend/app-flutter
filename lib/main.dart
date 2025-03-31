import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:io' show Platform;
import 'screens/register_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/main_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización del WebView
  late final PlatformWebViewControllerCreationParams params;
  
  try {
    if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams();
    } else {
      // Para otras plataformas (Linux, Windows, macOS), usar parámetros por defecto
      params = const PlatformWebViewControllerCreationParams();
    }

    // Inicializar el WebView con los parámetros
    WebViewController.fromPlatformCreationParams(params);
  } catch (e) {
    // Si hay algún error en la inicialización del WebView, lo manejamos silenciosamente
    print('WebView initialization warning: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserState()..loadUser()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Flutter',
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/login': (context) =>
            const LoginScreen(), // Asegúrate de que el nombre coincida con tu archivo
      },
      home: Consumer<UserState>(
        builder: (context, userState, _) {
          return userState.userId != null
              ? const MainScreen()
              : const HomeScreen();
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Create an Account'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

