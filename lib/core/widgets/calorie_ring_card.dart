import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CalorieRingCard extends StatelessWidget {
  final int current;
  final int target;

  const CalorieRingCard({
    super.key,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    // Hitung persentase (0.0 sampai 1.0)
    double percent = current / target;
    if (percent > 1.0) percent = 1.0;

    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Sisa Kalori Hari Ini",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 18.0,
              percent: percent,
              animation: true,
              animationDuration: 1200, // Animasi muter saat dibuka
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${target - current}", // Sisa Kalori
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Text("kkal tersisa", style: TextStyle(color: Colors.grey)),
                ],
              ),
              progressColor: theme.colorScheme.primary, // Hijau
              backgroundColor: theme.colorScheme.surfaceVariant, // Abu-abu
              circularStrokeCap: CircularStrokeCap.round, // Ujungnya bulat
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegend("Terpakai", "$current", Colors.green),
                _buildLegend("Target", "$target", Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }
}