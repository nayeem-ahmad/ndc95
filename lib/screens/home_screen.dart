import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/role_service.dart';
import 'directory_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasAdminAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    // Check if user is superadmin by email (backward compatibility)
    if (_isSuperAdmin()) {
      setState(() {
        _hasAdminAccess = true;
        _isLoading = false;
      });
      return;
    }
    
    // Check role-based access
    final hasAccess = await RoleService.isGroupAdmin();
    setState(() {
      _hasAdminAccess = hasAccess;
      _isLoading = false;
    });
  }

  bool _isSuperAdmin() {
    final user = FirebaseService.currentUser;
    return user?.email?.toLowerCase() == 'nayeem.ahmad@gmail.com';
  }

  List<Widget> _getScreens() {
    if (_hasAdminAccess) {
      return [
        const DirectoryScreen(),
        const ProfileScreen(),
        const AdminScreen(),
      ];
    } else {
      return [
        const DirectoryScreen(),
        const ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_hasAdminAccess) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Directory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Directory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Profile',
        ),
      ];
    }
  }

  String _getAppBarTitle() {
    if (_selectedIndex == 0) return 'Directory';
    if (_selectedIndex == 1) return 'My Profile';
    if (_selectedIndex == 2 && _hasAdminAccess) return 'Admin';
    return 'NDC95';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = _getScreens();
    final navItems = _getNavItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
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
          // Show update role button on Profile tab (for first-time setup)
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.of(context).pushNamed('/update-role');
              },
              tooltip: 'Update Role (One-time Setup)',
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
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700,
        onTap: _onItemTapped,
      ),
    );
  }
}
