import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../widgets/calorie_ring_card.dart';
import '../widgets/macro_nutrient_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _userName =
      Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
      'Teman';

  // Dummy data air minum
  int _glassCount = 3;
  int _selectedNavIndex = 0;

  // Data profil dari Supabase
  int _targetCalorie = 2000; // Default value
  bool _isLoadingProfile = true;
  String? _errorMessage;

  // Data kalori hari ini
  int _calorieToday = 0;
  late StreamSubscription _foodLogsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _setupFoodLogsListener();
  }

  @override
  void dispose() {
    _foodLogsSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        setState(() {
          _errorMessage = 'User tidak ditemukan';
          _isLoadingProfile = false;
        });
        return;
      }

      // Fetch semua data profil untuk kalkulasi TDEE
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('age, weight, height, gender, activity_level')
          .eq('id', userId)
          .single();

      // Hitung target kalori berdasarkan data user
      final calculatedCalorie = _calculateTargetCalorie(
        age: response['age'] ?? 25,
        weight: (response['weight'] ?? 70).toDouble(),
        height: (response['height'] ?? 170).toDouble(),
        gender: response['gender'] ?? 'Laki-laki',
        activityLevel: response['activity_level'] ?? '1.375',
      );

      if (mounted) {
        setState(() {
          _targetCalorie = calculatedCalorie;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengambil data profil';
          _isLoadingProfile = false;
          // Gunakan nilai default jika ada error
          _targetCalorie = 2000;
        });
      }
      print('Error fetching profile: $e');
    }
  }

  /// Hitung target kalori menggunakan formula TDEE (Total Daily Energy Expenditure)
  /// Menggunakan Mifflin-St Jeor untuk BMR, kemudian dikalikan dengan activity factor
  int _calculateTargetCalorie({
    required int age,
    required double weight, // kg
    required double height, // cm
    required String gender,
    required String activityLevel,
  }) {
    // Hitung BMR (Basal Metabolic Rate) menggunakan Mifflin-St Jeor
    double bmr;
    if (gender.toLowerCase().contains('perempuan') ||
        gender.toLowerCase().contains('wanita')) {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }

    // Konversi activity level string ke double
    double activityFactor = double.tryParse(activityLevel) ?? 1.375;

    // Hitung TDEE (Total Daily Energy Expenditure)
    double tdee = bmr * activityFactor;

    // Bulatkan ke 100 terdekat
    return ((tdee / 100).round() * 100).toInt();
  }

  /// Setup real-time listener untuk food_logs
  /// Mendengarkan perubahan makanan yang dicatat user
  void _setupFoodLogsListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Dapatkan tanggal hari ini
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    try {
      _foodLogsSubscription = Supabase.instance.client
          .from('food_logs')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (List<Map<String, dynamic>> data) {
              _updateDailyCalories(userId, startOfDay, endOfDay);
            },
            onError: (e) {
              print('Error in food logs stream: $e');
            },
          );

      // Fetch initial data
      _updateDailyCalories(userId, startOfDay, endOfDay);
    } catch (e) {
      print('Error setting up food logs listener: $e');
    }
  }

  /// Update total kalori hari ini dari food_logs
  Future<void> _updateDailyCalories(
    String userId,
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('food_logs')
          .select('calories')
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String());

      if (mounted && response is List) {
        int total = 0;
        for (var log in response) {
          total += (log['calories'] as int? ?? 0);
        }

        setState(() {
          _calorieToday = total;
        });
      }
    } catch (e) {
      print('Error updating daily calories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Column(
        children: [
          // --- HEADER SECTION ---
          Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, $_userName 👋",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Mari jaga kesehatan Anda",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      // Logout Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Calorie Card - No Overlap
                  if (_isLoadingProfile)
                    const Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 60),
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Memuat data profil...'),
                            SizedBox(height: 60),
                          ],
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    Card(
                      elevation: 8,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            const Icon(
                              Icons.warning_rounded,
                              color: Colors.orange,
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchUserProfile,
                              child: const Text('Coba Lagi'),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    )
                  else
                    CalorieRingCard(
                      current: _calorieToday,
                      target: _targetCalorie,
                    ),
                ],
              ),
            ),

          // --- BODY CONTENT (No overlap, clean layout) ---
          Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Makro
                    const MacroNutrientRow(),
                    const SizedBox(height: 32),

                    // --- WATER TRACKER ---
                    _buildWaterTracker(),

                    const SizedBox(height: 32),

                    // Tombol Catat Makanan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: const Text(
                          'Catat Makanan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 26),
              selectedIcon: Icon(Icons.home_filled, size: 26),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, size: 26),
              selectedIcon: Icon(Icons.bar_chart_rounded, size: 26),
              label: 'Statistik',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 26),
              selectedIcon: Icon(Icons.person, size: 26),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: WATER TRACKER PREMIUM
  Widget _buildWaterTracker() {
    final percentage = (_glassCount / 8).clamp(0.0, 1.0);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.blue.withOpacity(0.15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.lightBlue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_drink,
                      color: Color(0xFF1976D2),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Minum Air Putih",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$_glassCount dari 8 gelas",
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: Colors.blue.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1976D2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
