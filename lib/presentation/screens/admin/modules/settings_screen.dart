import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  static final _db = Supabase.instance.client;
  bool _loading = true;
  bool _saving = false;
  Map<String, String> _values = {};
  Map<String, String> _labels = {};
  Map<String, String> _categories = {};

  static const _categoryOrder = ['contacto', 'home', 'redes', 'popup', 'faqs'];
  static const _categoryLabels = {
    'contacto': 'Contacto y soporte',
    'home': 'Pantalla de inicio',
    'redes': 'Redes sociales',
    'popup': 'Popup de bienvenida',
    'faqs': 'Preguntas frecuentes',
  };
  static const _categoryIcons = {
    'contacto': Icons.contact_phone_rounded,
    'home': Icons.home_rounded,
    'redes': Icons.share_rounded,
    'popup': Icons.campaign_rounded,
    'faqs': Icons.help_outline_rounded,
  };
  static const _categoryColors = {
    'contacto': Color(0xFF00796B),
    'home': AppColors.deepBlue,
    'redes': Color(0xFF6A1B9A),
    'popup': Color(0xFFE65100),
    'faqs': Color(0xFFF9A825),
  };

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db.from('app_settings').select();
      final vals = <String, String>{};
      final labs = <String, String>{};
      final cats = <String, String>{};
      for (final row in data) {
        final key = row['key'] as String;
        vals[key] = row['value'] as String? ?? '';
        labs[key] = row['label'] as String? ?? key;
        cats[key] = row['category'] as String? ?? 'general';
        _controllers[key] ??= TextEditingController();
        _controllers[key]!.text = vals[key]!;
      }
      if (mounted) setState(() {
        _values = vals; _labels = labs; _categories = cats; _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      for (final entry in _controllers.entries) {
        await _db.from('app_settings')
            .update({'value': entry.value.text, 'updated_at': DateTime.now().toIso8601String()})
            .eq('key', entry.key);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Configuración guardada'),
          backgroundColor: Color(0xFF00796B),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    ..._categoryOrder.map((cat) {
                      final keys = _controllers.keys.where((k) => _categories[k] == cat).toList();
                      if (keys.isEmpty) return const SizedBox.shrink();
                      return _CategorySection(
                        category: cat,
                        label: _categoryLabels[cat] ?? cat,
                        icon: _categoryIcons[cat] ?? Icons.settings_rounded,
                        color: _categoryColors[cat] ?? AppColors.deepBlue,
                        children: keys.map((key) => _SettingField(
                          settingKey: key,
                          label: _labels[key] ?? key,
                          controller: _controllers[key]!,
                          isBool: key == 'popup_active',
                          isMultiline: key.endsWith('_a') || key == 'hero_subtitle',
                        )).toList(),
                      );
                    }),
                    // Keys not in defined categories
                    ..._controllers.keys.where((k) {
                      final cat = _categories[k];
                      return cat == null || cat == 'general' || !_categoryOrder.contains(cat);
                    }).map((key) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: _SettingField(
                        settingKey: key,
                        label: _labels[key] ?? key,
                        controller: _controllers[key]!,
                        isBool: false, isMultiline: false,
                      ),
                    )),
                  ],
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
                    ),
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Guardar todos los cambios',
                              style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final String category;
  final String label;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _CategorySection({
    required this.category, required this.label, required this.icon,
    required this.color, required this.children,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(10)),
                  child: Icon(widget.icon, size: 18, color: AppColors.white)),
                const SizedBox(width: 12),
                Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: widget.color)),
                const Spacer(),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: widget.color),
              ]),
            ),
          ),
          if (_expanded) Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: widget.children),
          ),
        ],
      ),
    );
  }
}

class _SettingField extends StatefulWidget {
  final String settingKey;
  final String label;
  final TextEditingController controller;
  final bool isBool;
  final bool isMultiline;

  const _SettingField({
    required this.settingKey, required this.label, required this.controller,
    required this.isBool, required this.isMultiline,
  });

  @override
  State<_SettingField> createState() => _SettingFieldState();
}

class _SettingFieldState extends State<_SettingField> {
  @override
  Widget build(BuildContext context) {
    if (widget.isBool) {
      final isTrue = widget.controller.text == 'true';
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SwitchListTile(
          value: isTrue,
          onChanged: (v) {
            widget.controller.text = v ? 'true' : 'false';
            setState(() {});
          },
          title: Text(widget.label, style: const TextStyle(fontSize: 14)),
          activeColor: AppColors.deepBlue,
          contentPadding: EdgeInsets.zero,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller,
        maxLines: widget.isMultiline ? 3 : 1,
        keyboardType: widget.settingKey.contains('phone') || widget.settingKey.contains('number')
            ? TextInputType.phone
            : widget.settingKey.contains('email') ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: widget.label,
          filled: true, fillColor: const Color(0xFFF8F9FC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.deepBlue)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
