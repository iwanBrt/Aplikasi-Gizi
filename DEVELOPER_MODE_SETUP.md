# ⚙️ Enable Developer Mode - Windows Setup

## Step 1: Open Settings
Jendela Settings seharusnya sudah terbuka. Jika tidak, buka manual:
```
Windows Key + I
```

## Step 2: Find Developer Mode
Di Settings, pilih **"Update & Security"** (atau **"System"** tergantung Windows version)

Cari tab **"For developers"**

## Step 3: Toggle Developer Mode ON
Klik toggle untuk **"Developer Mode"** 

Expected:
```
☑️ Developer Mode (ON)
```

## Step 4: Windows Akan Setup
Tunggu proses selesai (bisa 1-2 menit). Jangan tutup windows.

Akan ada notifikasi:
```
✅ Developer Mode is ready for use
```

---

## Step 5: Restart Terminal & Run App

Setelah Developer Mode enabled, buka terminal baru dan jalankan:

```powershell
cd d:\Android\flutter_application_1
flutter clean
flutter run -d chrome
```

---

## ⏱️ Expected Timeline

1. Settings terbuka: 2 detik
2. Find Developer Mode: 10 detik  
3. Toggle ON: 5 detik
4. Setup process: 1-2 menit
5. Terminal ready: 30 detik

**Total: ~4 menit**

---

## ✅ Success Signs

Ketika app berhasil run, terminal akan show:

```
Launching lib\main.dart on Chrome in debug mode...
✓ Build succeeded!

Launching lib\main.dart...
✓ Connected...
```

Browser Chrome akan membuka dengan app running ✨

---

**Let me know once Developer Mode is enabled!** 🎯
