import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/vocab_provider.dart';
import 'providers/settings_provider.dart'; // Import mới
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VocabProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ), // Đăng ký Provider mới
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Vocab App',

            // 1. Cấu hình Theme Sáng
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF2F6FA),
            ),

            // 2. Cấu hình Theme Tối
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212), // Màu nền tối
              cardColor: const Color(0xFF1E1E1E),
            ),

            // 3. Áp dụng chế độ người dùng chọn
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // 4. Áp dụng Cỡ chữ toàn cục (Text Scale)
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQueryData.copyWith(
                  textScaler: TextScaler.linear(settings.textScale),
                ),
                child: child!,
              );
            },

            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
