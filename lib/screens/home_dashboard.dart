import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicine_reminder_app/providers/auth_provider.dart';
import 'package:medicine_reminder_app/providers/medicine_provider.dart';
import 'package:medicine_reminder_app/screens/dashboard_tab.dart';
import 'package:medicine_reminder_app/screens/medicine_list_screen.dart';
import 'package:medicine_reminder_app/screens/history_screen.dart';
import 'package:medicine_reminder_app/screens/profile_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const MedicineListScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Today\'s Schedule',
    'My Medicines',
    'Adherence History',
    'My Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<MedicineProvider>(context, listen: false).updateUserId(authProvider.user?.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final medicineProvider = Provider.of<MedicineProvider>(context);
    final user = authProvider.user;

    final today = DateTime.now();
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final todayMeds = medicineProvider.medicines.where((m) => m.date == todayString).toList();
    final takenCount = todayMeds.where((m) => m.status == 'Taken').length;
    final totalCount = todayMeds.length;
    final complianceRate = totalCount > 0 ? (takenCount / totalCount * 100).round() : 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: _currentIndex == 0 ? 0 : 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              medicineProvider.updateUserId(user?.uid);
            },
            tooltip: 'Sync Data',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              accountName: Text(
                user?.name ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(user?.email ?? 'No email'),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Progress',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalCount > 0 ? (takenCount / totalCount) : 0,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        complianceRate >= 80 ? Colors.green : (complianceRate >= 50 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$takenCount of $totalCount Taken', style: theme.textTheme.bodyMedium),
                      Text('$complianceRate% Adhered', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Schedule'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication_outlined),
              title: const Text('Medicines'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Adherence History'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Profile Settings'),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    authProvider.isFirebaseEnabled ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authProvider.isFirebaseEnabled ? 'Firebase Sync Enabled' : 'Sandbox (Offline Mode)',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out of your account?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && mounted) {
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: _tabs[_currentIndex],
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed('/add_medicine');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
