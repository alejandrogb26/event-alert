import 'package:flutter/material.dart';

import '../features/alerts/presentation/screens/alerts_screen.dart';
import '../features/events/presentation/screens/events_calendar_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // IndexedStack mantiene el árbol de widgets de cada pestaña vivo,
  // por lo que el scroll y el estado se conservan al cambiar de destino.
  static const List<Widget> _screens = [AlertsScreen(), EventsCalendarScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Eventos',
          ),
        ],
      ),
    );
  }
}
