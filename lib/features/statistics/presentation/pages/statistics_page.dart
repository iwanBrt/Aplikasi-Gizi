import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class DailyStats {
  final DateTime date;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int target;

  DailyStats({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.target,
  });

  double get percentage => (calories / target * 100).clamp(0, 100);
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<DailyStats> _weeklyData = [];
  int _targetCalorie = 2000;

  // Tab selection
  int _selectedTab = 0; // 0: Weekly, 1: Monthly, 2: Nutrients

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'User tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      // Fetch target calorie
      final profileResponse = await Supabase.instance.client
          .from('user_profiles')
          .select('target_calorie')
          .eq('id', userId)
          .single();

      final targetCalorie = profileResponse['target_calorie'] as int? ?? 2000;

      // Fetch weekly data (last 7 days)
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));

      final List<DailyStats> weeklyStats = [];

      for (int i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];

        final logsResponse = await Supabase.instance.client
            .from('food_logs')
            .select('calories, protein, carbs, fat')
            .eq('user_id', userId)
            .filter('created_at', 'gte', '${dateStr}T00:00:00')
            .filter('created_at', 'lte', '${dateStr}T23:59:59');

        int totalCalories = 0;
        double totalProtein = 0;
        double totalCarbs = 0;
        double totalFat = 0;

        for (var log in logsResponse) {
          totalCalories += (log['calories'] as int? ?? 0);
          totalProtein += (log['protein'] as num? ?? 0).toDouble();
          totalCarbs += (log['carbs'] as num? ?? 0).toDouble();
          totalFat += (log['fat'] as num? ?? 0).toDouble();
        }

        weeklyStats.add(
          DailyStats(
            date: date,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            target: targetCalorie,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _weeklyData = weeklyStats;
          _targetCalorie = targetCalorie;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _loadStatistics();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab selector
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(child: _buildTab(0, 'Minggu Ini')),
                        Expanded(child: _buildTab(1, 'Nutrisi')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Content based on selected tab
                  if (_selectedTab == 0) ...[
                    _buildWeeklyChart(),
                    const SizedBox(height: 24),
                    _buildWeeklySummary(),
                  ] else if (_selectedTab == 1) ...[
                    _buildNutrientBreakdown(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kalori Mingguan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: (_targetCalorie * 1.2).toDouble(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weeklyData.length) {
                            final day = _weeklyData[index].date
                                .toString()
                                .split(' ')[0]
                                .split('-')[2];
                            return Text(
                              day,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: _weeklyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.calories.toDouble(),
                          color: data.calories > data.target
                              ? Colors.orange
                              : const Color(0xFF2E7D32),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Dalam target'),
                  const SizedBox(width: 24),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Melebihi target'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    final totalCalories = _weeklyData.fold<int>(
      0,
      (sum, data) => sum + data.calories,
    );
    final avgCalories = (totalCalories / _weeklyData.length).round();
    final daysOnTarget = _weeklyData
        .where((data) => data.calories <= data.target)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Minggu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Kalori',
                '$totalCalories',
                'kal',
                const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Rata-rata',
                '$avgCalories',
                'kal',
                const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Target Tercapai',
                '$daysOnTarget',
                'dari 7 hari',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Target Kalori',
                '$_targetCalorie',
                'kal/hari',
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBreakdown() {
    final todayData = _weeklyData.isNotEmpty ? _weeklyData.last : null;

    if (todayData == null) {
      return const Center(child: Text('Belum ada data hari ini'));
    }

    final totalMacro =
        todayData.protein * 4 + todayData.carbs * 4 + todayData.fat * 9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrisi Hari Ini',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: todayData.protein * 4,
                          color: const Color(0xFFFF6B6B),
                          title: 'Protein',
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: todayData.carbs * 4,
                          color: const Color(0xFF4ECDC4),
                          title: 'Carbs',
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: todayData.fat * 9,
                          color: const Color(0xFFFFE66D),
                          title: 'Fat',
                          radius: 60,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildNutrientRow(
                  'Protein',
                  '${todayData.protein.toStringAsFixed(1)}g',
                  '${((todayData.protein * 4 / totalMacro) * 100).toStringAsFixed(0)}%',
                  const Color(0xFFFF6B6B),
                ),
                const SizedBox(height: 12),
                _buildNutrientRow(
                  'Karbohidrat',
                  '${todayData.carbs.toStringAsFixed(1)}g',
                  '${((todayData.carbs * 4 / totalMacro) * 100).toStringAsFixed(0)}%',
                  const Color(0xFF4ECDC4),
                ),
                const SizedBox(height: 12),
                _buildNutrientRow(
                  'Lemak',
                  '${todayData.fat.toStringAsFixed(1)}g',
                  '${((todayData.fat * 9 / totalMacro) * 100).toStringAsFixed(0)}%',
                  const Color(0xFFFFE66D),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientRow(
    String label,
    String value,
    String percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text(percentage, style: TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}
