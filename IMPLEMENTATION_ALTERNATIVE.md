// CONTOH IMPLEMENTASI ALTERNATIF (LEBIH CLEAN)
// Jika ingin menggunakan UserProfileService pattern
// Replace fungsi _fetchUserProfile() di home_page.dart dengan kode ini:

import '../../../../features/home/data/user_profile_service.dart';

class _HomePageState extends State<HomePage> {
  final UserProfileService _profileService = UserProfileService();
  
  // ... variabel lainnya ...
  int _targetCalorie = 2000;
  bool _isLoadingProfile = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId == null) {
        _setError('User tidak ditemukan');
        return;
      }

      // Gunakan UserProfileService
      final targetCalorie = await _profileService.getTargetCalorie(userId);

      if (mounted) {
        setState(() {
          _targetCalorie = targetCalorie;
          _isLoadingProfile = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _setError('Gagal mengambil data profil');
      }
      print('Error fetching profile: $e');
    }
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoadingProfile = false;
      _targetCalorie = 2000; // fallback
    });
  }

  // ... rest of the code ...
}
