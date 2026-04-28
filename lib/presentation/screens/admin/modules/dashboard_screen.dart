import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static final _db = Supabase.instance.client;

  bool _loading = true;
  int _activePkgs = 0;
  int _activePromos = 0;
  int _users = 0;
  int _monthBookings = 0;
  int _pendingLeads = 0;
  int _pendingTestimonials = 0;
  int _activeCoupons = 0;
  int _pendingBookings = 0;
  int _confirmedBookings = 0;
  int _cancelledBookings = 0;
  final List<FlSpot> _trendSpots = [];
  final List<Map<String, dynamic>> _recentBookings = [];
  final List<Map<String, dynamic>> _recentLeads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _db.from('destinations').select('id', count: CountOption.exact).eq('is_active', true),
        _db.from('destinations').select('id', count: CountOption.exact).eq('is_promotion', true).eq('is_active', true),
        _db.from('profiles').select('id', count: CountOption.exact),
        _db.from('bookings').select('id', count: CountOption.exact).gte('created_at', monthStart.toIso8601String()),
        _db.from('leads').select('id', count: CountOption.exact).eq('status', 'nuevo'),
        _db.from('testimonials').select('id', count: CountOption.exact).eq('is_approved', false),
        _db.from('coupons').select('id', count: CountOption.exact).eq('is_active', true),
        _db.from('bookings').select('status'),
        _db.from('bookings').select('created_at').gte('created_at',
            now.subtract(const Duration(days: 56)).toIso8601String()),
        _db.from('bookings').select('id,destination_name,status,created_at,full_name').order('created_at', ascending: false).limit(5),
        _db.from('leads').select('id,full_name,destination_query,status,created_at').order('created_at', ascending: false).limit(5),
      ]);

      // Extract counts
      final pkgRes = results[0] as PostgrestResponse;
      final promoRes = results[1] as PostgrestResponse;
      final userRes = results[2] as PostgrestResponse;
      final bookMonthRes = results[3] as PostgrestResponse;
      final leadsRes = results[4] as PostgrestResponse;
      final testRes = results[5] as PostgrestResponse;
      final coupRes = results[6] as PostgrestResponse;

      // Booking status breakdown
      final statusList = (results[7] as List).cast<Map<String, dynamic>>();
      int pending = 0, confirmed = 0, cancelled = 0;
      for (final b in statusList) {
        final s = b['status'] as String? ?? '';
        if (s == 'pending') pending++;
        else if (s == 'confirmed') confirmed++;
        else if (s == 'cancelled') cancelled++;
      }

      // Trend: group last 8 weeks
      final allDates = (results[8] as List)
          .map((e) => DateTime.parse((e as Map)['created_at'] as String))
          .toList();
      final spots = <FlSpot>[];
      for (int w = 7; w >= 0; w--) {
        final weekStart = now.subtract(Duration(days: (w + 1) * 7));
        final weekEnd = now.subtract(Duration(days: w * 7));
        final count = allDates
            .where((d) => d.isAfter(weekStart) && d.isBefore(weekEnd))
            .length;
        spots.add(FlSpot((7 - w).toDouble(), count.toDouble()));
      }

      final recentBk = (results[9] as List).cast<Map<String, dynamic>>();
      final recentL = (results[10] as List).cast<Map<String, dynamic>>();

      setState(() {
        _activePkgs = pkgRes.count ?? 0;
        _activePromos = promoRes.count ?? 0;
        _users = userRes.count ?? 0;
        _monthBookings = bookMonthRes.count ?? 0;
        _pendingLeads = leadsRes.count ?? 0;
        _pendingTestimonials = testRes.count ?? 0;
        _activeCoupons = coupRes.count ?? 0;
        _pendingBookings = pending;
        _confirmedBookings = confirmed;
        _cancelledBookings = cancelled;
        _trendSpots
          ..clear()
          ..addAll(spots);
        _recentBookings
          ..clear()
          ..addAll(recentBk);
        _recentLeads
          ..clear()
          ..addAll(recentL);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title row
          Row(
            children: [
              const Text('Resumen general',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText)),
              const Spacer(),
              Text(DateFormat('d MMM yyyy', 'es').format(DateTime.now()),
                  style: const TextStyle(
                      color: AppColors.darkGray, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          // KPI grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _KpiCard('Paquetes activos', '$_activePkgs',
                  Icons.luggage_rounded, const Color(0xFF0B2F5C)),
              _KpiCard('Promociones', '$_activePromos',
                  Icons.local_offer_rounded, const Color(0xFFE65100)),
              _KpiCard('Usuarios', '$_users',
                  Icons.people_alt_rounded, const Color(0xFF4527A0)),
              _KpiCard('Reservas mes', '$_monthBookings',
                  Icons.calendar_today_rounded, const Color(0xFF00796B)),
              _KpiCard('Leads nuevos', '$_pendingLeads',
                  Icons.person_add_alt_1_rounded, const Color(0xFFC62828)),
              _KpiCard('Cupones activos', '$_activeCoupons',
                  Icons.discount_rounded, const Color(0xFFF9A825)),
            ],
          ),
          const SizedBox(height: 24),
          // Booking trend chart
          _SectionTitle('Reservas últimas 8 semanas'),
          const SizedBox(height: 12),
          _TrendChart(spots: _trendSpots),
          const SizedBox(height: 24),
          // Status breakdown
          _SectionTitle('Estado de reservas'),
          const SizedBox(height: 12),
          _StatusBreakdown(
            pending: _pendingBookings,
            confirmed: _confirmedBookings,
            cancelled: _cancelledBookings,
          ),
          const SizedBox(height: 24),
          // Pending alerts
          if (_pendingTestimonials > 0) ...[
            _AlertBanner(
              '$_pendingTestimonials testimonio(s) pendientes de aprobación',
              Icons.star_half_rounded,
              const Color(0xFFF9A825),
            ),
            const SizedBox(height: 8),
          ],
          // Recent bookings
          _SectionTitle('Reservas recientes'),
          const SizedBox(height: 12),
          _RecentList(
            items: _recentBookings,
            builder: (b) => _BookingTile(b),
          ),
          const SizedBox(height: 24),
          // Recent leads
          _SectionTitle('Leads recientes'),
          const SizedBox(height: 12),
          _RecentList(
            items: _recentLeads,
            builder: (l) => _LeadTile(l),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---- Widgets ----

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.darkGray,
                      height: 1.3),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText));
  }
}

class _TrendChart extends StatelessWidget {
  final List<FlSpot> spots;

  const _TrendChart({required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('Sin datos',
            style: TextStyle(color: AppColors.darkGray)),
      );
    }
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY + 2).ceilToDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.lightGray,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.darkGray)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final w = v.toInt();
                  if (w < 0 || w > 7) return const SizedBox();
                  final d = DateTime.now()
                      .subtract(Duration(days: (7 - w) * 7));
                  return Text('S${w + 1}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.darkGray));
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.deepBlue,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.deepBlue.withValues(alpha: 0.08),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.deepBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final int pending;
  final int confirmed;
  final int cancelled;

  const _StatusBreakdown(
      {required this.pending,
      required this.confirmed,
      required this.cancelled});

  @override
  Widget build(BuildContext context) {
    final total = pending + confirmed + cancelled;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: total == 0
          ? const Text('Sin reservas registradas',
              style: TextStyle(color: AppColors.darkGray))
          : Column(
              children: [
                _StatusRow('Pendientes', pending, total,
                    const Color(0xFFF9A825)),
                const SizedBox(height: 10),
                _StatusRow('Confirmadas', confirmed, total,
                    const Color(0xFF00796B)),
                const SizedBox(height: 10),
                _StatusRow('Canceladas', cancelled, total,
                    const Color(0xFFC62828)),
              ],
            ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusRow(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$count',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _AlertBanner(this.message, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) builder;

  const _RecentList({required this.items, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Sin registros',
            style: TextStyle(color: AppColors.darkGray)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          return Column(
            children: [
              builder(item),
              if (e.key < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16,
                    color: AppColors.lightGray),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Map<String, dynamic> b;

  const _BookingTile(this.b);

  @override
  Widget build(BuildContext context) {
    final status = b['status'] as String? ?? '';
    final color = status == 'confirmed'
        ? const Color(0xFF00796B)
        : status == 'cancelled'
            ? const Color(0xFFC62828)
            : const Color(0xFFF9A825);
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.luggage_rounded, size: 16, color: color),
      ),
      title: Text(b['full_name'] as String? ?? 'Cliente',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(b['destination_name'] as String? ?? '',
          style: const TextStyle(fontSize: 11)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(status,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      ),
    );
  }
}

class _LeadTile extends StatelessWidget {
  final Map<String, dynamic> l;

  const _LeadTile(this.l);

  @override
  Widget build(BuildContext context) {
    final status = l['status'] as String? ?? 'nuevo';
    final color = _statusColor(status);
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_outline, size: 16, color: color),
      ),
      title: Text(l['full_name'] as String? ?? '',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(l['destination_query'] as String? ?? '',
          style: const TextStyle(fontSize: 11)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(status,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'vendido': return const Color(0xFF00796B);
      case 'contactado': return const Color(0xFF1A4A8A);
      case 'perdido': return const Color(0xFFC62828);
      default: return const Color(0xFFF9A825);
    }
  }
}
