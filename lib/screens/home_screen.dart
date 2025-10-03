import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/role_service.dart';
import 'admin_screen.dart';
import 'directory_screen.dart';
import 'home_dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasAdminAccess = false;
  bool _isLoading = true;
  final GlobalKey<DirectoryScreenState> _directoryKey = GlobalKey<DirectoryScreenState>();

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
        HomeDashboardScreen(onGroupSelected: _handleGroupSelected),
        DirectoryScreen(key: _directoryKey),
        const ProfileScreen(),
        const AdminScreen(),
      ];
    } else {
      return [
        HomeDashboardScreen(onGroupSelected: _handleGroupSelected),
        DirectoryScreen(key: _directoryKey),
        const ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_hasAdminAccess) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Home',
        ),
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
          icon: Icon(Icons.home_filled),
          label: 'Home',
        ),
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
    if (_selectedIndex == 0) return 'Home';
    if (_selectedIndex == 1) return 'Directory';
    if (_selectedIndex == 2) return 'My Profile';
    if (_selectedIndex == 3 && _hasAdminAccess) return 'Admin';
    return 'NDC95';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleGroupSelected(String group) {
    setState(() {
      _selectedIndex = 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _directoryKey.currentState?.applyGroupFilter(group);
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
