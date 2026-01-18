# Setup Database Supabase

## Tabel: user_profiles

Buat tabel `user_profiles` di Supabase dengan struktur berikut:

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

-- Buat index untuk performa
CREATE INDEX idx_user_profiles_id ON user_profiles(id);

-- Enable RLS (Row Level Security)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy untuk read: user hanya bisa lihat profil mereka sendiri
CREATE POLICY "Users can view own profile"
  ON user_profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Policy untuk update: user hanya bisa update profil mereka sendiri
CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Policy untuk insert: user hanya bisa insert profil mereka sendiri
CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);
```

## Tabel: daily_meals (optional untuk fitur log makanan)

```sql
CREATE TABLE daily_meals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  meal_name TEXT NOT NULL,
  calories INT NOT NULL,
  protein INT,
  carbs INT,
  fat INT,
  meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  meal_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_daily_meals_user_id ON daily_meals(user_id);
CREATE INDEX idx_daily_meals_date ON daily_meals(meal_date);

ALTER TABLE daily_meals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own meals"
  ON daily_meals
  FOR SELECT
  USING (auth.uid() = user_id);
```

## Langkah-langkah Setup:

1. Login ke Supabase Console
2. Buka project Anda
3. Ke tab "SQL Editor"
4. Paste queries di atas (satu per satu atau sekaligus)
5. Run queries
6. Pastikan table berhasil dibuat dengan melihat tab "Tables"

## Isi data test (opsional):

Untuk testing, buat entry profil untuk user Anda dengan:
- Ganti `'USER_ID_ANDA'` dengan actual user ID dari auth.users
- Sesuaikan target_calorie sesuai kebutuhan

```sql
INSERT INTO user_profiles (id, full_name, target_calorie, age, gender, height, weight, activity_level)
VALUES (
  'USER_ID_ANDA',
  'Nama Lengkap',
  2500,
  25,
  'male',
  175,
  70,
  'moderate'
);
```
