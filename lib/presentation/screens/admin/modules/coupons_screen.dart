import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  static final _db = Supabase.instance.client;
  final _fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  bool _loading = true;
  List<Map<String, dynamic>> _coupons = [];
  String _filter = 'all'; // all | active | expired

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
        data = await _db.from('coupons').select().eq('is_active', true).order('created_at', ascending: false);
      } else if (_filter == 'expired') {
        data = await _db.from('coupons').select().eq('is_active', false).order('created_at', ascending: false);
      } else {
        data = await _db.from('coupons').select().order('created_at', ascending: false);
      }
      if (mounted) setState(() { _coupons = List<Map<String, dynamic>>.from(data); _loading = false; });
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
              _Chip(label: 'Todos', active: _filter == 'all', onTap: () { setState(() => _filter = 'all'); _load(); }),
              const SizedBox(width: 8),
              _Chip(label: 'Activos', active: _filter == 'active', onTap: () { setState(() => _filter = 'active'); _load(); }),
              const SizedBox(width: 8),
              _Chip(label: 'Inactivos', active: _filter == 'expired', onTap: () { setState(() => _filter = 'expired'); _load(); }),
              const Spacer(),
              Text('${_coupons.length} cupones', style: const TextStyle(color: AppColors.darkGray, fontSize: 12)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _coupons.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.discount_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Sin cupones', style: TextStyle(color: Colors.grey[500])),
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _coupons.length,
                            itemBuilder: (_, i) => _CouponCard(
                              coupon: _coupons[i],
                              fmt: _fmt,
                              onEdit: () => _openForm(context, _coupons[i]),
                              onToggle: () => _toggle(_coupons[i]),
                              onDelete: () => _delete(context, _coupons[i]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFC62828),
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Nuevo cupón', style: TextStyle(color: AppColors.white)),
        onPressed: () => _openForm(context, null),
      ),
    );
  }

  Future<void> _toggle(Map<String, dynamic> c) async {
    await _db.from('coupons').update({'is_active': !(c['is_active'] as bool? ?? true)}).eq('id', c['id']);
    _load();
  }

  Future<void> _delete(BuildContext context, Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cupón'),
        content: Text('¿Eliminar el cupón "${c['code']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await _db.from('coupons').delete().eq('id', c['id']);
      _load();
    }
  }

  void _openForm(BuildContext context, Map<String, dynamic>? coupon) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _CouponFormScreen(coupon: coupon, onSaved: _load),
    ));
  }
}

class _Chip extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC62828) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(
        color: active ? AppColors.white : AppColors.darkGray,
        fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CouponCard({required this.coupon, required this.fmt, required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActive = coupon['is_active'] as bool? ?? true;
    final isPercent = (coupon['type'] as String? ?? 'percent') == 'percent';
    final value = (coupon['value'] as num?)?.toDouble() ?? 0;
    final used = coupon['used_count'] as int? ?? 0;
    final maxUses = coupon['max_uses'] as int?;
    final expiresAt = coupon['expires_at'] != null ? DateTime.tryParse(coupon['expires_at']) : null;
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final df = DateFormat('dd/MM/yyyy');
    final progress = maxUses != null && maxUses > 0 ? (used / maxUses).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        border: (!isActive || isExpired) ? Border.all(color: Colors.grey[300]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive && !isExpired ? const Color(0xFFC62828) : Colors.grey[400],
                borderRadius: BorderRadius.circular(8)),
              child: Text(coupon['code'] ?? '', style: const TextStyle(
                color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isActive && !isExpired) ? const Color(0xFFC62828).withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8)),
              child: Text(
                isPercent ? '-${value.toStringAsFixed(0)}%' : '-${fmt.format(value)}',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: (isActive && !isExpired) ? const Color(0xFFC62828) : Colors.grey[500])),
            ),
            const Spacer(),
            if (isExpired) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6)),
              child: Text('Vencido', style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          if (maxUses != null) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Usos: $used${maxUses > 0 ? ' / $maxUses' : ''}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.grey[200],
                color: progress > 0.8 ? Colors.red : const Color(0xFFC62828),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
          ] else
            Text('Usos: $used (ilimitados)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Row(children: [
            if (expiresAt != null) Row(children: [
              Icon(Icons.event_rounded, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('Vence: ${df.format(expiresAt)}', style: TextStyle(color: isExpired ? Colors.red : Colors.grey[600], fontSize: 12)),
            ]),
            const Spacer(),
            if (coupon['min_amount'] != null && (coupon['min_amount'] as num) > 0)
              Text('Mín: ${fmt.format(coupon['min_amount'])}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ]),
          if (coupon['conditions'] != null && coupon['conditions'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(coupon['conditions'], style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            _Btn2(icon: Icons.edit_rounded, label: 'Editar', color: AppColors.deepBlue, onTap: onEdit),
            const SizedBox(width: 8),
            _Btn2(icon: isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: isActive ? 'Desactivar' : 'Activar',
              color: isActive ? Colors.orange : Colors.green, onTap: onToggle),
            const Spacer(),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), onPressed: onDelete),
          ]),
        ],
      ),
    );
  }
}

class _Btn2 extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Btn2({required this.icon, required this.label, required this.color, required this.onTap});

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

// ─── Coupon Form ──────────────────────────────────────────────────────────────

class _CouponFormScreen extends StatefulWidget {
  final Map<String, dynamic>? coupon;
  final VoidCallback onSaved;
  const _CouponFormScreen({this.coupon, required this.onSaved});

  @override
  State<_CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends State<_CouponFormScreen> {
  static final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _code;
  late final TextEditingController _value;
  late final TextEditingController _minAmount;
  late final TextEditingController _maxUses;
  late final TextEditingController _conditions;
  String _type = 'percent';
  bool _isActive = true;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _code       = TextEditingController(text: c?['code'] ?? '');
    _value      = TextEditingController(text: c?['value']?.toString() ?? '');
    _minAmount  = TextEditingController(text: c?['min_amount']?.toString() ?? '');
    _maxUses    = TextEditingController(text: c?['max_uses']?.toString() ?? '');
    _conditions = TextEditingController(text: c?['conditions'] ?? '');
    _type       = c?['type'] as String? ?? 'percent';
    _isActive   = c?['is_active'] as bool? ?? true;
    _expiresAt  = c?['expires_at'] != null ? DateTime.tryParse(c!['expires_at']) : null;
  }

  @override
  void dispose() {
    for (final c in [_code, _value, _minAmount, _maxUses, _conditions]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'code': _code.text.trim().toUpperCase(),
      'type': _type,
      'value': double.tryParse(_value.text) ?? 0,
      'min_amount': _minAmount.text.isNotEmpty ? double.tryParse(_minAmount.text) ?? 0 : 0,
      'max_uses': _maxUses.text.isNotEmpty ? int.tryParse(_maxUses.text) : null,
      'conditions': _conditions.text.trim().isNotEmpty ? _conditions.text.trim() : null,
      'is_active': _isActive,
      'expires_at': _expiresAt?.toIso8601String(),
    };
    try {
      if (widget.coupon == null) {
        await _db.from('coupons').insert(data);
      } else {
        await _db.from('coupons').update(data).eq('id', widget.coupon!['id']);
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
        backgroundColor: const Color(0xFFC62828),
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(widget.coupon == null ? 'Nuevo cupón' : 'Editar cupón',
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
              _f(_code, 'Código del cupón', required: true),
              const Text('Tipo de descuento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _type = 'percent'),
                  child: _TypeTile(label: 'Porcentaje', icon: Icons.percent_rounded, active: _type == 'percent'))),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _type = 'fixed'),
                  child: _TypeTile(label: 'Valor fijo', icon: Icons.attach_money_rounded, active: _type == 'fixed'))),
              ]),
              const SizedBox(height: 14),
              _f(_value, _type == 'percent' ? 'Porcentaje de descuento (%)' : 'Valor de descuento (COP)',
                required: true, keyboard: TextInputType.number),
              _f(_minAmount, 'Compra mínima (COP)', keyboard: TextInputType.number),
              _f(_maxUses, 'Máximo de usos (vacío = ilimitado)', keyboard: TextInputType.number),
              _f(_conditions, 'Condiciones / descripción', maxLines: 3),
              SwitchListTile(value: _isActive, onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Cupón activo'), activeColor: const Color(0xFFC62828), contentPadding: EdgeInsets.zero),
            ]),
            _card([
              ListTile(contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded, size: 18, color: Color(0xFFC62828)),
                title: const Text('Fecha de vencimiento', style: TextStyle(fontSize: 14)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_expiresAt != null ? df.format(_expiresAt!) : 'Sin fecha',
                    style: TextStyle(color: _expiresAt != null ? AppColors.darkText : Colors.grey)),
                  if (_expiresAt != null) IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                    onPressed: () => setState(() => _expiresAt = null)),
                ]),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _expiresAt ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (d != null) setState(() => _expiresAt = d);
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
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _f(TextEditingController c, String label, {bool required = false, int maxLines = 1, TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c, maxLines: maxLines, keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC62828))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      validator: required ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
    ),
  );
}

class _TypeTile extends StatelessWidget {
  final String label; final IconData icon; final bool active;
  const _TypeTile({required this.label, required this.icon, required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFC62828) : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      border: active ? null : Border.all(color: Colors.grey[300]!)),
    child: Column(children: [
      Icon(icon, size: 24, color: active ? AppColors.white : Colors.grey[500]),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppColors.white : AppColors.darkGray)),
    ]),
  );
}
