import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/food_tracking/presentation/pages/food_tracking_page.dart';
import '../../../../features/statistics/presentation/pages/statistics_page.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';
import 'scan_food_page.dart';
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

  // Data kalori dan makro hari ini
  int _calorieToday = 0;
  double _proteinToday = 0;
  double _carbsToday = 0;
  double _fatToday = 0;
  List<Map<String, dynamic>> _todayLogs = [];
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
      print('🔐 User ID: $userId');

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

      print('📋 Profile loaded: $response');

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
      print('❌ Error fetching profile: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengambil data profil: $e';
          _isLoadingProfile = false;
          _targetCalorie = 2000;
        });
      }
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
    if (userId == null) {
      setState(() {
        _errorMessage = 'User tidak ditemukan';
      });
      return;
    }

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
              if (mounted) {
                setState(() {
                  _errorMessage = 'Gagal load data makanan: $e';
                });
              }
            },
          );

      print('✅ Listener setup complete');
      // Initial load
      _updateDailyCalories(userId, startOfDay, endOfDay);
    } catch (e) {
      print('❌ Error setting up food logs listener: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal setup listener: $e';
        });
      }
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
          .select('id, food_name, calories, protein, carbs, fat, image_url, meal_type, created_at')
          .eq('user_id', userId)
          .filter('created_at', 'gte', '${todayStr}T00:00:00')
          .filter('created_at', 'lte', '${todayStr}T23:59:59');

      print('📋 Query response: $response');

      if (mounted) {
        int total = 0;
        double totalProtein = 0;
        double totalCarbs = 0;
        double totalFat = 0;

        for (var log in response) {
          final calories = log['calories'];
          final foodName = log['food_name'] ?? 'Unknown';
          final protein = log['protein'] ?? 0;
          final carbs = log['carbs'] ?? 0;
          final fat = log['fat'] ?? 0;

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

          // Accumulate macros
          totalProtein += (protein is num) ? protein.toDouble() : 0;
          totalCarbs += (carbs is num) ? carbs.toDouble() : 0;
          totalFat += (fat is num) ? fat.toDouble() : 0;
        }

        print('✅ Total kalori hari ini: $total');
        print(
          '✅ Total protein: $totalProtein, carbs: $totalCarbs, fat: $totalFat',
        );

        if (mounted) {
          setState(() {
            _calorieToday = total;
            _proteinToday = totalProtein;
            _carbsToday = totalCarbs;
            _fatToday = totalFat;
            _todayLogs = response;
          });
        }
      }
    } catch (e) {
      print('❌ Error updating daily calories: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal update kalori: $e';
        });
      }
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

  Future<void> _deleteLog(String id) async {
    print('🔴 DELETE TRIGGERED for id: $id');
    print('🔴 Current _todayLogs length: ${_todayLogs.length}');
    print('🔴 Current _calorieToday: $_calorieToday');
    
    try {
      if (mounted) {
        setState(() {
         
          final deletedLog = _todayLogs.firstWhere(
            (log) => log['id'] == id,
            orElse: () => {},
          );

          print('🔴 Found deletedLog: $deletedLog');

          if (deletedLog.isNotEmpty) {
            // Kurangi dari total
            final calories = deletedLog['calories'] ?? 0;
            final protein = deletedLog['protein'] ?? 0;
            final carbs = deletedLog['carbs'] ?? 0;
            final fat = deletedLog['fat'] ?? 0;

            final caloriesInt = (calories is int) ? calories : (calories is double) ? calories.toInt() : int.tryParse(calories.toString()) ?? 0;
            final proteinDouble = (protein is num) ? protein.toDouble() : 0.0;
            final carbsDouble = (carbs is num) ? carbs.toDouble() : 0.0;
            final fatDouble = (fat is num) ? fat.toDouble() : 0.0;

            print('🔴 Reducing calories by: $caloriesInt');
            
            _calorieToday -= caloriesInt;
            _proteinToday -= proteinDouble;
            _carbsToday -= carbsDouble;
            _fatToday -= fatDouble;

            print('🔴 New _calorieToday: $_calorieToday');

            // Hapus dari list
            _todayLogs.removeWhere((log) => log['id'] == id);
            print('🔴 New _todayLogs length: ${_todayLogs.length}');
          } else {
            print('🔴 ERROR: deletedLog is empty!');
          }
        });
      } else {
        print('🔴 ERROR: Widget not mounted!');
      }

      // Kemudian hapus dari database
      print('🔴 Deleting from database...');
      await Supabase.instance.client.from('food_logs').delete().eq('id', id);
      print('🔴 Successfully deleted from database');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Makanan berhasil dihapus'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('✅ DELETE COMPLETED for id: $id');
    } catch (e) {
      print('❌ Error deleting log: $e');
      print('❌ Error stack: ${StackTrace.current}');
      
      // Rollback - refresh data dari server
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        );
        _updateDailyCalories(userId, startOfDay, endOfDay);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menghapus: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to Scan Food Page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanFoodPage()),
          );
          
          // Refresh data if food was added
          if (result == true) {
            _refreshCalories();
          }
        },
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: const Text(
          'AI Scan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 6,
      ),
      body: SingleChildScrollView(
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
                  MacroNutrientRow(
                    proteinCurrent: _proteinToday,
                    carbsCurrent: _carbsToday,
                    fatCurrent: _fatToday,
                  ),
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
                  if (_todayLogs.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Riwayat Hari Ini',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_todayLogs.length} makanan',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todayLogs.length,
                      itemBuilder: (context, index) {
                        final log = _todayLogs[index];
                        final foodName = log['food_name'] ?? 'Unknown';
                        final calories = log['calories'] ?? 0;
                        final protein = log['protein'] ?? 0;
                        final carbs = log['carbs'] ?? 0;
                        final fat = log['fat'] ?? 0;
                        final imageUrl = log['image_url'];
                        final id = log['id'];
                        final mealType = log['meal_type'] ?? '';

                        // Icon dan label untuk meal type
                        IconData mealIcon;
                        String mealLabel;
                        Color mealColor;

                        switch (mealType) {
                          case 'breakfast':
                            mealIcon = Icons.wb_sunny;
                            mealLabel = 'Sarapan';
                            mealColor = Colors.orange;
                            break;
                          case 'lunch':
                            mealIcon = Icons.wb_sunny_outlined;
                            mealLabel = 'Makan Siang';
                            mealColor = Colors.amber;
                            break;
                          case 'dinner':
                            mealIcon = Icons.nightlight_round;
                            mealLabel = 'Makan Malam';
                            mealColor = Colors.indigo;
                            break;
                          case 'snack':
                            mealIcon = Icons.cookie;
                            mealLabel = 'Cemilan';
                            mealColor = Colors.pink;
                            break;
                          default:
                            mealIcon = Icons.restaurant;
                            mealLabel = 'Makanan';
                            mealColor = Colors.grey;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header dengan meal type dan delete button
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mealColor.withOpacity(0.1),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: mealColor.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        mealIcon,
                                        size: 18,
                                        color: mealColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        mealLabel,
                                        style: TextStyle(
                                          color: mealColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.shade400,
                                            size: 20,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext dialogContext) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  title: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.warning_amber_rounded,
                                                        color: Colors.orange.shade400,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text('Hapus Makanan?'),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    'Yakin ingin menghapus "$foodName"?',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(dialogContext),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Colors.grey.shade700,
                                                      ),
                                                      child: const Text('Batal'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(dialogContext);
                                                        _deleteLog(id);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                      child: const Text('Hapus'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Content dengan foto (jika ada)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Foto makanan (jika ada)
                                      if (imageUrl != null &&
                                          imageUrl.toString().isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 16),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              imageUrl.toString(),
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 90,
                                                  height: 90,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey.shade400,
                                                    size: 32,
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  width: 90,
                                                  height: 90,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: const Color(0xFF2E7D32),
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),

                                      // Info makanan
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Nama makanan
                                            Text(
                                              foodName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            const SizedBox(height: 10),

                                            // Kalori dengan icon
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF2E7D32),
                                                    const Color(0xFF43A047),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.local_fire_department,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '$calories kal',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // Nutrisi lain
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                _buildNutrientChip(
                                                  icon: Icons.fitness_center,
                                                  label: 'Protein',
                                                  value: '${protein.toStringAsFixed(1)}g',
                                                  color: Colors.blue,
                                                ),
                                                _buildNutrientChip(
                                                  icon: Icons.grain,
                                                  label: 'Karbo',
                                                  value: '${carbs.toStringAsFixed(1)}g',
                                                  color: Colors.orange,
                                                ),
                                                _buildNutrientChip(
                                                  icon: Icons.water_drop,
                                                  label: 'Lemak',
                                                  value: '${fat.toStringAsFixed(1)}g',
                                                  color: Colors.purple,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else
                    const SizedBox(height: 32),
                ],
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

  Widget _buildNutrientChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: Color.fromRGBO(
                (color.red * 0.7).toInt(),
                (color.green * 0.7).toInt(),
                (color.blue * 0.7).toInt(),
                1,
              ),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Color(0xFF1976D2),
                        ),
                        iconSize: 28,
                        onPressed: _glassCount > 0
                            ? () {
                                setState(() {
                                  _glassCount--;
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF1976D2),
                        ),
                        iconSize: 28,
                        onPressed: _glassCount < 8
                            ? () {
                                setState(() {
                                  _glassCount++;
                                });
                              }
                            : null,
                      ),
                    ],
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
