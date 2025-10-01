import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'directory_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DirectoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _isSuperAdmin() {
    final user = FirebaseService.currentUser;
    return user?.email?.toLowerCase() == 'nayeem.ahmad@gmail.com';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Directory' : 'My Profile'),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Show admin import button only for super admin on Profile tab
          if (_selectedIndex == 1 && _isSuperAdmin())
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () {
                Navigator.of(context).pushNamed('/admin-import');
              },
              tooltip: 'Import CSV Data',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Directory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700,
        onTap: _onItemTapped,
      ),
    );
  }
}
