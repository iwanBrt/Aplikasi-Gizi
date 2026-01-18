import 'package:flutter/material.dart';

class MacroNutrientRow extends StatelessWidget {
  const MacroNutrientRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Protein (Target misal 100g)
        Expanded(child: _buildItem(context, "Protein", "45", 100, Colors.purpleAccent, Icons.fitness_center)),
        const SizedBox(width: 12),
        // Karbo (Target misal 250g)
        Expanded(child: _buildItem(context, "Karbo", "120", 250, Colors.orangeAccent, Icons.rice_bowl)),
        const SizedBox(width: 12),
        // Lemak (Target misal 60g)
        Expanded(child: _buildItem(context, "Lemak", "30", 60, Colors.redAccent, Icons.water_drop)),
      ],
    );
  }

  Widget _buildItem(BuildContext context, String label, String value, int target, Color color, IconData icon) {
    double progress = double.parse(value) / target;
    if (progress > 1.0) progress = 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${value}g",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Progress Bar Kecil
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}