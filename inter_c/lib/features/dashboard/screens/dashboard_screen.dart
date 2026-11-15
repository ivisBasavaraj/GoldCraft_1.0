import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_outlined, label: 'Inventory'),
    _NavItem(icon: Icons.shopping_cart_outlined, label: 'Sales'),
    _NavItem(icon: Icons.shopping_bag_outlined, label: 'Purchase'),
    _NavItem(icon: Icons.account_balance_outlined, label: 'Accounts'),
    _NavItem(icon: Icons.people_outline, label: 'HR'),
    _NavItem(icon: Icons.bar_chart_outlined, label: 'Reports'),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inter-C ERP'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const CircleAvatar(child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: _buildNavList(),
            ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              extended: true,
              minExtendedWidth: 200,
              destinations: _navItems
                  .map((e) => NavigationRailDestination(
                        icon: Icon(e.icon),
                        label: Text(e.label),
                      ))
                  .toList(),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildNavList() {
    return ListView(
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Color(0xFF1A237E)),
          child: Text('Inter-C ERP', style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
        ..._navItems.asMap().entries.map(
              (e) => ListTile(
                leading: Icon(e.value.icon),
                title: Text(e.value.label),
                selected: _selectedIndex == e.key,
                onTap: () {
                  setState(() => _selectedIndex = e.key);
                  Navigator.pop(context);
                },
              ),
            ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _navItems[_selectedIndex].label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (_selectedIndex == 0) const _DashboardOverview(),
          if (_selectedIndex != 0)
            Center(
              child: Text(
                '${_navItems[_selectedIndex].label} module coming soon',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Total Sales', '₹0', Icons.trending_up, Colors.green),
      ('Purchase Orders', '0', Icons.shopping_bag, Colors.blue),
      ('Stock Items', '0', Icons.inventory, Colors.orange),
      ('Pending Bills', '₹0', Icons.receipt_long, Colors.red),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map((c) => SizedBox(
                width: 200,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(c.$3, color: c.$4, size: 32),
                        const SizedBox(height: 12),
                        Text(c.$1, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(c.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
