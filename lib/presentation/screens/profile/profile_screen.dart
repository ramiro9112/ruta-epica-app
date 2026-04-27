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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
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
          // Profile header
          profileAsync.when(
            loading: () => _ProfileHeader(
              name: user?.email?.split('@').first ?? 'Viajero',
              email: user?.email ?? '',
              avatarUrl: null,
              favCount: favCount,
            ),
            error: (_, __) => _ProfileHeader(
              name: user?.email?.split('@').first ?? 'Viajero',
              email: user?.email ?? '',
              avatarUrl: null,
              favCount: favCount,
            ),
            data: (profile) => _ProfileHeader(
              name: profile?.displayName ?? user?.email?.split('@').first ?? 'Viajero',
              email: profile?.email ?? user?.email ?? '',
              avatarUrl: profile?.avatarUrl,
              phone: profile?.phone,
              favCount: favCount,
              onAvatarTap: () => _pickAvatar(context, ref, user?.id),
            ),
          ),
          const SizedBox(height: 16),
          // Menu items
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
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MenuSection(
            items: [
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: AppStrings.ayuda,
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                label: AppStrings.terminos,
                onTap: () {},
              ),
            ],
          ),
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
          // Version
          Center(
            child: Text(
              '${AppStrings.version} 1.0.0',
              style: const TextStyle(
                color: AppColors.darkGray,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _pickAvatar(
      BuildContext context, WidgetRef ref, String? userId) async {
    if (userId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
    if (picked == null) return;
    try {
      final file = File(picked.path);
      final url =
          await SupabaseService.instance.uploadAvatar(file, userId);
      if (url != null) {
        await SupabaseService.instance.updateProfile(
          userId: userId,
          avatarUrl: url,
        );
        ref.invalidate(userProfileProvider);
      }
    } catch (_) {}
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
