import 'package:flutter/material.dart';
// Import halaman register untuk navigasi
import 'register_page.dart';
// Import logic AuthService
import '../../data/auth_service.dart';
// IMPORT PENTING: Onboarding Page (Target navigasi saat ini)
import '../../../../features/onboarding/presentation/onboarding_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variabel loading state
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Mengambil tema agar konsisten
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant, // Background abu terang
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 1. LOGO APLIKASI ---
                Image.asset(
                  'assets/images/logo_nusantara.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 120),
                ),
                const SizedBox(height: 24),

                // --- 2. JUDUL ---
                Text("Welcome Back!", style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  "Silakan masuk untuk melanjutkan progres gizimu.",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // --- 3. FORM INPUT DALAM CARD ---
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Input Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? 'Email tidak valid'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Input Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6
                                ? 'Password min. 6 karakter'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // --- TOMBOL LOGIN (DENGAN LOGIC) ---
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null // Matikan tombol saat loading
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      // 1. Mulai Loading
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      // 2. Panggil Logic Login
                                      final authService = AuthService();
                                      final error = await authService.login(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );

                                      if (!mounted) return;

                                      // 3. Stop Loading
                                      setState(() {
                                        _isLoading = false;
                                      });

                                      // 4. Cek Hasil
                                      if (error == null) {
                                        // SUKSES LOGIN
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Login Berhasil!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );

                                        // --- NAVIGASI KE ONBOARDING (TESTING) ---
                                        // Setelah login, kita paksa user isi data fisik dulu
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const OnboardingPage(),
                                          ),
                                        );
                                      } else {
                                        // GAGAL LOGIN
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(error),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "MASUK",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- 4. LINK DAFTAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigasi ke Halaman Register
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Daftar Sekarang",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary, // Warna Oranye
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
