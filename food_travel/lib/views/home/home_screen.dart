import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../router/route_names.dart';
import '../personal/personal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome to FoodG Travel!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('You are signed in.'),
        ],
      ),
    ),
    Center(child: Text('Kham pha')),
    Center(child: Text('Cong thuc')),
    Center(child: Text('Luu')),
    PersonalPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    final showAppBar = _currentIndex != 4;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person) : null,
                ),
              ),
              title: const Text('FoodG Travel'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AuthService().logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                      (_) => false,
                    );
                  },
                  tooltip: 'Logout',
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B0F1A),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFF8A8F9A),
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Kham pha',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Cong thuc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Luu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Toi',
          ),
        ],
      ),
    );
  }
}
