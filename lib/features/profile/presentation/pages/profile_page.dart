import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditing = false;

  // User data
  String _fullName = '';
  String _email = '';
  int _age = 25;
  double _weight = 70;
  double _height = 170;
  String _gender = 'Laki-laki'; // Laki-laki / Perempuan
  String _activityLevel =
      'sedentary'; // sedentary, light, moderate, very_active
  int _targetCalorie = 2000;
  String _calculatedTDEE = '';

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _targetCalorieController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _targetCalorieController = TextEditingController();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final email = Supabase.instance.client.auth.currentUser?.email ?? '';

      if (userId == null) {
        setState(() {
          _errorMessage = 'User tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _fullName = response['full_name'] ?? 'User';
        _email = email;
        _age = response['age'] ?? 25;
        _weight = (response['weight'] as num?)?.toDouble() ?? 70.0;
        _height = (response['height'] as num?)?.toDouble() ?? 170.0;
        _gender = response['gender'] ?? 'Laki-laki';
        _activityLevel = response['activity_level'] ?? 'sedentary';
        _targetCalorie = response['target_calorie'] ?? 2000;

        _nameController.text = _fullName;
        _ageController.text = _age.toString();
        _weightController.text = _weight.toStringAsFixed(1);
        _heightController.text = _height.toStringAsFixed(1);
        _targetCalorieController.text = _targetCalorie.toString();

        _calculateTDEE();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat profil: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateTDEE() {
    // Harris-Benedict Formula
    double bmr;
    if (_gender == 'Laki-laki') {
      bmr = 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * _age);
    } else {
      bmr = 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * _age);
    }

    // Activity multipliers
    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'very_active': 1.725,
    };

    final multiplier = activityMultipliers[_activityLevel] ?? 1.2;
    final tdee = (bmr * multiplier).round();

    setState(() {
      _calculatedTDEE = tdee.toString();
    });
  }

  Future<void> _saveProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('user_profiles')
          .update({
            'full_name': _nameController.text,
            'age': int.parse(_ageController.text),
            'weight': double.parse(_weightController.text),
            'height': double.parse(_heightController.text),
            'gender': _gender,
            'activity_level': _activityLevel,
            'target_calorie': int.parse(_targetCalorieController.text),
          })
          .eq('id', userId);

      setState(() {
        _fullName = _nameController.text;
        _age = int.parse(_ageController.text);
        _weight = double.parse(_weightController.text);
        _height = double.parse(_heightController.text);
        _targetCalorie = int.parse(_targetCalorieController.text);
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetCalorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Saya'), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Saya'), elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadProfile();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        elevation: 0,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade400, Colors.blue.shade800],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_email, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // TDEE Info Card
            if (!_isEditing)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green.shade400, Colors.green.shade700],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Daily Energy Expenditure',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_calculatedTDEE kcal/hari',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Target harian: $_targetCalorie kcal',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isEditing) const SizedBox(height: 24),

            // Personal Information Section
            Text(
              'Informasi Pribadi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              label: 'Nama Lengkap',
              value: _fullName,
              controller: _nameController,
              isEditing: _isEditing,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),

            // Body Metrics Section
            Text(
              'Data Fisik',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProfileField(
                    label: 'Umur',
                    value: '$_age tahun',
                    controller: _ageController,
                    isEditing: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProfileField(
                    label: 'Berat (kg)',
                    value: '${_weight.toStringAsFixed(1)} kg',
                    controller: _weightController,
                    isEditing: _isEditing,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProfileField(
                    label: 'Tinggi (cm)',
                    value: '${_height.toStringAsFixed(1)} cm',
                    controller: _heightController,
                    isEditing: _isEditing,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildGenderDropdown()),
              ],
            ),
            const SizedBox(height: 24),

            // Activity & Target
            Text(
              'Aktivitas & Target',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityLevelDropdown(),
            const SizedBox(height: 16),
            _buildProfileField(
              label: 'Target Kalori Harian',
              value: '$_targetCalorie kcal',
              controller: _targetCalorieController,
              isEditing: _isEditing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: label,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isEditing)
          DropdownButtonFormField<String>(
            value: _gender,
            items: const [
              DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
              DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
            ],
            onChanged: (value) {
              setState(() {
                _gender = value ?? 'Laki-laki';
                _calculateTDEE();
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _gender,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityLevelDropdown() {
    final activityLabels = {
      'sedentary': 'Sedentari (Jarang bergerak)',
      'light': 'Ringan (1-3 hari olahraga/minggu)',
      'moderate': 'Sedang (3-5 hari olahraga/minggu)',
      'very_active': 'Sangat Aktif (6-7 hari olahraga/minggu)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tingkat Aktivitas',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isEditing)
          DropdownButtonFormField<String>(
            value: _activityLevel,
            items: activityLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _activityLevel = value ?? 'sedentary';
                _calculateTDEE();
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activityLabels[_activityLevel] ?? _activityLevel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}
