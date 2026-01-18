import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Instance Supabase (Alat komunikasi)
  final SupabaseClient _supabase = Supabase.instance.client;

  // LOGIKA REGISTER
  Future<String?> register({required String email, required String password, required String nama}) async {
    try {
      // 1. Kirim data ke Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': nama}, // Kita simpan nama di metadata user
      );

      // 2. Cek apakah ada user yang tercipta
      if (response.user == null) {
        return 'Gagal mendaftar: Respon kosong';
      }
      
      return null; // Null artinya SUKSES (tidak ada error)
      
    } on AuthException catch (e) {
      return e.message; // Kembalikan pesan error dari Supabase (misal: Email sudah dipakai)
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // LOGIKA LOGIN
  Future<String?> login({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return 'Login gagal';
      }

      return null; // Sukses
    } on AuthException catch (e) {
      return e.message; // Misal: Password salah
    } catch (e) {
      return 'Terjadi kesalahan sistem';
    }
  }

  // LOGIKA LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
  
  // CEK APAKAH USER SEDANG LOGIN (Untuk Auto-Login)
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}