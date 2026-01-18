# 🧪 Test Credentials & Sample Data

## Test User Data

Untuk testing, gunakan data berikut (setelah sign up):

### Test User 1: Standard Target (2000 cal)
```
Email: test1@example.com
Password: Test123!@#
Name: Test User 1
Target Calorie: 2000
Age: 25
Gender: Male
Height: 175 cm
Weight: 70 kg
```

**SQL Insert:**
```sql
-- Setelah user sign up, copy user ID dan run ini:
INSERT INTO user_profiles 
(id, full_name, target_calorie, age, gender, height, weight, activity_level)
VALUES 
('PASTE_USER_ID_HERE', 'Test User 1', 2000, 25, 'male', 175, 70, 'moderate');
```

---

### Test User 2: High Target (2800 cal)
```
Email: test2@example.com
Password: Test123!@#
Name: Test User 2
Target Calorie: 2800
Age: 30
Gender: Male
Height: 180 cm
Weight: 80 kg
```

**SQL Insert:**
```sql
INSERT INTO user_profiles 
(id, full_name, target_calorie, age, gender, height, weight, activity_level)
VALUES 
('PASTE_USER_ID_HERE', 'Test User 2', 2800, 30, 'male', 180, 80, 'active');
```

---

### Test User 3: Low Target (1600 cal)
```
Email: test3@example.com
Password: Test123!@#
Name: Test User 3
Target Calorie: 1600
Age: 22
Gender: Female
Height: 160 cm
Weight: 55 kg
```

**SQL Insert:**
```sql
INSERT INTO user_profiles 
(id, full_name, target_calorie, age, gender, height, weight, activity_level)
VALUES 
('PASTE_USER_ID_HERE', 'Test User 3', 1600, 22, 'female', 160, 55, 'light');
```

---

## Testing Scenarios

### Scenario 1: Happy Path (Profile Exists)

**Setup:**
1. Sign up dengan email: test1@example.com
2. Copy user ID dari Supabase → Authentication → Users
3. Insert test data untuk user tersebut

**Expected:**
```
Loading spinner → Fetch data → Ring chart shows 2000 cal
```

**Verification:**
- [ ] Loading spinner visible
- [ ] Ring chart updates after 1-2 seconds
- [ ] No error message
- [ ] Percentage shows: 850/2000 = 42%

---

### Scenario 2: Profile Not Found

**Setup:**
1. Sign up dengan email baru: testnew@example.com
2. Jangan insert data ke user_profiles

**Expected:**
```
Loading spinner → Fetch fails → Error message with "Coba Lagi" button
```

**Verification:**
- [ ] Loading spinner visible
- [ ] Error card appears
- [ ] Error message readable
- [ ] Retry button clickable
- [ ] Fallback to 2000 cal

---

### Scenario 3: Network Error Simulation

**Setup:**
1. Sign up & insert profile
2. Run app
3. Disable internet sebelum loading selesai

**Expected:**
```
Loading spinner → Network timeout → Error message
```

**Verification:**
- [ ] Error message appears
- [ ] Retry button works
- [ ] After re-connecting internet & clicking retry → success

---

## Quick Copy-Paste Setup

### All-in-One Setup SQL

```sql
-- Run di Supabase SQL Editor

-- 1. Create table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  target_calorie INT DEFAULT 2000,
  age INT,
  gender TEXT,
  height INT,
  weight INT,
  activity_level TEXT DEFAULT 'moderate',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Create index
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON user_profiles(id);

-- 3. Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create policies
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
```

## Finding User ID in Supabase

### Method 1: From Supabase Console
1. Go to https://app.supabase.com
2. Select your project
3. Click "Authentication" → "Users"
4. Copy the user ID (looks like: 550e8400-e29b-41d4-a716-446655440000)

### Method 2: From App Console
```dart
// Add this line in home_page.dart build() method temporarily
print('User ID: ${Supabase.instance.client.auth.currentUser?.id}');

// Check Flutter console output
// Copy the ID and use it in SQL
```

### Method 3: From Browser DevTools
```javascript
// Open browser DevTools → Console (F12)
// If user is logged in:
console.log(JSON.parse(localStorage.getItem('supabase.auth.token')));
// User ID akan terlihat di JWT payload
```

---

## Batch Test SQL (For Multiple Users)

Jika ingin test dengan beberapa user sekaligus, siapkan user IDs dulu:

```sql
-- Replace dengan user IDs Anda
INSERT INTO user_profiles 
(id, full_name, target_calorie, age, gender, height, weight, activity_level)
VALUES 
('USER_ID_1', 'Test User 1', 2000, 25, 'male', 175, 70, 'moderate'),
('USER_ID_2', 'Test User 2', 2800, 30, 'male', 180, 80, 'active'),
('USER_ID_3', 'Test User 3', 1600, 22, 'female', 160, 55, 'light');
```

---

## Expected Ring Chart Percentages

Dengan current calorie = 850:

| Target | Percentage | Status |
|--------|-----------|--------|
| 1600 | 53% | Good |
| 1800 | 47% | Good |
| 2000 | 42% | Good |
| 2500 | 34% | Good |
| 2800 | 30% | Good |

---

## Debug Output Expected

Saat fetch berhasil, console harus menampilkan:
```
I/flutter (12345): User ID: 550e8400-e29b-41d4-a716-446655440000
I/flutter (12345): Fetched target calorie: 2000
```

Saat ada error:
```
I/flutter (12345): Error fetching profile: PostgrestException(...)
I/flutter (12345): Setting error state
```

---

## Helpful Commands

### Run app dengan verbose logging
```bash
flutter run -d chrome -v
```

### Clear app data & restart
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Check Supabase logs
1. Go to Supabase Console
2. Click "Logs" → "API Logs"
3. Filter by your queries
4. Check success/failure

---

**Tips:** 
- Jangan share user credentials di public repo
- Use environment variables untuk production
- Test semua 3 scenarios sebelum production
