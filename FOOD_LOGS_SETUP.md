# Setup Food Logs Table untuk Real-time Tracking

Buka **SQL Editor** di Supabase dan jalankan SQL berikut untuk membuat tabel food_logs:

## 1. Create Food Logs Table

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
  meal_type TEXT DEFAULT 'lunch', -- breakfast, lunch, dinner, snack
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own food logs
CREATE POLICY "Users can view own food logs" 
ON food_logs 
FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Users can insert their own food logs
CREATE POLICY "Users can insert own food logs" 
ON food_logs 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own food logs
CREATE POLICY "Users can update own food logs" 
ON food_logs 
FOR UPDATE 
USING (auth.uid() = user_id);

-- Policy: Users can delete their own food logs
CREATE POLICY "Users can delete own food logs" 
ON food_logs 
FOR DELETE 
USING (auth.uid() = user_id);

-- Create index untuk performance
CREATE INDEX idx_food_logs_user_id ON food_logs(user_id);
CREATE INDEX idx_food_logs_created_at ON food_logs(created_at);
```

## 2. Insert Test Data

Ganti `YOUR-USER-ID` dengan user ID Anda (dari Supabase Authentication):

```sql
-- Insert test food logs for today
INSERT INTO food_logs (user_id, food_name, calories, protein, carbs, fat, meal_type) 
VALUES 
  ('YOUR-USER-ID', 'Nasi Kuning', 250, 5, 45, 3, 'breakfast'),
  ('YOUR-USER-ID', 'Ayam Goreng', 300, 35, 10, 15, 'lunch'),
  ('YOUR-USER-ID', 'Tahu Goreng', 150, 15, 5, 8, 'lunch'),
  ('YOUR-USER-ID', 'Buah Pisang', 100, 1, 27, 0, 'snack');
```

## 3. Verify Setup

Setelah menjalankan SQL:
1. Cek tabel `food_logs` muncul di Table list
2. Lihat data yang sudah diinsert
3. Refresh app di browser

## Expected Result

✅ Total kalori hari ini akan menampilkan **800 kal** (250 + 300 + 150 + 100)
✅ Ring chart akan update secara **real-time** ketika ada makanan baru ditambahkan
✅ Percentage akan otomatis terhitung dari total kalori

## Fitur Real-time Tracking

Sekarang app sudah support:
- ✅ **Mendengarkan perubahan** di table food_logs menggunakan Realtime Supabase
- ✅ **Auto update** ketika ada makanan baru ditambahkan (tanpa reload)
- ✅ **Kalkulasi otomatis** total kalori hari ini
- ✅ **Percentage tracking** berdasarkan target yang dipersonalisasi

## Next Steps

Untuk menambah makanan:
1. User klik button "Catat Makanan"
2. Isi form dengan nama makanan, kalori, protein, carbs, fat
3. Submit → data masuk ke `food_logs` table
4. Ring chart **auto update** secara real-time 🚀
