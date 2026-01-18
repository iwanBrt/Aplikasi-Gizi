import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../../../../features/home/presentation/widgets/calorie_ring_card.dart';
import '../../../../features/home/presentation/widgets/macro_nutrient_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Ambil nama user dari Supabase (Metadata)
  final String _userName =
      Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
      'Teman';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background sedikit abu modern
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Halo, $_userName 👋",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              "Jaga pola makanmu hari ini!",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              // LOGOUT LOGIC
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),

      // --- BODY ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kartu Ring Kalori (Dummy Data: 850 dari 2000)
            const CalorieRingCard(current: 850, target: 2000),

            const SizedBox(height: 24),
            const Text(
              "Nutrisi Harian",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // 2. Baris Makro Nutrisi
            const MacroNutrientRow(),

            const SizedBox(height: 24),
            // 3. Tombol Aksi Cepat
            SizedBox(
              width: double.infinity, // Lebar penuh
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Buka halaman cari makanan
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Fitur Log Makanan segera hadir!"),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Catat Makanan (Sarapan)"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0, // Sedang di tab Home
        onDestinationSelected: (index) {
          // Nanti kita atur navigasi pindah tab di sini
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
