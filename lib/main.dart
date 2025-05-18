import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/user/data/repositories/user_repository_impl.dart';
import 'features/user/presentation/providers/user_provider.dart';
import 'features/user/presentation/screens/user_list_screen.dart';

/// Entry point of the application
/// Initializes Flutter bindings and sets up the app with device preview and state management
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // Wrap the app with DevicePreview for responsive design testing
    DevicePreview(
      enabled: false,
      builder:
          (context) => MultiProvider(
            providers: [
              Provider(create: (_) => UserRepositoryImpl()),
              ChangeNotifierProxyProvider<UserRepositoryImpl, UserProvider>(
                create:
                    (context) =>
                        UserProvider(context.read<UserRepositoryImpl>()),
                update:
                    (context, repository, previous) =>
                        previous ?? UserProvider(repository),
              ),
            ],
            child: const MyApp(),
          ),
    ),
  );
}

/// Root widget of the application
/// Defines the app's theme and initial route
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User Fetcher',
      // Define the app's theme with Material 3 design
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
        ),
      ),
      // Set the initial screen to UserListScreen
      home: const UserListScreen(),
    );
  }
}
