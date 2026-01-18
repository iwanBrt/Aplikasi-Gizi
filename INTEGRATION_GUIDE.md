# Integrasi Data Profil Real-time dari Supabase

## 📋 Ringkasan Perubahan

Telah mengintegrasikan pengambilan data target kalori asli dari database Supabase ke dalam HomePage, menggantikan hardcoded value (2000) dengan data dinamis dari profil pengguna.

## 🔄 Alur Kerja

```
User Login → HomePage Load → initState → Fetch User Profile → Update UI
                                            ↓
                                  Ambil target_calorie dari DB
                                  Update _targetCalorie state
                                  Update CalorieRingCard dengan nilai real
```

## 📝 Perubahan Kode

### 1. Variabel State Baru di `_HomePageState`

```dart
// Data profil dari Supabase
int _targetCalorie = 2000; // Default value
bool _isLoadingProfile = true;
String? _errorMessage;
```

**Penjelasan:**
- `_targetCalorie`: Menyimpan target kalori dari database
- `_isLoadingProfile`: Flag untuk menampilkan loading state
- `_errorMessage`: Menyimpan pesan error jika fetch gagal

### 2. Lifecycle Method: `initState()`

```dart
@override
void initState() {
  super.initState();
  _fetchUserProfile();
}
```

Dipanggil saat HomePage pertama kali dirender untuk fetch data profil.

### 3. Fungsi: `_fetchUserProfile()`

```dart
Future<void> _fetchUserProfile() async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) {
      // Handle: user tidak terdeteksi
      setState(() {
        _errorMessage = 'User tidak ditemukan';
        _isLoadingProfile = false;
      });
      return;
    }

    // Query ke table user_profiles
    final response = await Supabase.instance.client
        .from('user_profiles')
        .select('target_calorie')
        .eq('id', userId)
        .single();

    if (mounted) {
      setState(() {
        _targetCalorie = response['target_calorie'] ?? 2000;
        _isLoadingProfile = false;
      });
    }
  } catch (e) {
    // Handle error dengan graceful fallback
    if (mounted) {
      setState(() {
        _errorMessage = 'Gagal mengambil data profil';
        _isLoadingProfile = false;
        _targetCalorie = 2000; // Gunakan default
      });
    }
    print('Error fetching profile: $e');
  }
}
```

**Fitur:**
- ✅ Mengambil user ID dari auth session Supabase
- ✅ Query ke tabel `user_profiles` berdasarkan ID user
- ✅ Update state dengan data yang diterima
- ✅ Fallback ke 2000 jika ada error
- ✅ Loading indicator saat fetch sedang berjalan
- ✅ Error message jika fetch gagal dengan tombol retry

### 4. UI State Handling di `build()`

**Loading State:**
```dart
_isLoadingProfile
    ? Card(
        // Loading indicator
        child: CircularProgressIndicator()
      )
```

**Error State:**
```dart
: _errorMessage != null
    ? Card(
        // Warning icon + error message
        // Tombol "Coba Lagi" untuk retry
      )
```

**Success State:**
```dart
: CalorieRingCard(
    current: 850,
    target: _targetCalorie, // ✅ Nilai real dari DB
  )
```

## 🗄️ Schema Database Supabase

**Tabel: `user_profiles`**

| Column | Type | Deskripsi |
|--------|------|-----------|
| `id` | UUID | Foreign key ke auth.users (PK) |
| `full_name` | TEXT | Nama lengkap pengguna |
| `target_calorie` | INT | Target kalori harian (default: 2000) |
| `age` | INT | Usia pengguna |
| `gender` | TEXT | Jenis kelamin |
| `height` | INT | Tinggi badan (cm) |
| `weight` | INT | Berat badan (kg) |
| `activity_level` | TEXT | Level aktivitas |
| `created_at` | TIMESTAMP | Waktu pembuatan |
| `updated_at` | TIMESTAMP | Waktu update terakhir |

### SQL Setup (Jalankan di Supabase Console)

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  target_calorie INT DEFAULT 2000,
  age INT,
  gender TEXT,
  height INT COMMENT 'dalam cm',
  weight INT COMMENT 'dalam kg',
  activity_level TEXT DEFAULT 'moderate',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: User hanya bisa lihat profil sendiri
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

-- Policy: User hanya bisa update profil sendiri
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);
```

## ✅ Testing

### Test Case 1: Happy Path (Success)
1. User sudah punya profil di `user_profiles`
2. `_isLoadingProfile = true` → tampilkan loading
3. Fetch berhasil → update `_targetCalorie`
4. `_isLoadingProfile = false` → tampilkan CalorieRingCard dengan nilai real

### Test Case 2: First Time User (No Profile Yet)
1. User baru, belum ada di `user_profiles`
2. Query akan throw error
3. Catch error → tampilkan error message
4. User klik "Coba Lagi" untuk retry, atau set profil dulu

### Test Case 3: Network Error
1. User offline atau koneksi jelek
2. Catch error → fallback ke 2000
3. Tampilkan error message dengan tombol retry

## 🚀 Langkah Selanjutnya (Rekomendasi)

1. **Create User Profile Screen**
   - Form untuk input target kalori, height, weight, dll
   - Hitung BMR (Basal Metabolic Rate) otomatis
   - Save ke Supabase saat pertama kali login

2. **Daily Calorie Tracking**
   - Fetch data kalori yang dikonsumsi dari `daily_meals`
   - Update `current` di CalorieRingCard secara real-time

3. **Real-time Updates**
   - Gunakan Supabase Realtime untuk subscribe ke perubahan profil
   - Jika user update target kalori, UI langsung update

4. **Macronutrient Real-time**
   - Fetch data makro (protein, carbs, fat) dari Supabase
   - Sesuaikan dengan target di profil

5. **Error Handling Enhancement**
   - Retry logic dengan exponential backoff
   - Toast notification untuk error
   - Offline mode dengan local cache

## 📚 Code References

**File yang dimodifikasi:**
- `lib/features/home/presentation/pages/home_page.dart`

**Widget yang bergantung:**
- `CalorieRingCard` (menerima `target` parameter dinamis)
- `MacroNutrientRow` (siap untuk integrasi)
- `_buildWaterTracker` (independen)

**Dependencies:**
- `supabase_flutter` (sudah ada di pubspec.yaml)

## 🔒 Security Notes

- ✅ RLS policies sudah mengamankan data (user hanya bisa akses profil sendiri)
- ✅ User ID diambil dari `auth.currentUser` (verified)
- ✅ Error message tidak membuka data sensitif
- ✅ Mounted check sebelum setState (prevent memory leak)
