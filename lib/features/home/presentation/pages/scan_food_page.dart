import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../../core/constants/env.dart';

class ScanFoodPage extends StatefulWidget {
  const ScanFoodPage({super.key});

  @override
  State<ScanFoodPage> createState() => _ScanFoodPageState();
}

class _ScanFoodPageState extends State<ScanFoodPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  XFile? _selectedImage;
  bool _isAnalyzing = false;
  bool _isAnalyzed = false;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Default meal type, akan di-update otomatis di initState berdasarkan jam
  String _selectedMealType = 'breakfast'; 

  @override
  void initState() {
    super.initState();
    _determineMealType();
  }

  void _determineMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      _selectedMealType = 'breakfast'; // 05:00 - 11:00 -> Sarapan
    } else if (hour >= 11 && hour < 15) {
      _selectedMealType = 'lunch';     // 11:00 - 15:00 -> Makan Siang
    } else if (hour >= 15 && hour < 19) {
      _selectedMealType = 'snack';     // 15:00 - 19:00 -> Snack/Sore
    } else {
      _selectedMealType = 'dinner';    // 19:00 - 05:00 -> Makan Malam
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isAnalyzed = false;
          _errorMessage = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mengambil foto: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isAnalyzed = false;
          _errorMessage = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mengambil foto: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      print('🔑 API Key: ${Env.geminiApiKey.substring(0, 15)}...');
      
      // Read image file as bytes
      final bytes = await _selectedImage!.readAsBytes();
      print('📸 Image size: ${bytes.length} bytes');
      
      // Initialize Gemini with vision model
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview', // Model stable yang mensupport vision
        apiKey: Env.geminiApiKey,
      );

      print('Analyzing image with Gemini Vision...');
      
      // Determine correct mime type
      final fileExt = _selectedImage!.name.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (fileExt == 'png') mimeType = 'image/png';
      if (fileExt == 'webp') mimeType = 'image/webp';
      if (fileExt == 'heic') mimeType = 'image/heic';

      // Create prompt for food analysis
      final prompt = '''Analisis gambar makanan ini dan berikan informasi nutrisi dalam format JSON berikut:
{
  "food_name": "nama makanan dalam bahasa Indonesia",
  "calories": angka kalori (integer),
  "protein": gram protein (float),
  "carbs": gram karbohidrat (float),
  "fat": gram lemak (float)
}

Berikan HANYA JSON tanpa teks tambahan.''';

      // Send multimodal request with image and text
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes), // Use correct mime type
        ])
      ];

      final response = await model.generateContent(content);
      final aiMessage = response.text ?? '';
      
      print('🤖 AI Response: $aiMessage');
      
      // Parse nutrition data from JSON
      try {
        // Clean response - remove markdown code blocks if present
        String cleanedResponse = aiMessage.trim();
        if (cleanedResponse.startsWith('```json')) {
          cleanedResponse = cleanedResponse.substring(7);
        }
        if (cleanedResponse.startsWith('```')) {
          cleanedResponse = cleanedResponse.substring(3);
        }
        if (cleanedResponse.endsWith('```')) {
          cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
        }
        cleanedResponse = cleanedResponse.trim();
        
        // Check if JSON looks incomplete
        if (!cleanedResponse.endsWith('}')) {
          throw FormatException('JSON terpotong - tidak ada closing brace.');
        }
        
        final nutritionData = jsonDecode(cleanedResponse);
        
        // Validate required fields
        if (nutritionData['food_name'] == null || 
            nutritionData['calories'] == null || 
            nutritionData['protein'] == null || 
            nutritionData['carbs'] == null || 
            nutritionData['fat'] == null) {
          throw FormatException('Field JSON tidak lengkap');
        }
        
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _isAnalyzed = true;
            _foodNameController.text = nutritionData['food_name'] ?? 'Makanan';
            // Round calories to integer since database expects int
            final caloriesValue = nutritionData['calories'];
            _caloriesController.text = (caloriesValue is int) 
                ? caloriesValue.toString() 
                : (caloriesValue as num).round().toString();
            _proteinController.text = nutritionData['protein'].toString();
            _carbsController.text = nutritionData['carbs'].toString();
            _fatController.text = nutritionData['fat'].toString();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Analisis berhasil! Periksa dan edit jika perlu.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (parseError) {
        print('⚠️ Parse error: $parseError');
        print('Raw AI response length: ${aiMessage.length} chars');
        print('Raw AI response: $aiMessage');
        
        // Try to extract food name at least from partial response
        String extractedFoodName = 'Makanan (Edit Manual)';
        try {
          final foodNameMatch = RegExp(r'"food_name":\s*"([^"]+)"').firstMatch(aiMessage);
          if (foodNameMatch != null) {
            extractedFoodName = foodNameMatch.group(1) ?? extractedFoodName;
          }
        } catch (e) {
          print('Could not extract food name');
        }
        
        // Fallback to manual input
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _isAnalyzed = true;
            _foodNameController.text = extractedFoodName;
            _caloriesController.text = '0';
            _proteinController.text = '0.0';
            _carbsController.text = '0.0';
            _fatController.text = '0.0';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Response terpotong atau format tidak valid.\nDitemukan: $extractedFoodName\n\nSilakan isi data nutrisi manual.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      
    } catch (e) {
      print('❌ Error analyzing image: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Error: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ Gagal analisis gambar'),
                const SizedBox(height: 4),
                Text(
                  'Detail: ${e.toString()}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
        
        // Tetap buka form untuk input manual
        setState(() {
          _isAnalyzed = true;
          _foodNameController.text = '';
          _caloriesController.text = '';
          _proteinController.text = '';
          _carbsController.text = '';
          _fatController.text = '';
        });
      }
    }
  }

  Future<void> _saveFoodLog() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ User tidak ditemukan')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Upload Image ke Supabase Storage (jika ada gambar)
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          print('Uploading image to Supabase Storage...');
          final bytes = await _selectedImage!.readAsBytes();
          // Gunakan .name agar aman di Web & Mobile
          final fileExt = _selectedImage!.name.split('.').last;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final filePath = '$userId/$fileName';
          
          await Supabase.instance.client.storage
              .from('food_images') // Pastikan bucket 'food_images' sudah dibuat di Supabase
              .uploadBinary(
                filePath,
                bytes,
                fileOptions: FileOptions(contentType: 'image/$fileExt'),
              );

          imageUrl = Supabase.instance.client.storage
              .from('food_images')
              .getPublicUrl(filePath);
              
          print('Image uploaded: $imageUrl');
        } catch (storageError) {
          print('Upload error: $storageError');
          // Lanjut simpan data meski gambar gagal upload (opsional)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal upload gambar, menyimpan data teks saja...'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      print('Controller values before parsing:');
      print('  - Calories text: "${_caloriesController.text}"');
      print('  - Protein text: "${_proteinController.text}"');
      print('  - Carbs text: "${_carbsController.text}"');
      print('  - Fat text: "${_fatController.text}"');
      
      // Parse as double first then round to int to safe-guard against DB Integer constraints
      final calories = double.parse(_caloriesController.text.trim()).round();
      final protein = double.parse(_proteinController.text.trim()).round(); // Rounding to int
      final carbs = double.parse(_carbsController.text.trim()).round();     // Rounding to int
      final fat = double.parse(_fatController.text.trim()).round();         // Rounding to int
      final foodName = _foodNameController.text.trim();

      print('Parsed data (rounded to int for safety):');
      print('  - Food: $foodName');
      print('  - Calories: $calories');
      print('  - Protein: $protein');
      print('  - Carbs: $carbs');
      print('  - Fat: $fat');
      print('  - Image URL: $imageUrl');

      final dataToInsert = {
        'user_id': userId,
        'food_name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal_type': _selectedMealType, // Gunakan pilihan user
        'portion_size': 1,
        'created_at': DateTime.now().toIso8601String(), // Gunakan waktu lokal perangkat
        // Masukkan URL gambar ke database jika berhasil upload
        if (imageUrl != null) 'image_url': imageUrl,
      };
      
      print('Data being sent to Supabase:');
      print(dataToInsert);

      await Supabase.instance.client.from('food_logs').insert(dataToInsert);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Makanan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Kembali ke HomePage dengan success flag
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error saving: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Scan Makanan'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.green.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Food Analyzer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'hitung kandungan nutrisi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Image Preview or Picker
            if (_selectedImage == null)
              _buildImagePicker()
            else
              _buildImagePreview(),

            const SizedBox(height: 24),

            // Analyzing Indicator
            if (_isAnalyzing)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      '🤖 Sedang menganalisis makanan...',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI sedang mengenali dan menghitung nutrisi',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Result Form
            if (_isAnalyzed && !_isAnalyzing) _buildResultForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Ambil Foto Makanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih dari kamera atau galeri',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: kIsWeb
                ? Image.network(
                    _selectedImage!.path,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_selectedImage!.path),
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _isAnalyzed = false;
                    _foodNameController.clear();
                    _caloriesController.clear();
                    _proteinController.clear();
                    _carbsController.clear();
                    _fatController.clear();
                  });
                },
              ),
            ),
          ),
          if (!_isAnalyzed && !_isAnalyzing)
            Positioned(
              bottom: 12,
              right: 12,
              child: ElevatedButton.icon(
                onPressed: _analyzeImage,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Analisis Ulang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success indicator
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analisis Selesai!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Periksa dan edit data jika diperlukan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildTextField(
            controller: _foodNameController,
            label: 'Nama Makanan',
            icon: Icons.restaurant,
            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _caloriesController,
            label: 'Kalori (kal)',
            icon: Icons.local_fire_department,
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _proteinController,
                  label: 'Protein (g)',
                  icon: Icons.fitness_center,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _carbsController,
                  label: 'Karbo (g)',
                  icon: Icons.grain,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _fatController,
            label: 'Lemak (g)',
            icon: Icons.water_drop,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Dropdown Pilihan Waktu Makan
          DropdownButtonFormField<String>(
            value: _selectedMealType,
            decoration: InputDecoration(
              labelText: 'Waktu Makan',
              prefixIcon: const Icon(Icons.access_time),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'breakfast', child: Text('Sarapan (Pagi)')),
              DropdownMenuItem(value: 'lunch', child: Text('Makan Siang')),
              DropdownMenuItem(value: 'snack', child: Text('Cemilan / Snack')),
              DropdownMenuItem(value: 'dinner', child: Text('Makan Malam')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedMealType = newValue);
              }
            },
          ),
          
          const SizedBox(height: 32),

          // Save Button
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveFoodLog,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Makanan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
