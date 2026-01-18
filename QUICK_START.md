# 🚀 QUICK REFERENCE CARD

## Integrasi Data Profil Real-time - Langkah Cepat

---

## ⚡ 5-Menit Setup

### 1. Database (Supabase Console)
Copy-paste ke SQL Editor:
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  target_calorie INT DEFAULT 2000,
  age INT, gender TEXT, height INT, weight INT,
  activity_level TEXT DEFAULT 'moderate',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_user_profiles_id ON user_profiles(id);
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
```

### 2. Insert Test Data
```sql
INSERT INTO user_profiles (id, full_name, target_calorie, age, gender, height, weight)
VALUES ('YOUR_USER_ID', 'Test User', 2500, 25, 'male', 175, 70);
```

### 3. Run App
```bash
flutter run -d chrome
```

### 4. Expected Result
- Spinner → Real data fetched → Ring chart updates ✅

---

## 📂 Key Files

| File | Purpose |
|------|---------|
| `home_page.dart` | Main implementation |
| `user_profile_service.dart` | Optional helper service |
| `INTEGRATION_GUIDE.md` | Complete guide |
| `SETUP_CHECKLIST.md` | Setup & testing |
| `TEST_DATA.md` | Test scenarios |
| `DATABASE_SETUP.md` | SQL scripts |

---

## 🔍 Key Code Changes

### In `home_page.dart`:

```dart
// Added state variables
int _targetCalorie = 2000;
bool _isLoadingProfile = true;
String? _errorMessage;

// Added in initState()
void initState() {
  super.initState();
  _fetchUserProfile();
}

// Added method
Future<void> _fetchUserProfile() async {
  // Fetch from Supabase
  // Update state
}

// Updated CalorieRingCard
CalorieRingCard(
  current: 850,
  target: _targetCalorie,  // ← Dynamic!
)
```

---

## 🧪 Testing

### Test 1: Happy Path
```
Login → Load → Spinner → Data fetched → Ring updates ✅
```

### Test 2: Error
```
Login (no profile) → Spinner → Error message → Retry button ✅
```

### Test 3: Different Targets
```
User A (2000 cal) → User B (2800 cal) → Values different ✅
```

---

## ❌ Troubleshooting

| Problem | Solution |
|---------|----------|
| Query fails | Check table created in Supabase |
| Returns null | Insert test data |
| RLS error | Check policies created |
| App doesn't update | Check mounted check in code |
| Still shows 2000 | Verify _targetCalorie passed to widget |

---

## 📋 Minimal Checklist

- [ ] Run SQL setup
- [ ] Insert test data
- [ ] Run app
- [ ] Check ring chart updates
- [ ] Try error scenario
- [ ] Check retry works
- [ ] ✅ Done!

---

## 🎯 Success Indicators

✅ App loads → spinner shows  
✅ Data fetches → spinner disappears  
✅ Ring chart shows target from DB  
✅ Error handling works  
✅ Different users → different targets  

---

## 📊 Data in UI

```
Current: 850 cal
Target: [FROM DATABASE] ← This changed!
Ring %: 850/target * 100

Before: Always 850/2000 = 42%
After:  850/2500 = 34% (or whatever target is)
```

---

## 🔐 Security Verified

✅ RLS policies enabled
✅ User ID from auth
✅ No sensitive data exposed
✅ Error handling graceful

---

## 📞 Need Help?

1. Read `INTEGRATION_GUIDE.md` (detailed)
2. Check `SETUP_CHECKLIST.md` (step-by-step)
3. Verify `TEST_DATA.md` (sample data)
4. Check SQL in `DATABASE_SETUP.md` (queries)

---

**Status**: ✅ READY TO GO! 🎉

Follow the 5-minute setup above and test!
