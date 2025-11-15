import 'package:flutter/material.dart';
import 'package:pyqachu/features/home/screens/search_page.dart';
import 'package:pyqachu/features/bookmark/screens/bookmark_page.dart';
import 'package:pyqachu/features/profile/screens/profile_page.dart';
import 'package:pyqachu/features/moderation/screens/moderation_page.dart';
import 'package:pyqachu/core/services/auth_service.dart';
import 'package:pyqachu/core/services/api_service.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isModerator = false;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkModeratorStatus();
  }

  Future<void> _checkModeratorStatus() async {
    print('=== CHECKING MODERATOR STATUS ===');
    
    final user = await AuthService.getUser();
    print('Current user data: $user');
    
    final token = await AuthService.getToken();
    print('Auth token available: ${token != null ? "YES" : "NO"}');
    
    if (token != null) {
      // Also check via API call
      final isModerator = await ApiService.isModerator();
      print('API isModerator result: $isModerator');
      
      setState(() {
        _isModerator = isModerator;
        _setupNavigationItems();
        _pageController = PageController(initialPage: widget.initialIndex);
      });
    } else {
      print('No auth token - user not logged in');
      setState(() {
        _isModerator = false;
        _setupNavigationItems();
        _pageController = PageController(initialPage: widget.initialIndex);
      });
    }
    
    print('Final moderator status: $_isModerator');
    print('=== END MODERATOR CHECK ===');
  }

  void _setupNavigationItems() {
    _pages = [
      const SearchPage(),
      const BookmarkPage(),
      if (_isModerator) const ModerationPage(),
      const ProfilePage(),
    ];

    _navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bookmark_outline),
        activeIcon: Icon(Icons.bookmark),
        label: 'Bookmark',
      ),
      if (_isModerator)
        const BottomNavigationBarItem(
          icon: Icon(Icons.gavel_outlined),
          activeIcon: Icon(Icons.gavel),
          label: 'Moderate',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      // Show loading while checking moderator status
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: _navItems,
        ),
      ),
    );
  }
}