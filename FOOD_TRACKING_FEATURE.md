# 📝 "Catat Makanan" Feature Implementation Guide

## Deskripsi
Fitur untuk user menambahkan makanan yang dikonsumsi ke dalam tracking. Setiap makanan yang dicatat akan otomatis update ring chart secara real-time.

## User Flow

```
User clicks "Catat Makanan"
        ↓
FoodTrackingPage opens
        ↓
Form displayed:
  - Nama Makanan (text input)
  - Kalori (number input)
  - Protein (g) 
  - Karbs (g)
  - Fat (g)
  - Meal Type (dropdown: breakfast/lunch/dinner/snack)
  - Portion Size (number input)
        ↓
User fills form + clicks "Simpan"
        ↓
Data inserted to food_logs table
        ↓
Real-time listener detects change
        ↓
_updateDailyCalories() runs
        ↓
Ring chart updates automatically ✨
```

---

## 1. Create Food Tracking Page

File: `lib/features/food_tracking/presentation/pages/food_tracking_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodTrackingPage extends StatefulWidget {
  const FoodTrackingPage({super.key});

  @override
  State<FoodTrackingPage> createState() => _FoodTrackingPageState();
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _portionSizeController = TextEditingController(text: '1.0');
  
  String _mealType = 'lunch';
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _saveFoodLog() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _errorMessage = 'User tidak ditemukan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('food_logs').insert({
        'user_id': userId,
        'food_name': _foodNameController.text,
        'calories': int.parse(_caloriesController.text),
        'protein': int.tryParse(_proteinController.text) ?? 0,
        'carbs': int.tryParse(_carbsController.text) ?? 0,
        'fat': int.tryParse(_fatController.text) ?? 0,
        'portion_size': double.tryParse(_portionSizeController.text) ?? 1.0,
        'meal_type': _mealType,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Makanan berhasil dicatat!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menyimpan: $e');
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
      body: SingleChildScrollView(
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

              // Nama Makanan
              const Text(
                'Nama Makanan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                  if (value?.isEmpty ?? true) return 'Nama makanan tidak boleh kosong';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Kalori
              const Text(
                'Kalori (kal)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                  if (value?.isEmpty ?? true) return 'Kalori tidak boleh kosong';
                  if (int.tryParse(value!) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Protein
              const Text(
                'Protein (g)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _mealType,
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Sarapan')),
                  DropdownMenuItem(value: 'lunch', child: Text('Makan Siang')),
                  DropdownMenuItem(value: 'dinner', child: Text('Makan Malam')),
                  DropdownMenuItem(value: 'snack', child: Text('Cemilan')),
                ]
                    .map((item) => DropdownMenuItem(
                          value: item.value,
                          child: item.child,
                        ))
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                  onPressed: _isLoading ? null : _saveFoodLog,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
```

---

## 2. Add Button to HomePage

Update `home_page.dart` - ubah button di bagian akhir:

```dart
// Sebelumnya: FAB atau hardcoded button
// Sekarang: Di dalam Column, sebelum SizedBox terakhir

ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FoodTrackingPage(),
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF2E7D32),
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 12,
    ),
  ),
  icon: const Icon(Icons.add),
  label: const Text('Catat Makanan'),
),
```

---

## 3. Directory Structure

```
lib/features/
├── food_tracking/
│   ├── presentation/
│   │   ├── pages/
│   │   │   └── food_tracking_page.dart  (NEW)
│   │   └── widgets/
│   │       └── (empty for now)
│   └── data/
│       └── (empty for now)
```

---

## 4. Update pubspec.yaml (If Needed)

Already included in your project:
- ✅ supabase_flutter
- ✅ flutter (Material Design)

No new dependencies needed! ✨

---

## 5. Testing Steps

### Manual Test:

1. **Login to app**
   - User dengan profile data (age, weight, height, etc)

2. **Check Ring Chart Shows Target**
   - Target should show calculated value
   - Example: 2100 kal for users with age 20, 60kg, 164cm

3. **Click "Catat Makanan"**
   - Form should open
   - Can input food data

4. **Fill Form & Save**
   ```
   Nasi Kuning | 250 kal
   Ayam Goreng | 300 kal
   ```

5. **Check Real-time Update**
   - Ring chart should update from 0% → 22% (550/2100)
   - **Without any page refresh!** ⚡

6. **Add More Food**
   ```
   Tahu Goreng | 150 kal
   ```
   - Ring chart updates to 28% (700/2100)

---

## 🎯 Expected Behavior

```
Before:
┌─────────────────┐
│   0%            │ ← Dikonsumsi: 0 kal
│  ────────────   │
└─────────────────┘

Click "Catat Makanan" → Fill form → Simpan

After (automatic, no reload):
┌─────────────────┐
│   26%           │ ← Dikonsumsi: 550 kal
│  ◢███░░░░░░░░┐  │
└─────────────────┘
```

---

## 📊 Database Entry Example

When user submits form, this gets inserted into `food_logs`:

```json
{
  "id": "uuid-1234",
  "user_id": "current-user-id",
  "food_name": "Nasi Kuning",
  "calories": 250,
  "protein": 5,
  "carbs": 45,
  "fat": 3,
  "portion_size": 1.0,
  "meal_type": "breakfast",
  "created_at": "2026-01-18T10:30:00Z"
}
```

---

## ⚠️ Important Points

1. **Real-time Listener Active**
   - HomePage already has `_setupFoodLogsListener()`
   - When food_logs table changes, HomePage knows immediately
   - No polling needed! 🚀

2. **Validation**
   - Food name required
   - Calories required (must be number)
   - Protein/Carbs/Fat are optional

3. **Error Handling**
   - If insert fails, show error in card
   - User can try again
   - Navigation won't pop if error

4. **User Context**
   - Auto-use current user ID from Auth
   - No need to select user in form
   - Secure: Each user only sees their own data (RLS policy)

---

## 🔗 Integration Points

```
FoodTrackingPage
       ↓
    [Form]
       ↓
  [Validasi]
       ↓
[Insert to food_logs]
       ↓
  Supabase Realtime
       ↓
  HomePage Listener ← _setupFoodLogsListener()
       ↓
_updateDailyCalories()
       ↓
setState(_calorieToday = ...)
       ↓
CalorieRingCard updates ✨
```

---

## 🚀 Next Steps After This

1. ✅ Food Tracking Form (THIS)
2. Food History List (view/edit/delete)
3. Daily Analytics
4. Weekly Trends
5. Notifications
6. Meal Presets (predefined foods)

---

## 📝 Summary

✅ Complete form code ready to copy-paste  
✅ Real-time integration already set up in HomePage  
✅ Database table structure provided  
✅ No additional dependencies needed  
✅ Full error handling included  

**Status: Ready to implement!** 🎯
