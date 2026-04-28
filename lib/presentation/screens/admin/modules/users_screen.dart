import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  static final _db = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.removeListener(_filter);
    _search.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _users : _users.where((u) {
        return (u['full_name'] ?? '').toLowerCase().contains(q) ||
               (u['email'] ?? '').toLowerCase().contains(q) ||
               (u['phone'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db.from('profiles').select().order('created_at', ascending: false);
      _users = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() => _loading = false);
        _filter();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Buscar usuarios...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true, fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_filtered.length} usuarios', style: const TextStyle(color: AppColors.darkGray, fontSize: 12)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Sin usuarios', style: TextStyle(color: Colors.grey[500])),
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _UserTile(
                              user: _filtered[i],
                              onTap: () => _showDetail(context, _filtered[i]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> user) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final createdAt = user['created_at'] != null ? DateTime.tryParse(user['created_at']) : null;
    final initials = _initials(user['full_name'] ?? user['email'] ?? 'U');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.deepBlue,
                backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                child: user['avatar_url'] == null
                    ? Text(initials, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user['full_name'] ?? 'Sin nombre', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ])),
            ]),
            const Divider(height: 24),
            if (user['phone'] != null && user['phone'].toString().isNotEmpty)
              _detailRow(Icons.phone_outlined, 'Teléfono', user['phone']),
            _detailRow(Icons.calendar_today_outlined, 'Registrado',
              createdAt != null ? df.format(createdAt) : 'Desconocido'),
            _detailRow(Icons.person_outline_rounded, 'ID de usuario', (user['id'] as String).substring(0, 8) + '...'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.deepBlue),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final createdAt = user['created_at'] != null ? DateTime.tryParse(user['created_at']) : null;
    final name = user['full_name'] ?? user['email'] ?? 'Sin nombre';
    final initials = _initials(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.deepBlue.withValues(alpha: 0.15),
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null
                ? Text(initials, style: const TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.w700, fontSize: 13))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
              overflow: TextOverflow.ellipsis),
            Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (createdAt != null)
              Text(df.format(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 2),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.darkGray),
          ]),
        ]),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
