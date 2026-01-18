import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/pages/login_page.dart';
// PENTING: Import file env yang menyimpan kunci rahasia
import 'core/constants/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

      // --- HALAMAN UTAMA ---
      home: const LoginPage(),
    );
  }
}
