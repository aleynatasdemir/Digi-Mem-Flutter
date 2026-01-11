import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/memory_service.dart';
import 'services/spotify_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(prefs),
        ),
        ChangeNotifierProxyProvider<AuthService, MemoryService>(
          create: (context) => MemoryService(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, auth, previous) =>
              previous ?? MemoryService(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, SpotifyService>(
          create: (context) => SpotifyService(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, auth, previous) =>
              previous ?? SpotifyService(auth),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'Digi-Mem',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            home: authService.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
