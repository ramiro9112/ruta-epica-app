import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  static final _db = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _leads = [];
  String _statusFilter = 'all';
  final _search = TextEditingController();

  static const _statuses = ['all', 'nuevo', 'contactado', 'vendido', 'perdido'];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_applySearch);
  }

  @override
  void dispose() {
    _search.removeListener(_applySearch);
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _allLeads = [];

  void _applySearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _leads = _allLeads.where((l) {
        if (_statusFilter != 'all' && l['status'] != _statusFilter) return false;
        if (q.isEmpty) return true;
        return (l['full_name'] ?? '').toLowerCase().contains(q) ||
               (l['email'] ?? '').toLowerCase().contains(q) ||
               (l['phone'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db.from('leads').select().order('created_at', ascending: false);
      _allLeads = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() => _loading = false);
        _applySearch();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counters = <String, int>{};
    for (final s in _statuses.skip(1)) {
      counters[s] = _allLeads.where((l) => l['status'] == s).length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Search + filters
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, email, teléfono...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true, fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((s) {
                      final count = s == 'all' ? _allLeads.length : (counters[s] ?? 0);
                      final active = _statusFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 12),
                        child: GestureDetector(
                          onTap: () { setState(() => _statusFilter = s); _applySearch(); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: active ? _statusColor(s) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_statusLabel(s), style: TextStyle(
                                color: active ? AppColors.white : AppColors.darkGray,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: active ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10)),
                                child: Text('$count', style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: active ? AppColors.white : AppColors.darkGray)),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _leads.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Sin resultados', style: TextStyle(color: Colors.grey[500])),
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _leads.length,
                            itemBuilder: (_, i) => _LeadCard(
                              lead: _leads[i],
                              onStatusChange: (newStatus) => _changeStatus(_leads[i]['id'], newStatus),
                              onTap: () => _openDetail(context, _leads[i]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE65100),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.white),
        label: const Text('Nuevo lead', style: TextStyle(color: AppColors.white)),
        onPressed: () => _openDetail(context, null),
      ),
    );
  }

  Future<void> _changeStatus(String id, String status) async {
    await _db.from('leads').update({'status': status, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
    _load();
  }

  void _openDetail(BuildContext context, Map<String, dynamic>? lead) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _LeadDetailScreen(lead: lead, onSaved: _load),
    ));
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'all': return 'Todos';
      case 'nuevo': return 'Nuevo';
      case 'contactado': return 'Contactado';
      case 'vendido': return 'Vendido';
      case 'perdido': return 'Perdido';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'nuevo': return const Color(0xFFE65100);
      case 'contactado': return AppColors.deepBlue;
      case 'vendido': return Colors.green;
      case 'perdido': return Colors.grey;
      default: return AppColors.deepBlue;
    }
  }
}

class _LeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onTap;

  const _LeadCard({required this.lead, required this.onStatusChange, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = lead['status'] as String? ?? 'nuevo';
    final df = DateFormat('dd/MM/yy HH:mm');
    final createdAt = lead['created_at'] != null ? DateTime.tryParse(lead['created_at']) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
          border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(lead['full_name'] ?? 'Sin nombre',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText))),
              _StatusBadge(status: status),
            ]),
            const SizedBox(height: 6),
            if (lead['phone'] != null) _info(Icons.phone_outlined, lead['phone']),
            if (lead['email'] != null) _info(Icons.email_outlined, lead['email']),
            if (lead['destination_query'] != null) _info(Icons.location_on_outlined, lead['destination_query']),
            const SizedBox(height: 8),
            Row(children: [
              if (createdAt != null) Text(df.format(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: onStatusChange,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'nuevo', child: Text('Nuevo')),
                  const PopupMenuItem(value: 'contactado', child: Text('Contactado')),
                  const PopupMenuItem(value: 'vendido', child: Text('Vendido')),
                  const PopupMenuItem(value: 'perdido', child: Text('Perdido')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Estado', style: TextStyle(fontSize: 12, color: AppColors.deepBlue, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.deepBlue),
                  ]),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 12), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'nuevo': return const Color(0xFFE65100);
      case 'contactado': return AppColors.deepBlue;
      case 'vendido': return Colors.green;
      case 'perdido': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'nuevo': color = const Color(0xFFE65100); break;
      case 'contactado': color = AppColors.deepBlue; break;
      case 'vendido': color = Colors.green; break;
      case 'perdido': color = Colors.grey; break;
      default: color = Colors.grey;
    }
    final labels = {'nuevo': 'Nuevo', 'contactado': 'Contactado', 'vendido': 'Vendido', 'perdido': 'Perdido'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(labels[status] ?? status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Lead Detail / Form ───────────────────────────────────────────────────────

class _LeadDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? lead;
  final VoidCallback onSaved;
  const _LeadDetailScreen({this.lead, required this.onSaved});

  @override
  State<_LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<_LeadDetailScreen> {
  static final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _destination;
  late final TextEditingController _message;
  late final TextEditingController _notes;
  late final TextEditingController _assignedTo;
  String _status = 'nuevo';

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _name        = TextEditingController(text: l?['full_name'] ?? '');
    _phone       = TextEditingController(text: l?['phone'] ?? '');
    _email       = TextEditingController(text: l?['email'] ?? '');
    _destination = TextEditingController(text: l?['destination_query'] ?? '');
    _message     = TextEditingController(text: l?['message'] ?? '');
    _notes       = TextEditingController(text: l?['notes'] ?? '');
    _assignedTo  = TextEditingController(text: l?['assigned_to'] ?? '');
    _status      = l?['status'] as String? ?? 'nuevo';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _destination, _message, _notes, _assignedTo]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'full_name': _name.text.trim(),
      'phone': _phone.text.trim().isNotEmpty ? _phone.text.trim() : null,
      'email': _email.text.trim().isNotEmpty ? _email.text.trim() : null,
      'destination_query': _destination.text.trim().isNotEmpty ? _destination.text.trim() : null,
      'message': _message.text.trim().isNotEmpty ? _message.text.trim() : null,
      'notes': _notes.text.trim().isNotEmpty ? _notes.text.trim() : null,
      'assigned_to': _assignedTo.text.trim().isNotEmpty ? _assignedTo.text.trim() : null,
      'status': _status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      if (widget.lead == null) {
        await _db.from('leads').insert(data);
      } else {
        await _db.from('leads').update(data).eq('id', widget.lead!['id']);
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
        backgroundColor: const Color(0xFFE65100),
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(widget.lead == null ? 'Nuevo lead' : 'Detalle del lead',
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
              _f(_name, 'Nombre completo', required: true),
              _f(_phone, 'Teléfono', keyboard: TextInputType.phone),
              _f(_email, 'Email', keyboard: TextInputType.emailAddress),
              _f(_destination, 'Destino de interés'),
            ]),
            _card([
              const Text('Estado del lead', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepBlue)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: ['nuevo', 'contactado', 'vendido', 'perdido'].map((s) {
                final active = _status == s;
                final labels = {'nuevo': 'Nuevo', 'contactado': 'Contactado', 'vendido': 'Vendido', 'perdido': 'Perdido'};
                return GestureDetector(
                  onTap: () => setState(() => _status = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? _sColor(s) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(labels[s]!, style: TextStyle(
                      color: active ? AppColors.white : AppColors.darkGray,
                      fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList()),
            ]),
            _card([
              _f(_assignedTo, 'Asignado a (asesor)'),
              _f(_message, 'Mensaje original', maxLines: 3),
              _f(_notes, 'Notas internas', maxLines: 4),
            ]),
          ],
        ),
      ),
    );
  }

  Color _sColor(String s) {
    switch (s) {
      case 'nuevo': return const Color(0xFFE65100);
      case 'contactado': return AppColors.deepBlue;
      case 'vendido': return Colors.green;
      case 'perdido': return Colors.grey;
      default: return Colors.grey;
    }
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE65100))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      validator: required ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
    ),
  );
}
