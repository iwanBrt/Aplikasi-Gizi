import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/food_tracking/presentation/pages/food_tracking_page.dart';
import '../../../../features/statistics/presentation/pages/statistics_page.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';
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

  int _glassCount = 3;
  int _selectedNavIndex = 0;

  // Data profil dari Supabase
  int _targetCalorie = 2000;
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
          _targetCalorie = 2000;
        });
      }
      print('Error fetching profile: $e');
    }
  }

  int _calculateTargetCalorie({
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
  }) {
    double bmr;
    if (gender.toLowerCase().contains('perempuan') ||
        gender.toLowerCase().contains('wanita')) {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }

    double activityFactor = double.tryParse(activityLevel) ?? 1.375;
    double tdee = bmr * activityFactor;

    return ((tdee / 100).round() * 100).toInt();
  }

  void _setupFoodLogsListener() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    try {
      // Listener tanpa filter tanggal - lebih reliable untuk real-time
      _foodLogsSubscription = Supabase.instance.client
          .from('food_logs')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (List<Map<String, dynamic>> data) {
              print('🔔 Food logs stream triggered: ${data.length} items');
              _updateDailyCalories(userId, startOfDay, endOfDay);
            },
            onError: (e) {
              print('❌ Error in food logs stream: $e');
            },
          );

      print('✅ Listener setup complete');
      // Initial load
      _updateDailyCalories(userId, startOfDay, endOfDay);
    } catch (e) {
      print('❌ Error setting up food logs listener: $e');
    }
  }

  Future<void> _updateDailyCalories(
    String userId,
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      // Format dates untuk query
      final todayStr = startOfDay.toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD only

      print('📊 Querying calories: user=$userId, date=$todayStr');

      // Query dengan casting date saja (ignore timezone)
      final response = await Supabase.instance.client
          .from('food_logs')
          .select('id, food_name, calories, created_at')
          .eq('user_id', userId)
          .filter('created_at', 'gte', '${todayStr}T00:00:00')
          .filter('created_at', 'lte', '${todayStr}T23:59:59');

      print('📋 Query response: $response');

      if (mounted) {
        int total = 0;
        for (var log in response) {
          final calories = log['calories'];
          final foodName = log['food_name'] ?? 'Unknown';

          if (calories != null) {
            int cal = 0;
            if (calories is int) {
              cal = calories;
            } else if (calories is double) {
              cal = calories.toInt();
            } else if (calories is String) {
              cal = int.tryParse(calories) ?? 0;
            }
            total += cal;
            print('  → $foodName: $cal kal');
          }
        }

        print('✅ Total kalori hari ini: $total');

        if (mounted) {
          setState(() {
            _calorieToday = total;
          });
        }
      }
    } catch (e) {
      print('❌ Error updating daily calories: $e');
    }
  }

  void _refreshCalories() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    _updateDailyCalories(userId, startOfDay, endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Mari jaga kesehatan Anda",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
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
                    if (_isLoadingProfile)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Column(
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
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
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

              // BODY
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MacroNutrientRow(),
                    const SizedBox(height: 32),
                    _buildWaterTracker(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Push to FoodTrackingPage
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FoodTrackingPage(),
                            ),
                          );
                          // Refresh kalori setelah kembali
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _refreshCalories();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
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
            ],
          ),
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
            if (index == 1) {
              // Navigate to Statistics
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsPage()),
              );
            } else if (index == 2) {
              // Navigate to Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            } else {
              setState(() => _selectedNavIndex = index);
            }
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

  Widget _buildWaterTracker() {
    final percentage = (_glassCount / 8).clamp(0.0, 1.0);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                              ?.copyWith(fontWeight: FontWeight.w700),
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
