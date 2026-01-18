import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CalorieRingCard extends StatelessWidget {
  final int current;
  final int target;

  const CalorieRingCard({Key? key, required this.current, required this.target})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (current / target * 100).clamp(0, 100).toDouble();
    final remaining = target - current;
    final progressPercentage = (current / target).clamp(0.0, 1.0);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Column(
                children: [
                  Text(
                    'Total Kalori Hari Ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Target: $target kal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: progressPercentage * 100,
                            color: const Color(0xFFFF9800),
                            title: '',
                            radius: 50,
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          PieChartSectionData(
                            value: (1 - progressPercentage) * 100,
                            color: Colors.grey.shade200,
                            title: '',
                            radius: 50,
                          ),
                        ],
                        centerSpaceRadius: 55,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lengkap',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Dikonsumsi', '$current', 'kal'),
                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                  _buildStatColumn('Target', '$target', 'kal'),
                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                  _buildStatColumn('Sisa', '$remaining', 'kal'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
