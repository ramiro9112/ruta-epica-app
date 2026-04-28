import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class TestimonialsScreen extends StatefulWidget {
  const TestimonialsScreen({super.key});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> with SingleTickerProviderStateMixin {
  static final _db = Supabase.instance.client;
  late final TabController _tabs;
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db.from('testimonials').select().order('created_at', ascending: false);
      if (mounted) setState(() { _all = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _pending  => _all.where((t) => !(t['is_approved'] as bool? ?? false)).toList();
  List<Map<String, dynamic>> get _approved => _all.where((t) => t['is_approved'] as bool? ?? false).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: const Color(0xFFF9A825),
              unselectedLabelColor: AppColors.darkGray,
              indicatorColor: const Color(0xFFF9A825),
              tabs: [
                Tab(text: 'Pendientes (${_pending.length})'),
                Tab(text: 'Aprobados (${_approved.length})'),
                const Tab(text: 'Todos'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _TestimonialList(items: _pending, onRefresh: _load, emptyMsg: 'Sin pendientes de aprobar', showActions: true,
                        onApprove: (id) => _setApproved(id, true), onReject: (id) => _delete(context, id), onFeature: _toggleFeature),
                      _TestimonialList(items: _approved, onRefresh: _load, emptyMsg: 'Sin testimonios aprobados', showActions: false,
                        onApprove: (id) => _setApproved(id, false), onReject: (id) => _delete(context, id), onFeature: _toggleFeature),
                      _TestimonialList(items: _all, onRefresh: _load, emptyMsg: 'Sin testimonios', showActions: false,
                        onApprove: (id) {}, onReject: (id) => _delete(context, id), onFeature: _toggleFeature),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF9A825),
        icon: const Icon(Icons.add_rounded, color: AppColors.darkText),
        label: const Text('Nuevo testimonio', style: TextStyle(color: AppColors.darkText)),
        onPressed: () => _openForm(context, null),
      ),
    );
  }

  Future<void> _setApproved(String id, bool approved) async {
    await _db.from('testimonials').update({'is_approved': approved}).eq('id', id);
    _load();
  }

  Future<void> _toggleFeature(String id, bool current) async {
    await _db.from('testimonials').update({'is_featured': !current}).eq('id', id);
    _load();
  }

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar testimonio'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await _db.from('testimonials').delete().eq('id', id);
      _load();
    }
  }

  void _openForm(BuildContext context, Map<String, dynamic>? t) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _TestimonialFormScreen(testimonial: t, onSaved: _load),
    ));
  }
}

class _TestimonialList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;
  final String emptyMsg;
  final bool showActions;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final Function(String, bool) onFeature;

  const _TestimonialList({
    required this.items, required this.onRefresh, required this.emptyMsg,
    required this.showActions, required this.onApprove, required this.onReject, required this.onFeature,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.star_border_rounded, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text(emptyMsg, style: TextStyle(color: Colors.grey[500])),
    ]));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final t = items[i];
          final isApproved = t['is_approved'] as bool? ?? false;
          final isFeatured = t['is_featured'] as bool? ?? false;
          final df = DateFormat('dd/MM/yy');
          final createdAt = t['created_at'] != null ? DateTime.tryParse(t['created_at']) : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              border: isFeatured ? Border.all(color: const Color(0xFFF9A825), width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFF9A825).withValues(alpha: 0.2),
                    backgroundImage: t['photo_url'] != null ? NetworkImage(t['photo_url']) : null,
                    child: t['photo_url'] == null
                        ? Text((t['author_name'] ?? 'A')[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFFF9A825), fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t['author_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (t['author_city'] != null)
                      Text(t['author_city'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _Stars(rating: t['rating'] as int? ?? 5),
                    if (createdAt != null) Text(df.format(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                  ]),
                ]),
                const SizedBox(height: 10),
                Text('"${t['content'] ?? ''}"', style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic)),
                if (t['destination'] != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(t['destination'], style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ]),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  if (showActions) ...[
                    _TBtn(icon: Icons.check_circle_outline_rounded, label: 'Aprobar', color: Colors.green,
                      onTap: () => onApprove(t['id'])),
                    const SizedBox(width: 8),
                  ],
                  if (isApproved && !showActions)
                    _TBtn(icon: Icons.unpublished_outlined, label: 'Quitar aprobación', color: Colors.orange,
                      onTap: () => onApprove(t['id'])),
                  _TBtn(
                    icon: isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                    label: isFeatured ? 'Destacado' : 'Destacar',
                    color: const Color(0xFFF9A825),
                    onTap: () => onFeature(t['id'], isFeatured),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), onPressed: () => onReject(t['id'])),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Icon(
      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
      size: 14, color: const Color(0xFFF9A825),
    )),
  );
}

class _TBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _TBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─── Testimonial Form ─────────────────────────────────────────────────────────

class _TestimonialFormScreen extends StatefulWidget {
  final Map<String, dynamic>? testimonial;
  final VoidCallback onSaved;
  const _TestimonialFormScreen({this.testimonial, required this.onSaved});

  @override
  State<_TestimonialFormScreen> createState() => _TestimonialFormScreenState();
}

class _TestimonialFormScreenState extends State<_TestimonialFormScreen> {
  static final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _content;
  late final TextEditingController _destination;
  late final TextEditingController _photoUrl;
  int _rating = 5;
  bool _approved = false;
  bool _featured = false;

  @override
  void initState() {
    super.initState();
    final t = widget.testimonial;
    _name        = TextEditingController(text: t?['author_name'] ?? '');
    _city        = TextEditingController(text: t?['author_city'] ?? '');
    _content     = TextEditingController(text: t?['content'] ?? '');
    _destination = TextEditingController(text: t?['destination'] ?? '');
    _photoUrl    = TextEditingController(text: t?['photo_url'] ?? '');
    _rating      = t?['rating'] as int? ?? 5;
    _approved    = t?['is_approved'] as bool? ?? false;
    _featured    = t?['is_featured'] as bool? ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _city, _content, _destination, _photoUrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'author_name': _name.text.trim(),
      'author_city': _city.text.trim().isNotEmpty ? _city.text.trim() : null,
      'content': _content.text.trim(),
      'destination': _destination.text.trim().isNotEmpty ? _destination.text.trim() : null,
      'photo_url': _photoUrl.text.trim().isNotEmpty ? _photoUrl.text.trim() : null,
      'rating': _rating,
      'is_approved': _approved,
      'is_featured': _featured,
    };
    try {
      if (widget.testimonial == null) {
        await _db.from('testimonials').insert(data);
      } else {
        await _db.from('testimonials').update(data).eq('id', widget.testimonial!['id']);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9A825),
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: Text(widget.testimonial == null ? 'Nuevo testimonio' : 'Editar testimonio',
          style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (_saving) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.darkText, strokeWidth: 2)))
          else TextButton(onPressed: _save, child: const Text('Guardar', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card([
              _f(_name, 'Nombre del autor', required: true),
              _f(_city, 'Ciudad'),
              _f(_photoUrl, 'URL foto del autor'),
              _f(_destination, 'Destino visitado'),
            ]),
            _card([
              _f(_content, 'Testimonio', required: true, maxLines: 5),
              const SizedBox(height: 4),
              const Text('Calificación', style: TextStyle(fontSize: 13, color: AppColors.darkGray)),
              const SizedBox(height: 8),
              Row(children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 32, color: const Color(0xFFF9A825)),
              ))),
            ]),
            _card([
              SwitchListTile(value: _approved, onChanged: (v) => setState(() => _approved = v),
                title: const Text('Aprobado'), activeColor: Colors.green, contentPadding: EdgeInsets.zero),
              SwitchListTile(value: _featured, onChanged: (v) => setState(() => _featured = v),
                title: const Text('Destacado'), activeColor: const Color(0xFFF9A825), contentPadding: EdgeInsets.zero),
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
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _f(TextEditingController c, String label, {bool required = false, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF9A825))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      validator: required ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
    ),
  );
}
