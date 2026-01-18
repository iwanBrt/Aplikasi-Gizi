import 'package:flutter/material.dart';
// Import logic AuthService yang sudah kita buat sebelumnya
import '../../data/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller input
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variabel untuk mengecek status loading
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // AppBar transparan
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: colorScheme.surfaceContainerHighest, // Background abu terang
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 1. LOGO KECIL ---
                Image.asset(
                  'assets/images/logo_nusantara.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 80),
                ),
                const SizedBox(height: 16),
                
                // Judul
                Text("Buat Akun Baru", style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  "Mulai perjalanan sehatmu hari ini.",
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // --- 2. FORM DALAM CARD ---
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
                          // Input Nama
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Nama Lengkap",
                              prefixIcon: Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

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
                                borderRadius: BorderRadius.all(Radius.circular(12)),
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
                              helperText: "Minimal 6 karakter",
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6
                                    ? 'Password terlalu pendek'
                                    : null,
                          ),
                          const SizedBox(height: 24),

                          // --- TOMBOL DAFTAR (DENGAN LOGIC) ---
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null // Matikan tombol jika sedang loading
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      // 1. Mulai Loading
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      // 2. Panggil Logic AuthService
                                      final authService = AuthService();
                                      final error = await authService.register(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        nama: _nameController.text,
                                      );

                                      // Cek apakah widget masih aktif sebelum update UI (Wajib di Flutter)
                                      if (!mounted) return;

                                      // 3. Stop Loading
                                      setState(() {
                                        _isLoading = false;
                                      });

                                      // 4. Cek Hasil
                                      if (error == null) {
                                        // SUKSES
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Registrasi Berhasil! Silakan Login.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        // Kembali ke Halaman Login
                                        Navigator.pop(context);
                                      } else {
                                        // GAGAL
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                            // Jika Loading, tampilkan putaran. Jika tidak, tampilkan teks.
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
                                    "DAFTAR SEKARANG",
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}