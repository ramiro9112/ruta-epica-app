import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _ofertas = true;
  bool _reservas = true;
  bool _novedades = false;
  bool _recordatorios = true;
  bool _loaded = false;

  static const _kOfertas = 'notif_ofertas';
  static const _kReservas = 'notif_reservas';
  static const _kNovedades = 'notif_novedades';
  static const _kRecordatorios = 'notif_recordatorios';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ofertas = prefs.getBool(_kOfertas) ?? true;
      _reservas = prefs.getBool(_kReservas) ?? true;
      _novedades = prefs.getBool(_kNovedades) ?? false;
      _recordatorios = prefs.getBool(_kRecordatorios) ?? true;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _loaded
          ? ListView(
              children: [
                const SizedBox(height: 16),
                _buildSection(
                  'Alertas de viaje',
                  [
                    _buildTile(
                      icon: Icons.local_offer_rounded,
                      color: AppColors.turquoise,
                      title: 'Ofertas y promociones',
                      subtitle: 'Descuentos exclusivos y paquetes especiales',
                      value: _ofertas,
                      onChanged: (v) {
                        setState(() => _ofertas = v);
                        _save(_kOfertas, v);
                      },
                    ),
                    _buildTile(
                      icon: Icons.luggage_rounded,
                      color: AppColors.deepBlue,
                      title: 'Mis reservas',
                      subtitle: 'Confirmaciones y actualizaciones de estado',
                      value: _reservas,
                      onChanged: (v) {
                        setState(() => _reservas = v);
                        _save(_kReservas, v);
                      },
                    ),
                    _buildTile(
                      icon: Icons.alarm_rounded,
                      color: AppColors.gold,
                      title: 'Recordatorios',
                      subtitle: 'Alertas antes de tu fecha de viaje',
                      value: _recordatorios,
                      onChanged: (v) {
                        setState(() => _recordatorios = v);
                        _save(_kRecordatorios, v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSection(
                  'Contenido',
                  [
                    _buildTile(
                      icon: Icons.newspaper_rounded,
                      color: AppColors.darkGray,
                      title: 'Novedades y tips',
                      subtitle: 'Guías de viaje y destinos nuevos',
                      value: _novedades,
                      onChanged: (v) {
                        setState(() => _novedades = v);
                        _save(_kNovedades, v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Las notificaciones push se activarán en una próxima actualización.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGray,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
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
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.deepBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
