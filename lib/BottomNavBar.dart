import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'message.dart';

class BottomNavBar extends StatefulWidget {
  final String currentUserId;
  const BottomNavBar({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  final List<Map<String, dynamic>> _navItems = [
    {'icon': LucideIcons.messageSquare, 'label': 'Chat'},
    {'icon': LucideIcons.users, 'label': 'Communities'},
    {'icon': LucideIcons.calendar, 'label': 'Calendar'},
    {'icon': LucideIcons.bell, 'label': 'Activity'},
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      MessageScreen(currentUserId: widget.currentUserId),
      const Placeholder(color: Colors.green),
      const Placeholder(color: Colors.blue),
      const Placeholder(color: Colors.orange),
    ];
  }

  Widget _buildSideNavItem(int index) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Tooltip(
        message: _navItems[index]['label'],
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 10),
        child: GestureDetector(
          onTap: () => setState(() => _currentIndex = index),
          child: Container(
            width: 30,
            height: 30,
            child: Icon(
              _navItems[index]['icon'],
              size: 18,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Container(
            width: 60,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_navItems.length, (index) => _buildSideNavItem(index)),
            ),
          ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          iconSize: 22,
          selectedLabelStyle: const TextStyle(fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.messageSquare),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.users),
              label: 'Communities',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calendar),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bell),
              label: 'Activity',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth > 800 ? _buildWebLayout() : _buildMobileLayout();
      },
    );
  }
}
