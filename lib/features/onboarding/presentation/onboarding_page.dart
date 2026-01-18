import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import HomePage agar setelah simpan data langsung masuk Dashboard
import '../../../../features/home/presentation/pages/home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- CONTROLLER INPUT ---
  final _ageController = TextEditingController();
  final _weightController = TextEditingController(); // Berat (kg)
  final _heightController = TextEditingController(); // Tinggi (cm)

  // --- VARIABEL PILIHAN ---
  String _gender = 'Laki-laki';
  double _activityLevel = 1.2; // Default: Sedentary (Jarang Olahraga)

  // Data Pilihan Aktivitas (Label & Nilai Multiplier)
  final List<Map<String, dynamic>> _activityOptions = [
    {'label': 'Jarang Olahraga (Rebahan)', 'value': 1.2},
    {'label': 'Olahraga Ringan (1-3 hari/minggu)', 'value': 1.375},
    {'label': 'Olahraga Sedang (3-5 hari/minggu)', 'value': 1.55},
    {'label': 'Olahraga Berat (6-7 hari/minggu)', 'value': 1.725},
    {'label': 'Atlet / Fisik Ekstrem', 'value': 1.9},
  ];

  // --- LOGIKA HITUNG KALORI (RUMUS MIFFLIN-ST JEOR) ---
  int _calculateCalories(int age, double weight, double height, String gender, double activity) {
    double bmr;
    // 1. Hitung BMR (Basal Metabolic Rate) - Energi minimal buat hidup
    if (gender == 'Laki-laki') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // 2. Hitung TDEE (Total Daily Energy Expenditure) - Kalori harian
    double tdee = bmr * activity;
    
    return tdee.round(); // Bulatkan ke angka terdekat
  }

  // --- FUNGSI SIMPAN KE SUPABASE ---
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw "User tidak ditemukan, silakan login ulang.";

      // 1. Ambil data dari input
      final int age = int.parse(_ageController.text);
      final double weight = double.parse(_weightController.text);
      final double height = double.parse(_heightController.text);

      // 2. Hitung Target Kalori
      final int dailyCalories = _calculateCalories(age, weight, height, _gender, _activityLevel);

      // 3. Kirim ke Tabel 'user_profiles'
      await Supabase.instance.client.from('user_profiles').upsert({
        'id': user.id, // ID User yang sedang login
        'full_name': user.userMetadata?['full_name'], // Ambil nama dari login tadi
        'age': age,
        'gender': _gender,
        'weight': weight,
        'height': height,
        'activity_level': _activityLevel.toString(),
        'daily_calories': dailyCalories, // HASIL HITUNGAN DISIMPAN DISINI
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // 4. Sukses! Pindah ke Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profil disimpan! Targetmu: $dailyCalories kkal/hari")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lengkapi Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mari hitung kebutuhan gizimu 🥗",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Data ini digunakan untuk menghitung target kalori harianmu secara akurat."),
              const SizedBox(height: 32),

              // --- 1. JENIS KELAMIN ---
              const Text("Jenis Kelamin", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _genderRadio('Laki-laki', Icons.male),
                  const SizedBox(width: 16),
                  _genderRadio('Perempuan', Icons.female),
                ],
              ),
              const SizedBox(height: 24),

              // --- 2. UMUR, BERAT, TINGGI ---
              Row(
                children: [
                  Expanded(
                    child: _buildNumInput("Usia (thn)", _ageController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumInput("Berat (kg)", _weightController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumInput("Tinggi (cm)", _heightController),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- 3. AKTIVITAS FISIK ---
              const Text("Seberapa sering kamu bergerak?", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                value: _activityLevel,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _activityOptions.map((option) {
                  return DropdownMenuItem<double>(
                    value: option['value'],
                    child: Text(
                      option['label'],
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _activityLevel = val!),
              ),
              const SizedBox(height: 40),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("HITUNG & MULAI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET KECIL UNTUK INPUT ANGKA
  Widget _buildNumInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Wajib isi';
        if (double.tryParse(value) == null) return 'Angka!';
        return null;
      },
    );
  }

  // WIDGET KECIL UNTUK PILIHAN GENDER
  Widget _genderRadio(String value, IconData icon) {
    bool isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
            border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 30),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: isSelected ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}