import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  static final _db = Supabase.instance.client;
  final _fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  bool _loading = true;
  List<Map<String, dynamic>> _packages = [];
  String _filter = 'all'; // all | active | promo

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> data;
      if (_filter == 'active') {
        data = await _db.from('destinations').select().eq('is_active', true).order('display_order').order('created_at', ascending: false);
      } else if (_filter == 'promo') {
        data = await _db.from('destinations').select().eq('is_promotion', true).order('display_order').order('created_at', ascending: false);
      } else {
        data = await _db.from('destinations').select().order('display_order').order('created_at', ascending: false);
      }
      if (mounted) setState(() { _packages = List<Map<String, dynamic>>.from(data); _loading = false; });
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
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _packages.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _packages.length,
                            itemBuilder: (_, i) => _PackageCard(
                              pkg: _packages[i],
                              fmt: _fmt,
                              onEdit: () => _openForm(context, _packages[i]),
                              onToggle: () => _toggleActive(_packages[i]),
                              onDelete: () => _confirmDelete(context, _packages[i]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.deepBlue,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Nuevo paquete', style: TextStyle(color: AppColors.white)),
        onPressed: () => _openForm(context, null),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _FilterChip(label: 'Todos', active: _filter == 'all', onTap: () { setState(() => _filter = 'all'); _load(); }),
          const SizedBox(width: 8),
          _FilterChip(label: 'Activos', active: _filter == 'active', onTap: () { setState(() => _filter = 'active'); _load(); }),
          const SizedBox(width: 8),
          _FilterChip(label: 'En promo', active: _filter == 'promo', onTap: () { setState(() => _filter = 'promo'); _load(); }),
          const Spacer(),
          Text('${_packages.length} paquetes', style: const TextStyle(color: AppColors.darkGray, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.luggage_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text('Sin paquetes', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
      ],
    ),
  );

  Future<void> _toggleActive(Map<String, dynamic> pkg) async {
    final newVal = !(pkg['is_active'] as bool? ?? true);
    await _db.from('destinations').update({'is_active': newVal}).eq('id', pkg['id']);
    _load();
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> pkg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar paquete'),
        content: Text('¿Eliminar "${pkg['name']}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.from('destinations').delete().eq('id', pkg['id']);
      _load();
    }
  }

  void _openForm(BuildContext context, Map<String, dynamic>? pkg) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PackageFormScreen(pkg: pkg, onSaved: _load),
    ));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.deepBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: active ? AppColors.white : AppColors.darkGray,
          fontSize: 13, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> pkg;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PackageCard({
    required this.pkg, required this.fmt,
    required this.onEdit, required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = pkg['is_active'] as bool? ?? true;
    final isPromo = pkg['is_promotion'] as bool? ?? false;
    final tag = pkg['tag'] as String?;
    final price = (pkg['price'] as num?)?.toDouble() ?? 0;
    final promoPrice = (pkg['promotion_price'] as num?)?.toDouble();
    final spots = pkg['available_spots'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        border: isActive ? null : Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header
          if (pkg['image_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(pkg['image_url'], height: 140, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 140, color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey))),
                  if (!isActive) Container(height: 140, color: Colors.black45,
                    child: const Center(child: Text('INACTIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)))),
                  if (tag != null) Positioned(top: 10, left: 10,
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _tagColor(tag), borderRadius: BorderRadius.circular(8)),
                      child: Text(tag.toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(pkg['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkText))),
                  if (isPromo) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(6)),
                    child: Text('PROMO', style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(pkg['destination'] ?? pkg['country'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  if (pkg['duration_days'] != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${pkg['duration_days']} días', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                  if (spots != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.people_outline, size: 14, color: spots <= 3 ? Colors.red : Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('$spots cupos', style: TextStyle(color: spots <= 3 ? Colors.red : Colors.grey[600], fontSize: 13, fontWeight: spots <= 3 ? FontWeight.w700 : FontWeight.normal)),
                  ],
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  if (isPromo && promoPrice != null) ...[
                    Text(fmt.format(promoPrice), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                    const SizedBox(width: 8),
                    Text(fmt.format(price), style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: AppColors.darkGray)),
                  ] else
                    Text(fmt.format(price), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _ActionButton(icon: Icons.edit_rounded, label: 'Editar', color: AppColors.deepBlue, onTap: onEdit),
                  const SizedBox(width: 8),
                  _ActionButton(icon: isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    label: isActive ? 'Ocultar' : 'Activar',
                    color: isActive ? Colors.orange : Colors.green, onTap: onToggle),
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

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'hot': return Colors.red;
      case 'nuevo': return Colors.green;
      case 'últimos cupos': return Colors.orange;
      default: return AppColors.deepBlue;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Package Form Screen ──────────────────────────────────────────────────────

class _PackageFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pkg;
  final VoidCallback onSaved;
  const _PackageFormScreen({this.pkg, required this.onSaved});

  @override
  State<_PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<_PackageFormScreen> {
  static final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _destination;
  late final TextEditingController _country;
  late final TextEditingController _price;
  late final TextEditingController _promoPrice;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late final TextEditingController _itinerary;
  late final TextEditingController _includes;
  late final TextEditingController _excludes;
  late final TextEditingController _imageUrl;
  late final TextEditingController _ctaText;
  late final TextEditingController _spots;
  late final TextEditingController _displayOrder;
  String? _tag;
  bool _isActive = true;
  bool _isPromo = false;
  DateTime? _departureDate;
  DateTime? _promoEndsAt;

  static const _tags = ['', 'hot', 'nuevo', 'últimos cupos'];

  @override
  void initState() {
    super.initState();
    final p = widget.pkg;
    _name          = TextEditingController(text: p?['name'] ?? '');
    _destination   = TextEditingController(text: p?['destination'] ?? '');
    _country       = TextEditingController(text: p?['country'] ?? '');
    _price         = TextEditingController(text: p?['price']?.toString() ?? '');
    _promoPrice    = TextEditingController(text: p?['promotion_price']?.toString() ?? '');
    _duration      = TextEditingController(text: p?['duration_days']?.toString() ?? '');
    _description   = TextEditingController(text: p?['description'] ?? '');
    _itinerary     = TextEditingController(text: p?['itinerary'] ?? '');
    _includes      = TextEditingController(text: (p?['includes'] as List?)?.join('\n') ?? '');
    _excludes      = TextEditingController(text: (p?['excludes'] as List?)?.join('\n') ?? '');
    _imageUrl      = TextEditingController(text: p?['image_url'] ?? '');
    _ctaText       = TextEditingController(text: p?['cta_text'] ?? 'RESERVAR AHORA');
    _spots         = TextEditingController(text: p?['available_spots']?.toString() ?? '');
    _displayOrder  = TextEditingController(text: p?['display_order']?.toString() ?? '0');
    _tag           = p?['tag'] as String?;
    _isActive      = p?['is_active'] as bool? ?? true;
    _isPromo       = p?['is_promotion'] as bool? ?? false;
    _departureDate = p?['departure_date'] != null ? DateTime.tryParse(p!['departure_date']) : null;
    _promoEndsAt   = p?['promo_ends_at'] != null ? DateTime.tryParse(p!['promo_ends_at']) : null;
  }

  @override
  void dispose() {
    for (final c in [_name, _destination, _country, _price, _promoPrice, _duration,
      _description, _itinerary, _includes, _excludes, _imageUrl, _ctaText, _spots, _displayOrder]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final includesList = _includes.text.trim().split('\n').where((s) => s.isNotEmpty).toList();
    final excludesList = _excludes.text.trim().split('\n').where((s) => s.isNotEmpty).toList();

    final data = {
      'name': _name.text.trim(),
      'destination': _destination.text.trim(),
      'country': _country.text.trim(),
      'price': double.tryParse(_price.text) ?? 0,
      'promotion_price': _promoPrice.text.isNotEmpty ? double.tryParse(_promoPrice.text) : null,
      'duration_days': int.tryParse(_duration.text),
      'description': _description.text.trim(),
      'itinerary': _itinerary.text.trim().isNotEmpty ? _itinerary.text.trim() : null,
      'includes': includesList.isNotEmpty ? includesList : null,
      'excludes': excludesList.isNotEmpty ? excludesList : null,
      'image_url': _imageUrl.text.trim().isNotEmpty ? _imageUrl.text.trim() : null,
      'cta_text': _ctaText.text.trim().isNotEmpty ? _ctaText.text.trim() : 'RESERVAR AHORA',
      'available_spots': _spots.text.isNotEmpty ? int.tryParse(_spots.text) : null,
      'display_order': int.tryParse(_displayOrder.text) ?? 0,
      'tag': _tag?.isNotEmpty == true ? _tag : null,
      'is_active': _isActive,
      'is_promotion': _isPromo,
      'departure_date': _departureDate?.toIso8601String().split('T').first,
      'promo_ends_at': _promoEndsAt?.toIso8601String(),
    };

    try {
      if (widget.pkg == null) {
        await _db.from('destinations').insert(data);
      } else {
        await _db.from('destinations').update(data).eq('id', widget.pkg!['id']);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pkg != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(isEdit ? 'Editar paquete' : 'Nuevo paquete',
          style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (_saving) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)))
          else TextButton(onPressed: _save, child: const Text('Guardar', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Información básica', [
              _field(_name, 'Nombre del paquete', required: true),
              _field(_destination, 'Destino'),
              _field(_country, 'País'),
              _field(_duration, 'Duración (días)', keyboard: TextInputType.number),
              _field(_spots, 'Cupos disponibles', keyboard: TextInputType.number),
              _field(_displayOrder, 'Orden de aparición', keyboard: TextInputType.number),
            ]),
            _section('Precios', [
              _field(_price, 'Precio normal (COP)', required: true, keyboard: TextInputType.number),
              _field(_promoPrice, 'Precio promocional (COP)', keyboard: TextInputType.number),
            ]),
            _section('Etiqueta y estado', [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: _tag ?? '',
                  decoration: _inputDecoration('Etiqueta (tag)'),
                  items: _tags.map((t) => DropdownMenuItem(value: t, child: Text(t.isEmpty ? 'Sin etiqueta' : t))).toList(),
                  onChanged: (v) => setState(() => _tag = v),
                ),
              ),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Paquete activo'),
                activeColor: AppColors.deepBlue,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _isPromo,
                onChanged: (v) => setState(() => _isPromo = v),
                title: const Text('En promoción'),
                activeColor: Colors.orange,
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            _section('Fechas', [
              _dateTile('Fecha de salida', _departureDate, (d) => setState(() => _departureDate = d)),
              _dateTile('Promoción vence', _promoEndsAt, (d) => setState(() => _promoEndsAt = d)),
            ]),
            _section('Contenido', [
              _field(_description, 'Descripción comercial', maxLines: 4),
              _field(_itinerary, 'Itinerario', maxLines: 5),
              _field(_includes, 'Incluye (una línea por ítem)', maxLines: 4),
              _field(_excludes, 'No incluye (una línea por ítem)', maxLines: 4),
              _field(_ctaText, 'Texto botón CTA'),
              _field(_imageUrl, 'URL imagen principal'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepBlue))),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool required = false, int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: _inputDecoration(label),
        validator: required ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, ValueChanged<DateTime?> onPick) {
    final df = DateFormat('dd/MM/yyyy');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.deepBlue),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(date != null ? df.format(date) : 'Sin fecha', style: TextStyle(color: date != null ? AppColors.darkText : Colors.grey)),
        if (date != null) IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey), onPressed: () => onPick(null)),
      ]),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onPick(picked);
      },
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF8F9FC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.deepBlue)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
