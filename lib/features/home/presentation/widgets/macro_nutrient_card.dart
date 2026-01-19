import 'package:flutter/material.dart';

class MacroNutrientRow extends StatelessWidget {
  final double proteinCurrent;
  final double proteinTarget;
  final double carbsCurrent;
  final double carbsTarget;
  final double fatCurrent;
  final double fatTarget;

  const MacroNutrientRow({
    Key? key,
    this.proteinCurrent = 0,
    this.proteinTarget = 50,
    this.carbsCurrent = 0,
    this.carbsTarget = 250,
    this.fatCurrent = 0,
    this.fatTarget = 75,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withOpacity(0.15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrisi Makro',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),
              _buildMacroRow(
                'Protein',
                proteinCurrent,
                proteinTarget,
                Icons.fastfood,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 18),
              _buildMacroRow(
                'Karbohidrat',
                carbsCurrent,
                carbsTarget,
                Icons.grain,
                const Color(0xFFFF9800),
              ),
              const SizedBox(height: 18),
              _buildMacroRow(
                'Lemak',
                fatCurrent,
                fatTarget,
                Icons.opacity,
                const Color(0xFFE91E63),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    String label,
    double current,
    double target,
    IconData icon,
    Color color,
  ) {
    final percentage = (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${current.toStringAsFixed(0)}g dari ${target.toStringAsFixed(0)}g',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
