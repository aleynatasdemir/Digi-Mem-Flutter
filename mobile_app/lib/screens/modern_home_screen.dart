import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import 'modern_dashboard_screen.dart';
import 'archives_screen.dart';
import 'summaries_screen.dart';
import 'profile_screen.dart';
import 'add_memory_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({Key? key}) : super(key: key);

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemoryService>(context, listen: false).fetchMemories();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openQuickAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMemoryScreen(initialType: 'TEXT'),
      ),
    );
    if (result == true) {
      Provider.of<MemoryService>(context, listen: false).fetchMemories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ModernDashboardScreen(),
      const ArchivesScreen(),
      const SummariesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      extendBody: false,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFdad3e4).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(
              Colors.white.withOpacity(0.8),
              BlendMode.srcOver,
            ),
            child: Container(
              padding: const EdgeInsets.only(bottom: 20, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    icon: Icons.home,
                    label: 'Ana Sayfa',
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  _NavBarItem(
                    icon: Icons.archive,
                    label: 'Arşiv',
                    isSelected: _selectedIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  _NavBarItem(
                    icon: Icons.analytics,
                    label: 'Özet',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  _NavBarItem(
                    icon: Icons.person,
                    label: 'Profil',
                    isSelected: _selectedIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF7b3fcf)
                  : const Color(0xFF141019).withOpacity(0.4),
              size: 24,
              weight: isSelected ? 1.0 : 0.5,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF7b3fcf)
                    : const Color(0xFF141019).withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
