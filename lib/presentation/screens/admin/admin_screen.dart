import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'modules/dashboard_screen.dart';
import 'modules/packages_screen.dart';
import 'modules/banners_screen.dart';
import 'modules/leads_screen.dart';
import 'modules/users_screen.dart';
import 'modules/testimonials_screen.dart';
import 'modules/coupons_screen.dart';
import 'modules/settings_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _index = 0;

  static const _modules = [
    _Module(Icons.dashboard_rounded,          'Dashboard',       Color(0xFF0B2F5C)),
    _Module(Icons.luggage_rounded,             'Paquetes',        Color(0xFF1A4A8A)),
    _Module(Icons.photo_rounded,               'Banners',         Color(0xFF00796B)),
    _Module(Icons.person_add_alt_1_rounded,    'Leads',           Color(0xFFE65100)),
    _Module(Icons.people_alt_rounded,          'Usuarios',        Color(0xFF4527A0)),
    _Module(Icons.star_rounded,                'Testimonios',     Color(0xFFF9A825)),
    _Module(Icons.discount_rounded,            'Cupones',         Color(0xFFC62828)),
    _Module(Icons.settings_rounded,            'Configuración',   Color(0xFF37474F)),
  ];

  final _screens = const [
    DashboardScreen(),
    PackagesScreen(),
    BannersScreen(),
    LeadsScreen(),
    UsersAdminScreen(),
    TestimonialsScreen(),
    CouponsScreen(),
    AppSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  size: 18, color: AppColors.darkText),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Panel Admin',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white)),
                Text('Ruta Épica',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white54)),
              ],
            ),
          ],
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _AdminDrawer(
        modules: _modules,
        current: _index,
        email: user?.email ?? '',
        onSelect: (i) {
          setState(() => _index = i);
          Navigator.pop(context);
        },
        onBack: () => Navigator.pop(context),
      ),
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
    );
  }
}

class _Module {
  final IconData icon;
  final String title;
  final Color color;

  const _Module(this.icon, this.title, this.color);
}

class _AdminDrawer extends StatelessWidget {
  final List<_Module> modules;
  final int current;
  final String email;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;

  const _AdminDrawer({
    required this.modules,
    required this.current,
    required this.email,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.deepBlue,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        size: 28, color: AppColors.darkText),
                  ),
                  const SizedBox(height: 12),
                  const Text('Panel Admin',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            // Module list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: modules.length,
                itemBuilder: (_, i) {
                  final m = modules[i];
                  final active = i == current;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: active
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.2))
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: active
                              ? m.color
                              : m.color.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(m.icon,
                            size: 18, color: AppColors.white),
                      ),
                      title: Text(m.title,
                          style: TextStyle(
                            color: active
                                ? AppColors.white
                                : Colors.white70,
                            fontSize: 14,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                      trailing: active
                          ? Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : null,
                      onTap: () => onSelect(i),
                      dense: true,
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white54, size: 20),
              title: const Text('Volver a la app',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              onTap: () {
                Navigator.pop(context); // close drawer
                onBack();               // pop admin screen
              },
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
