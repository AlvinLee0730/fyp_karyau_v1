import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Import your module files
import 'lost_and_found.dart';
import 'pet_adoption.dart';
import 'education.dart';
import 'expense_tracking.dart'; // IMPORT THE NEW MODULE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://zbmxmfnsqlkzguumlfip.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibXhtZm5zcWxremd1dW1sZmlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2NDc0NDUsImV4cCI6MjA4NDIyMzQ0NX0.c7esc22nznThDauT9wKUDvXHdSMZGqECyPFw6I4GQ4Y',
  );

  runApp(const PetCareApp());
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetCare Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "PetCare Hub",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Choose a service to get started",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              // 1. Lost & Found Module
              _buildMenuCard(
                context,
                title: "Lost & Found",
                subtitle: "Help reunite pets with their families",
                icon: Icons.search_rounded,
                color: Colors.orange.shade100,
                iconColor: Colors.orange.shade900,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LostAndFoundPage()),
                ),
              ),

              const SizedBox(height: 15),

              // 2. Pet Adoption Module
              _buildMenuCard(
                context,
                title: "Pet Adoption",
                subtitle: "Give a loving pet a forever home",
                icon: Icons.favorite_rounded,
                color: Colors.pink.shade50,
                iconColor: Colors.pink.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PetAdoptionPage()),
                ),
              ),

              const SizedBox(height: 15),

              // 3. Pet Education Module
              _buildMenuCard(
                context,
                title: "Pet Education",
                subtitle: "Learn how to care for your furry friends",
                icon: Icons.menu_book_rounded,
                color: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EducationPage()),
                ),
              ),

              const SizedBox(height: 15),

              // 4. ADDED: Expense Tracking Module
              _buildMenuCard(
                context,
                title: "Expense Tracker",
                subtitle: "Manage your pet spending & budget",
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green.shade50,
                iconColor: Colors.green.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseTrackingPage()),
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "All reports are updated in real-time. Check back often for new updates!",
                        style: TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Color iconColor,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: iconColor.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: iconColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}