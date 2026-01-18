# ✅ Setup Checklist - Real-time Data Integration

## 📋 Pre-Implementation Checklist

- [x] Code structure ready
- [x] Supabase integration working
- [x] No compilation errors
- [ ] Database created in Supabase ← **NEXT STEP**
- [ ] Test data inserted
- [ ] App tested

## 🔧 Supabase Setup Steps

### Step 1: Create Table (Copy-paste ke SQL Editor)

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

-- Index untuk query
CREATE INDEX idx_user_profiles_id ON user_profiles(id);

-- Enable security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Read own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

-- RLS Policy: Update own profile  
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- RLS Policy: Insert own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

**Cara Menjalankan:**
1. Login ke https://app.supabase.com
2. Pilih project Anda
3. Buka tab "SQL Editor" (sebelah kiri)
4. Klik "New Query"
5. Copy-paste SQL di atas
6. Klik "Run"
7. Seharusnya muncul ✅ success

### Step 2: Insert Test Data

Ganti `'USER_ID_ANDA'` dengan actual user ID. Untuk mencarinya:
1. Buka tab "Authentication" → "Users"
2. Copy user ID yang ditampilkan

```sql
INSERT INTO user_profiles 
(id, full_name, target_calorie, age, gender, height, weight, activity_level)
VALUES 
('USER_ID_ANDA', 'Nama Lengkap', 2500, 25, 'male', 175, 70, 'moderate');
```

### Step 3: Verify Table Created

1. Buka tab "Tables" (di sebelah "Authentication")
2. Seharusnya ada tabel baru: `user_profiles`
3. Lihat columns: id, full_name, target_calorie, dll
4. Check data dengan klik tabel → lihat rows

## 🧪 Testing Steps

### Test 1: App dengan Data

**Prerequisites:**
- User sudah sign up / login
- Data di user_profiles sudah ada

**Expected Behavior:**
1. App load → loading spinner di ring chart
2. Data fetched dari Supabase
3. Ring chart menampilkan target_calorie dari DB
4. Tidak ada error message

**Testing:**
```bash
flutter run -d chrome
# Login dengan akun yang punya data
# Tunggu loading selesai
# Lihat apakah ring chart update dengan angka dari DB
```

### Test 2: Error Handling (No Profile)

**Setup:**
- Login dengan akun baru yang belum di user_profiles

**Expected Behavior:**
1. App load → loading spinner
2. Fetch gagal (user tidak ada di DB)
3. Tampil error message: "Gagal mengambil data profil"
4. Tombol "Coba Lagi"
5. App tetap berjalan dengan fallback 2000

**Testing:**
```bash
# Login dengan akun baru
# Tunggu loading
# Lihat error message
# Klik "Coba Lagi" (akan error lagi karena tidak ada data)
```

### Test 3: Network Error

**Setup:**
- Disconnect internet sebelum fetch dimulai

**Expected Behavior:**
1. Loading spinner muncul
2. Network timeout → error message
3. Tombol "Coba Lagi"
4. Klik retry setelah internet connect → berhasil

**Testing:**
```bash
flutter run -d chrome
# Putuskan internet sebelum app load selesai
# Tunggu timeout → error message
# Connect internet kembali
# Klik "Coba Lagi"
# Seharusnya berhasil fetch
```

### Test 4: Different Target Values

**Setup:**
- Insert multiple users dengan target_calorie berbeda

```sql
-- User 1: target 2000
INSERT INTO user_profiles (id, full_name, target_calorie)
VALUES ('USER_ID_1', 'User Test 1', 2000);

-- User 2: target 2500
INSERT INTO user_profiles (id, full_name, target_calorie)
VALUES ('USER_ID_2', 'User Test 2', 2500);

-- User 3: target 1800
INSERT INTO user_profiles (id, full_name, target_calorie)
VALUES ('USER_ID_3', 'User Test 3', 1800);
```

**Testing:**
- Login dengan User 1 → ring chart menunjukkan 2000 sebagai target
- Logout, login dengan User 2 → ring chart menunjukkan 2500 sebagai target
- Logout, login dengan User 3 → ring chart menunjukkan 1800 sebagai target

## 📊 Debugging Tips

Jika ada masalah, check ini:

### 1. Check User ID
```dart
// Di console Dart
final userId = Supabase.instance.client.auth.currentUser?.id;
print('User ID: $userId');
```

### 2. Check Database Query
Langsung test di Supabase SQL Editor:
```sql
SELECT * FROM user_profiles WHERE id = 'USER_ID_ANDA';
```

### 3. Check RLS Policies
Jika query berhasil di SQL Editor tapi gagal di app, berarti RLS policy issue:
```sql
-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'user_profiles';
```

### 4. Check App Logs
Look for error message di Flutter console:
```
Error fetching profile: ...
```

## 🎯 Success Criteria

✅ Semua test pass jika:

- [ ] Database table created
- [ ] RLS policies enabled
- [ ] Test data inserted
- [ ] App fetch data successfully
- [ ] Ring chart shows real target_calorie
- [ ] Loading spinner works
- [ ] Error message works
- [ ] Retry button works
- [ ] Multiple users dengan different targets tested
- [ ] No console errors
- [ ] No compilation warnings

## 🚀 After Testing

Jika semua test pass, langkah berikutnya:

1. ✅ Buat UI untuk "Setup Profil" (onboarding)
2. ✅ Add meal tracking (daily_meals table)
3. ✅ Real-time updates dengan Supabase Realtime
4. ✅ Weekly/monthly statistics

---

**Status:** Ready for setup ✨

Mulai dari Step 1 di atas untuk complete integration!
