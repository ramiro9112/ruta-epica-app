import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import 'help_screen.dart';
import 'notifications_screen.dart';
import 'terms_screen.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = user == null;

    if (isGuest) return _GuestProfileView();

    final profileAsync = ref.watch(userProfileProvider);
    final favCount = ref.watch(favoritesNotifierProvider).length;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(AppStrings.miPerfil),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfile(context, ref, user),
          ),
        ],
      ),
      body: ListView(
        children: [
          profileAsync.when(
            loading: () => _ProfileHeader(
              name: user.email?.split('@').first ?? 'Viajero',
              email: user.email ?? '',
              avatarUrl: null,
              favCount: favCount,
            ),
            error: (_, __) => _ProfileHeader(
              name: user.email?.split('@').first ?? 'Viajero',
              email: user.email ?? '',
              avatarUrl: null,
              favCount: favCount,
            ),
            data: (profile) => _ProfileHeader(
              name: profile?.displayName ?? user.email?.split('@').first ?? 'Viajero',
              email: profile?.email ?? user.email ?? '',
              avatarUrl: profile?.avatarUrl,
              phone: profile?.phone,
              favCount: favCount,
              onAvatarTap: () => _pickAvatar(context, ref, user.id),
            ),
          ),
          const SizedBox(height: 16),
          _MenuSection(
            items: [
              _MenuItem(
                icon: Icons.luggage_rounded,
                label: AppStrings.misReservas,
                onTap: () => context.go('/home/bookings'),
              ),
              _MenuItem(
                icon: Icons.favorite_rounded,
                label: AppStrings.misFavoritos,
                trailing: favCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$favCount',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText),
                        ),
                      )
                    : null,
                onTap: () => context.go('/home/favorites'),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: AppStrings.notificaciones,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MenuSection(
            items: [
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: AppStrings.ayuda,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                label: AppStrings.terminos,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                ),
              ),
            ],
          ),
          if (_isAdmin(user.email)) ...[
            const SizedBox(height: 12),
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Panel administrador',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _MenuSection(
            items: [
              _MenuItem(
                icon: Icons.logout_rounded,
                label: AppStrings.cerrarSesion,
                color: AppColors.error,
                onTap: () => _onSignOut(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppStrings.version} 1.0.0',
              style: const TextStyle(color: AppColors.darkGray, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool _isAdmin(String? email) {
    if (email == null) return false;
    const admins = {'agenciarutaepica@gmail.com', 'ramiro9112@gmail.com'};
    return admins.contains(email.toLowerCase());
  }

  Future<void> _onSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.cerrarSesion),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.cerrarSesion),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      // Router's refreshListenable detects auth change and redirects automatically.
    }
  }

  Future<void> _pickAvatar(
      BuildContext context, WidgetRef ref, String? userId) async {
    if (userId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (picked == null) return;

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Subiendo foto...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      final file = File(picked.path);
      // Append timestamp to bust cache on re-upload
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.path.split('.').last.toLowerCase();
      final path = 'avatars/${userId}_$ts.$ext';

      await SupabaseService.instance.client.storage
          .from('avatars')
          .upload(path, file,
              fileOptions: const FileOptions(upsert: true));

      final url = SupabaseService.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      await SupabaseService.instance.updateProfile(
        userId: userId,
        avatarUrl: url,
      );
      ref.invalidate(userProfileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada'),
            backgroundColor: AppColors.turquoise,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: ${e.toString().split(']').last.trim()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, User? user) {
    if (user == null) return;
    final profileAsync = ref.read(userProfileProvider);
    final profile = profileAsync.value;
    final nameController =
        TextEditingController(text: profile?.fullName ?? '');
    final phoneController =
        TextEditingController(text: profile?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.editarPerfil,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: AppStrings.nombreCompleto,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppStrings.telefono,
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await SupabaseService.instance.updateProfile(
                    userId: user.id,
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                  ref.invalidate(userProfileProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(AppStrings.guardarCambios),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Guest view ──────────────────────────────────────────────────────────────

class _GuestProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(AppStrings.miPerfil),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // Guest header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.deepBlue, AppColors.deepBlueLight],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 48, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Inicia sesión o crea una cuenta',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Guarda favoritos, haz reservas y más',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.darkText,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/login'),
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(
                              color: Colors.white70, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MenuSection(
            items: [
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: AppStrings.ayuda,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                label: AppStrings.terminos,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppStrings.version} 1.0.0',
              style:
                  const TextStyle(color: AppColors.darkGray, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Auth-required dialog (called from favorites / booking) ──────────────────

void showAuthRequiredDialog(BuildContext context, {String? reason}) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Inicia sesión',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Text(
        reason ?? 'Necesitas una cuenta para continuar.',
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            context.push('/login');
          },
          child: const Text('Iniciar sesión',
              style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/register');
          },
          child: const Text('Registrarse'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final int favCount;
  final VoidCallback? onAvatarTap;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.phone,
    required this.favCount,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepBlue, AppColors.deepBlueLight],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.gold,
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          _initials(name),
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                if (onAvatarTap != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: AppColors.darkText),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          if (phone != null && phone!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              phone!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(label: 'Favoritos', value: '$favCount'),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item.color ?? AppColors.deepBlue)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon,
                      size: 20, color: item.color ?? AppColors.deepBlue),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.color ?? AppColors.darkText,
                  ),
                ),
                trailing: item.trailing ??
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.darkGray, size: 20),
                onTap: item.onTap,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              ),
              if (i < items.length - 1)
                const Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: AppColors.lightGray),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    this.trailing,
    required this.onTap,
  });
}
