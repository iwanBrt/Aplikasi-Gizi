import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class FoodTrackingPage extends StatefulWidget {
  const FoodTrackingPage({super.key});

  @override
  State<FoodTrackingPage> createState() => _FoodTrackingPageState();
}

class FoodItem {
  final int id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _portionSizeController = TextEditingController(text: '1.0');

  String _mealType = 'lunch';
  bool _isLoading = false;
  bool _isLoadingFoods = true;
  bool _isUploadingImage = false;
  String? _errorMessage;

  List<FoodItem> _foodsList = [];
  FoodItem? _selectedFood;

  XFile? _selectedImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _portionSizeController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    try {
      final response = await Supabase.instance.client
          .from('foods')
          .select('id, name, calories, protein, carbs, fat');

      if (mounted) {
        setState(() {
          _foodsList = (response as List)
              .map(
                (food) => FoodItem(
                  id: food['id'] as int,
                  name: food['name'] as String,
                  calories: food['calories'] as int,
                  protein: (food['protein'] as num).toDouble(),
                  carbs: (food['carbs'] as num).toDouble(),
                  fat: (food['fat'] as num).toDouble(),
                ),
              )
              .toList();
          _isLoadingFoods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat daftar makanan: $e';
          _isLoadingFoods = false;
        });
      }
    }
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selectedFood = food;
      _foodNameController.text = food.name;
      _caloriesController.text = food.calories.toString();
      _proteinController.text = food.protein.toString();
      _carbsController.text = food.carbs.toString();
      _fatController.text = food.fat.toString();
    });
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isUploadingImage = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _selectedImage = image);
        await _uploadImage(image);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal ambil foto: $e');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isUploadingImage = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _selectedImage = image);
        await _uploadImage(image);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal pilih foto: $e');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/$timestamp.jpg';

      // Read file as bytes
      final fileBytes = await image.readAsBytes();

      // Upload to Supabase storage
      await Supabase.instance.client.storage
          .from('food_images')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final url = Supabase.instance.client.storage
          .from('food_images')
          .getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _imageUrl = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Foto berhasil diupload')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Gagal upload foto: $e');
      }
    }
  }

  Future<void> _saveFoodLog() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _errorMessage = 'User tidak ditemukan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final calories = int.parse(_caloriesController.text);
      final protein = double.tryParse(_proteinController.text) ?? 0;
      final carbs = double.tryParse(_carbsController.text) ?? 0;
      final fat = double.tryParse(_fatController.text) ?? 0;
      final portionSize = double.tryParse(_portionSizeController.text) ?? 1.0;
      final foodName = _foodNameController.text;
      final finalCalories = (calories * portionSize).toInt();

      print('🍽️ Inserting food log:');
      print('  Food: $foodName');
      print('  Calories: $calories × $portionSize = $finalCalories');
      print('  Photo: $_imageUrl');

      final response = await Supabase.instance.client.from('food_logs').insert({
        'user_id': userId,
        'food_name': foodName,
        'calories': finalCalories,
        'protein': protein * portionSize,
        'carbs': carbs * portionSize,
        'fat': fat * portionSize,
        'portion_size': portionSize,
        'meal_type': _mealType,
        'image_url': _imageUrl,
      }).select();

      print('✅ Insert successful: $response');

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Makanan berhasil dicatat!'),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menyimpan: $e');
      print('❌ Error saving food log: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Makanan'),
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: _isLoadingFoods
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat daftar makanan...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),

                    // Image preview atau picker
                    const Text(
                      'Foto Makanan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImage != null && _imageUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                  _imageUrl = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isUploadingImage
                                    ? null
                                    : _pickImage,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Kamera'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF2E7D32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isUploadingImage
                                    ? null
                                    : _pickImageFromGallery,
                                icon: const Icon(Icons.image),
                                label: const Text('Galeri'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF1976D2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isUploadingImage)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 24),

                    // Pilih Makanan
                    const Text(
                      'Pilih Makanan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _foodsList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Tidak ada data makanan'),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<FoodItem>(
                              isExpanded: true,
                              underline: const SizedBox(),
                              value: _selectedFood,
                              hint: const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text('Pilih dari daftar makanan'),
                              ),
                              onChanged: (food) {
                                if (food != null) _selectFood(food);
                              },
                              items: _foodsList
                                  .map(
                                    (food) => DropdownMenuItem(
                                      value: food,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(food.name),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                    const SizedBox(height: 24),

                    // Atau Input Manual
                    const Text(
                      'Nama Makanan (Jika tidak ada di list)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _foodNameController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Nasi Kuning',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Nama makanan tidak boleh kosong';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Kalori
                    const Text(
                      'Kalori (kal)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Kalori tidak boleh kosong';
                        if (int.tryParse(value!) == null)
                          return 'Harus berupa angka';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Protein
                    const Text(
                      'Protein (g)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _proteinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Carbs
                    const Text(
                      'Karbohidrat (g)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _carbsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Fat
                    const Text(
                      'Lemak (g)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fatController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meal Type
                    const Text(
                      'Jenis Makanan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _mealType,
                      items:
                          const [
                                DropdownMenuItem(
                                  value: 'breakfast',
                                  child: Text('Sarapan'),
                                ),
                                DropdownMenuItem(
                                  value: 'lunch',
                                  child: Text('Makan Siang'),
                                ),
                                DropdownMenuItem(
                                  value: 'dinner',
                                  child: Text('Makan Malam'),
                                ),
                                DropdownMenuItem(
                                  value: 'snack',
                                  child: Text('Cemilan'),
                                ),
                              ]
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.value,
                                  child: item.child,
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _mealType = value);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Portion Size
                    const Text(
                      'Jumlah Porsi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _portionSizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '1.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isUploadingImage)
                            ? null
                            : _saveFoodLog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
