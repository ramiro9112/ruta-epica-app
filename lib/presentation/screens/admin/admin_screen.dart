import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/destination_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<DestinationModel> _destinations = [];
  bool _loading = true;
  String? _error;

  static final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _client
          .from('destinations')
          .select()
          .order('name', ascending: true);
      final list =
          (data as List).map((e) => DestinationModel.fromJson(e)).toList();
      setState(() {
        _destinations = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleActive(DestinationModel d) async {
    try {
      await _client
          .from('destinations')
          .update({'is_active': !d.isActive}).eq('id', d.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _delete(DestinationModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar paquete'),
        content: Text('¿Eliminar "${d.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _client.from('destinations').delete().eq('id', d.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _openEdit(DestinationModel? d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DestinationForm(
        destination: d,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Panel administrador'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(null),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo paquete'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _destinations.length,
                  itemBuilder: (_, i) {
                    final d = _destinations[i];
                    return _DestinationTile(
                      destination: d,
                      onEdit: () => _openEdit(d),
                      onToggle: () => _toggleActive(d),
                      onDelete: () => _delete(d),
                    );
                  },
                ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _DestinationTile({
    required this.destination,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final d = destination;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: d.isActive
            ? null
            : Border.all(color: AppColors.mediumGray, width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                d.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.lightGray,
                  child: const Icon(Icons.image_not_supported_outlined,
                      size: 20, color: AppColors.mediumGray),
                ),
              ),
            ),
            title: Text(
              d.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: d.isActive ? AppColors.darkText : AppColors.darkGray,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.country} · ${d.category} · ${d.durationDays}d',
                  style: const TextStyle(fontSize: 11, color: AppColors.darkGray),
                ),
                Row(
                  children: [
                    Text(
                      '\$${(d.priceFrom / 1000).toStringAsFixed(0)}k COP',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBlue),
                    ),
                    if (d.isFeatured) ...[
                      const SizedBox(width: 6),
                      _Tag('Destacado', AppColors.gold),
                    ],
                    if (d.isPromotion) ...[
                      const SizedBox(width: 4),
                      _Tag('Promo', AppColors.turquoise),
                    ],
                    if (!d.isActive) ...[
                      const SizedBox(width: 4),
                      _Tag('Inactivo', AppColors.error),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'toggle') onToggle();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Editar')
                    ])),
                PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(
                          d.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(d.isActive ? 'Desactivar' : 'Activar')
                    ])),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Eliminar',
                          style: TextStyle(color: AppColors.error))
                    ])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------- FORM ----------

class _DestinationForm extends StatefulWidget {
  final DestinationModel? destination;
  final VoidCallback onSaved;

  const _DestinationForm({this.destination, required this.onSaved});

  @override
  State<_DestinationForm> createState() => _DestinationFormState();
}

class _DestinationFormState extends State<_DestinationForm> {
  static final _client = Supabase.instance.client;

  late final TextEditingController _name;
  late final TextEditingController _country;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _discount;
  late final TextEditingController _includes;
  late String _category;
  late bool _isFeatured;
  late bool _isPromotion;
  late bool _isActive;
  bool _saving = false;

  static const _categories = [
    'beach', 'city', 'adventure', 'cultural', 'international'
  ];
  static const _categoryLabels = {
    'beach': 'Playa',
    'city': 'Ciudad',
    'adventure': 'Aventura',
    'cultural': 'Cultural',
    'international': 'Internacional',
  };

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _name = TextEditingController(text: d?.name ?? '');
    _country = TextEditingController(text: d?.country ?? '');
    _description = TextEditingController(text: d?.description ?? '');
    _imageUrl = TextEditingController(text: d?.imageUrl ?? '');
    _price = TextEditingController(text: d != null ? d.priceFrom.toStringAsFixed(0) : '');
    _duration = TextEditingController(text: d?.durationDays.toString() ?? '');
    _discount = TextEditingController(text: d?.discountPercent?.toStringAsFixed(0) ?? '');
    _includes = TextEditingController(text: d != null ? d.includes.join(', ') : '');
    _category = d?.category ?? 'beach';
    _isFeatured = d?.isFeatured ?? false;
    _isPromotion = d?.isPromotion ?? false;
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _price.dispose();
    _duration.dispose();
    _discount.dispose();
    _includes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _country.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y país son obligatorios.')),
      );
      return;
    }
    setState(() => _saving = true);

    final includesList = _includes.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final payload = {
      'name': _name.text.trim(),
      'country': _country.text.trim(),
      'description': _description.text.trim(),
      'image_url': _imageUrl.text.trim(),
      'price_from': double.tryParse(_price.text.trim()) ?? 0,
      'duration_days': int.tryParse(_duration.text.trim()) ?? 0,
      'discount_percent': double.tryParse(_discount.text.trim()),
      'includes': includesList,
      'category': _category,
      'is_featured': _isFeatured,
      'is_promotion': _isPromotion,
      'is_active': _isActive,
      'currency': 'COP',
      'gallery': <String>[],
      'metadata': <String, dynamic>{},
    };

    try {
      if (widget.destination != null) {
        await _client
            .from('destinations')
            .update(payload)
            .eq('id', widget.destination!.id);
      } else {
        await _client.from('destinations').insert(payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.destination != null
                ? 'Paquete actualizado'
                : 'Paquete creado'),
            backgroundColor: AppColors.turquoise,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.destination != null ? 'Editar paquete' : 'Nuevo paquete',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(_name, 'Nombre del destino', required: true),
            const SizedBox(height: 12),
            _field(_country, 'País', required: true),
            const SizedBox(height: 12),
            _field(_description, 'Descripción', maxLines: 4),
            const SizedBox(height: 12),
            _field(_imageUrl, 'URL de imagen'),
            // Image preview
            if (_imageUrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrl.text,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      color: AppColors.lightGray,
                      child: const Center(
                          child: Text('URL de imagen inválida',
                              style: TextStyle(color: AppColors.error))),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_price, 'Precio (COP)', numeric: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_duration, 'Días', numeric: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_discount, 'Desc. %', numeric: true)),
              ],
            ),
            const SizedBox(height: 12),
            _field(_includes, 'Incluye (separado por comas)', maxLines: 2),
            const SizedBox(height: 12),
            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(_categoryLabels[c] ?? c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            // Toggles
            _SwitchRow('Destacado', _isFeatured,
                (v) => setState(() => _isFeatured = v)),
            _SwitchRow('Promoción', _isPromotion,
                (v) => setState(() => _isPromotion = v)),
            _SwitchRow(
                'Activo', _isActive, (v) => setState(() => _isActive = v)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar cambios',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.deepBlue,
        ),
      ],
    );
  }
}
