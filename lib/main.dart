import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
// PENTING: Import file env yang menyimpan kunci rahasia
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Inisialisasi Supabase menggunakan variabel dari file env.dart
  // Pastikan kamu sudah membuat file lib/core/constants/env.dart
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Gizi',
      debugShowCheckedModeBanner: false, // Hilangkan pita DEBUG
      // --- PENGATURAN TEMA ---
      theme: ThemeData(
        useMaterial3: true,

        // 1. Skema Warna (Hijau + Aksen Oranye)
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Colors.green, // Warna Utama
              brightness: Brightness.light,
            ).copyWith(
              // Warna Secondary (Oranye) untuk teks Link / Tombol Aksi
              secondary: const Color(0xFFE67E22),
              tertiary: const Color(0xFFE67E22),
            ),

        // 2. Gaya Teks (Tipografi)
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(color: Colors.black54),
        ),

        // 3. Gaya Tombol (ElevatedButton) - WAJIB ADA BIAR CANTIK
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Tombol default hijau
            foregroundColor: Colors.white, // Teks putih
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Sudut membulat
            ),
            elevation: 2, // Sedikit bayangan
          ),
        ),

        // 4. Gaya Input Form (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5), // Latar input abu terang
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // Default tanpa garis
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.green, // Garis hijau saat diklik
              width: 2,
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
        ),
      ),

      // --- HALAMAN UTAMA - dengan Auth Gate untuk persistent login ---
      home: const AuthGate(),
    );
  }
}

// Widget untuk mengecek apakah user sudah login atau belum
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Tunggu sebentar untuk Supabase initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        // User sudah login, redirect ke HomePage
        print('✅ User sudah login: ${session.user.email}');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan LoginPage sebagai default
    return const LoginPage();
  }
}
