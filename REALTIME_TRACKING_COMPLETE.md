# 🎯 Real-time Tracking Integration - COMPLETE

## ✅ What's Been Implemented

### 1. **Dynamic Target Calorie Calculation**
Target kalori sekarang dihitung **otomatis** berdasarkan data user:

```
Formula: TDEE = BMR × Activity Factor

BMR (Basal Metabolic Rate) = Mifflin-St Jeor Formula
- Pria: (10 × berat) + (6.25 × tinggi) - (5 × umur) + 5
- Wanita: (10 × berat) + (6.25 × tinggi) - (5 × umur) - 161

Activity Levels:
- 1.200 = Sedentary
- 1.375 = Light (1-3x/minggu) 
- 1.550 = Moderate (3-5x/minggu)
- 1.725 = Very Active (6-7x/minggu)
- 1.900 = Extra Active (2x/hari)
```

**Contoh:**
- User: Pria, 20 tahun, 60kg, 164cm, aktivitas 1.375
- BMR = (10×60) + (6.25×164) - (5×20) + 5 = 600 + 1025 - 100 + 5 = **1530 kal**
- TDEE = 1530 × 1.375 = **2104 kal** (dibulatkan jadi 2100)

### 2. **Real-time Food Tracking**
App sekarang mendengarkan **real-time updates** dari `food_logs` table:

```dart
// Di HomePage, listener akan auto-detect:
- Makanan baru ditambahkan
- Makanan diedit
- Makanan dihapus

→ Ring chart otomatis update tanpa perlu reload!
```

### 3. **Kalori Hari Ini Display**
Ring chart menampilkan:
- ✅ **Target** (calculated from user profile)
- ✅ **Dikonsumsi** (summed from food_logs today)
- ✅ **Percentage** (consumed/target)
- ✅ **Sisa** (remaining to reach target)

---

## 📋 Setup Instructions

### Step 1: Enable Developer Mode (Windows)
```powershell
# Run as Administrator
start ms-settings:developers
```
→ Toggle "Developer Mode" ON

### Step 2: Create Food Logs Table (Supabase SQL)

Buka SQL Editor di Supabase dan jalankan:

```sql
-- Create food_logs table
CREATE TABLE food_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  food_name TEXT NOT NULL,
  calories INT NOT NULL DEFAULT 0,
  protein INT DEFAULT 0,
  carbs INT DEFAULT 0,
  fat INT DEFAULT 0,
  portion_size FLOAT DEFAULT 1.0,
  meal_type TEXT DEFAULT 'lunch',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own food logs" 
ON food_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own food logs" 
ON food_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own food logs" 
ON food_logs FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own food logs" 
ON food_logs FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_food_logs_user_id ON food_logs(user_id);
CREATE INDEX idx_food_logs_created_at ON food_logs(created_at);
```

### Step 3: Also Make Sure user_profiles Has target_calorie Column

```sql
-- Check if column exists, if not add it:
ALTER TABLE user_profiles ADD COLUMN target_calorie INT DEFAULT 2000;
```

### Step 4: Insert Test Data

Ganti `YOUR-USER-ID` dengan user ID dari Supabase Authentication:

```sql
-- Insert test food logs for today
INSERT INTO food_logs (user_id, food_name, calories, protein, carbs, fat, meal_type) 
VALUES 
  ('YOUR-USER-ID', 'Nasi Kuning', 250, 5, 45, 3, 'breakfast'),
  ('YOUR-USER-ID', 'Ayam Goreng', 300, 35, 10, 15, 'lunch'),
  ('YOUR-USER-ID', 'Tahu Goreng', 150, 15, 5, 8, 'lunch'),
  ('YOUR-USER-ID', 'Buah Pisang', 100, 1, 27, 0, 'snack');
```

### Step 5: Run App

```bash
cd d:\Android\flutter_application_1
flutter pub get
flutter clean
flutter run -d chrome
```

---

## 🔍 Expected Result

Setelah setup, user akan melihat:

```
┌─────────────────────────────┐
│    Total Kalori Hari Ini    │
│  Target: 2100 kal (badge)   │
│         ┌───────┐           │
│         │  40%  │ 📊        │
│         └───────┘           │
│  Dikonsumsi: 850 kal        │
│  Target: 2100 kal          │
│  Sisa: 1250 kal            │
└─────────────────────────────┘
```

**BONUS: Real-time Update**
- User buka form "Catat Makanan"
- Isi: "Mie Goreng" + 400 kal
- Klik Submit
- **POOF!** Ring chart langsung update ke 40% → 59% ✨

---

## 💻 Code Changes Summary

### File: `home_page.dart`
```dart
// NEW STATE VARIABLES
int _calorieToday = 0;                    // Total kalori hari ini
late StreamSubscription _foodLogsSubscription;

// NEW METHODS
_calculateTargetCalorie()                 // Auto-hitung target
_setupFoodLogsListener()                  // Realtime listener
_updateDailyCalories()                    // Update total kalori

// OVERRIDE
dispose()                                 // Cancel subscription
initState()                               // Setup listener + fetch
```

### File: `calorie_ring_card.dart`
```dart
// NEW DISPLAY
- Show "Target: {target} kal" badge di header
- Better visual hierarchy
- Permanent fixture, tidak hardcoded lagi
```

---

## 📊 Data Flow

```
User Login
   ↓
initState() runs
   ├─ _fetchUserProfile()
   │  ├ Get: age, weight, height, gender, activity_level
   │  └ Calculate: target_calorie = TDEE formula
   │     └ setState(_targetCalorie = calculated)
   │
   └─ _setupFoodLogsListener()
      ├ Stream from food_logs table
      └ Auto-update when food added/removed
         └ setState(_calorieToday = sum of calories)

UI Renders
   ├ CalorieRingCard(
   │   current: _calorieToday,
   │   target: _targetCalorie
   │ )
   └ Shows: percentage, consumed, target, remaining
```

---

## 🎯 Features Ready to Build Next

### 1. **"Catat Makanan" Button**
```dart
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => FoodTrackingPage())
  ),
  child: const Text('Catat Makanan'),
)
```

Form fields:
- Food name
- Calories
- Protein/Carbs/Fat breakdown
- Meal type (breakfast, lunch, dinner, snack)
- Portion size

Submit → Insert to `food_logs` → Real-time update ✨

### 2. **Food History**
Display list of food_logs:
- Filter by date
- Filter by meal type
- Edit/Delete options
- Statistics (avg daily intake, etc)

### 3. **Weekly Analytics**
- Line chart showing daily intake trends
- Compare to target
- Macro breakdown chart

### 4. **Notifications**
- Alert when reaching 80% target
- Reminder to log food
- Daily summary

---

## ⚠️ Important Notes

1. **Windows Developer Mode Required**
   - Symlink support needed untuk plugin
   - Run: `start ms-settings:developers`

2. **Supabase Realtime**
   - Only works if Realtime is enabled in Supabase
   - Check: Project Settings → Replication

3. **Time Zone**
   - Current implementation uses local time for "today"
   - For production, consider using UTC

4. **Performance**
   - Real-time listener runs on every change
   - Consider debouncing if many rapid updates

---

## ✨ Summary

✅ Target kalori **auto-calculated** dari profile user  
✅ Ring chart **real-time update** saat makanan ditambah  
✅ Database **setup ready** dengan RLS security  
✅ UI **shows target value** di card header  
✅ Full production code, **ready to use**  

**Next step:** Implement "Catat Makanan" form to complete the flow! 🚀
