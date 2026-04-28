import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  static final _db = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db.from('banners').select().order('display_order').order('created_at', ascending: false);
      if (mounted) setState(() { _banners = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _banners.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _banners.length,
                      itemBuilder: (_, i) => _BannerCard(
                        banner: _banners[i],
                        onEdit: () => _openForm(context, _banners[i]),
                        onToggle: () => _toggle(_banners[i]),
                        onDelete: () => _delete(context, _banners[i]),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00796B),
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Nuevo banner', style: TextStyle(color: AppColors.white)),
        onPressed: () => _openForm(context, null),
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.photo_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('Sin banners', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
    ]),
  );

  Future<void> _toggle(Map<String, dynamic> banner) async {
    await _db.from('banners').update({'is_active': !(banner['is_active'] as bool? ?? true)}).eq('id', banner['id']);
    _load();
  }

  Future<void> _delete(BuildContext context, Map<String, dynamic> banner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar banner'),
        content: Text('¿Eliminar "${banner['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await _db.from('banners').delete().eq('id', banner['id']);
      _load();
    }
  }

  void _openForm(BuildContext context, Map<String, dynamic>? banner) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _BannerFormScreen(banner: banner, onSaved: _load),
    ));
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerCard({required this.banner, required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActive = banner['is_active'] as bool? ?? true;
    final df = DateFormat('dd/MM/yy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner['image_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(children: [
                Image.network(banner['image_url'], height: 120, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey[200],
                    child: const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey))),
                if (!isActive) Container(height: 120, color: Colors.black45,
                  child: const Center(child: Text('INACTIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)))),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? Colors.green : Colors.grey)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(banner['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: isActive ? Colors.green[50] : Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                    child: Text(isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(color: isActive ? Colors.green[700] : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w700))),
                ]),
                if (banner['subtitle'] != null) ...[
                  const SizedBox(height: 4),
                  Text(banner['subtitle'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(banner['cta_text'] ?? 'Reservar ahora', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  if (banner['starts_at'] != null)
                    Text('${df.format(DateTime.parse(banner['starts_at']))} → ${banner['ends_at'] != null ? df.format(DateTime.parse(banner['ends_at'])) : '∞'}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _Btn(icon: Icons.edit_rounded, label: 'Editar', color: AppColors.deepBlue, onTap: onEdit),
                  const SizedBox(width: 8),
                  _Btn(icon: isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    label: isActive ? 'Ocultar' : 'Mostrar', color: isActive ? Colors.orange : Colors.green, onTap: onToggle),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), onPressed: onDelete),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─── Banner Form ──────────────────────────────────────────────────────────────

class _BannerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? banner;
  final VoidCallback onSaved;
  const _BannerFormScreen({this.banner, required this.onSaved});

  @override
  State<_BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<_BannerFormScreen> {
  static final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _cta;
  late final TextEditingController _imageUrl;
  late final TextEditingController _displayOrder;
  bool _isActive = true;
  DateTime? _startsAt;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _title        = TextEditingController(text: b?['title'] ?? '');
    _subtitle     = TextEditingController(text: b?['subtitle'] ?? '');
    _cta          = TextEditingController(text: b?['cta_text'] ?? 'Reservar ahora');
    _imageUrl     = TextEditingController(text: b?['image_url'] ?? '');
    _displayOrder = TextEditingController(text: b?['display_order']?.toString() ?? '0');
    _isActive     = b?['is_active'] as bool? ?? true;
    _startsAt     = b?['starts_at'] != null ? DateTime.tryParse(b!['starts_at']) : null;
    _endsAt       = b?['ends_at'] != null ? DateTime.tryParse(b!['ends_at']) : null;
  }

  @override
  void dispose() {
    for (final c in [_title, _subtitle, _cta, _imageUrl, _displayOrder]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim().isNotEmpty ? _subtitle.text.trim() : null,
      'cta_text': _cta.text.trim(),
      'image_url': _imageUrl.text.trim().isNotEmpty ? _imageUrl.text.trim() : null,
      'display_order': int.tryParse(_displayOrder.text) ?? 0,
      'is_active': _isActive,
      'starts_at': _startsAt?.toIso8601String(),
      'ends_at': _endsAt?.toIso8601String(),
    };
    try {
      if (widget.banner == null) {
        await _db.from('banners').insert(data);
      } else {
        await _db.from('banners').update(data).eq('id', widget.banner!['id']);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(widget.banner == null ? 'Nuevo banner' : 'Editar banner',
          style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (_saving) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)))
          else TextButton(onPressed: _save, child: const Text('Guardar', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card([
              _f(_title, 'Título del banner', required: true),
              _f(_subtitle, 'Subtítulo', maxLines: 2),
              _f(_cta, 'Texto del botón CTA'),
              _f(_imageUrl, 'URL de imagen'),
              _f(_displayOrder, 'Orden', keyboard: TextInputType.number),
              SwitchListTile(value: _isActive, onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Banner activo'), activeColor: Colors.green, contentPadding: EdgeInsets.zero),
            ]),
            _card([
              ListTile(contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF00796B)),
                title: const Text('Fecha inicio', style: TextStyle(fontSize: 14)),
                trailing: Text(_startsAt != null ? df.format(_startsAt!) : 'Sin fecha', style: TextStyle(color: _startsAt != null ? AppColors.darkText : Colors.grey)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _startsAt ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setState(() => _startsAt = d);
                }),
              ListTile(contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy_rounded, size: 18, color: Color(0xFF00796B)),
                title: const Text('Fecha fin', style: TextStyle(fontSize: 14)),
                trailing: Text(_endsAt != null ? df.format(_endsAt!) : 'Sin fecha', style: TextStyle(color: _endsAt != null ? AppColors.darkText : Colors.grey)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _endsAt ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setState(() => _endsAt = d);
                }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
    child: Column(children: children),
  );

  Widget _f(TextEditingController c, String label, {bool required = false, int maxLines = 1, TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c, maxLines: maxLines, keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00796B))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      validator: required ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
    ),
  );
}
