import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/shared/widgets/salon_notification_dialog.dart';
import 'package:ruvexi_mobile/shared/widgets/branch_switcher_sheet.dart';
import 'package:ruvexi_mobile/features/expenses/screens/expenses_screen.dart';
import 'package:ruvexi_mobile/features/staff/screens/staff_management_screen.dart';
import 'package:ruvexi_mobile/features/inventory/screens/inventory_screen.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  final RuvexiAppState appState;

  const ReportsAnalyticsScreen({super.key, required this.appState});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  int _selectedChip = 0; // 0: Revenue, 1: Services, 2: Staff, 3: Inventory
  String _selectedPeriod = "This Month";
  Map<String, dynamic>? _summary;
  bool _isLoading = false;
  String? _lastBranchId;

  String get _rangeKey {
    switch (_selectedPeriod) {
      case "Today":
        return "today";
      case "This Week":
        return "week";
      default:
        return "month";
    }
  }

  @override
  void initState() {
    super.initState();
    _lastBranchId = widget.appState.activeBranch?.id;
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await widget.appState.api.fetchReportsSummary(
        range: _rangeKey,
        branchId: widget.appState.activeBranch?.id,
      );
      if (mounted) {
        setState(() {
          _summary = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReportDetailsModal(String title, {required double revenue, required double profit, required int invoiceCount}) {
    final branchName = widget.appState.activeBranch?.name ?? widget.appState.salonName;
    final summaryText =
        "$title ($branchName • $_selectedPeriod)\n"
        "Invoices: $invoiceCount\n"
        "Gross Revenue: ₹${revenue.toStringAsFixed(0)}\n"
        "Net Profit: ₹${profit.toStringAsFixed(0)}";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101311),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Live ledger for $branchName ($_selectedPeriod): $invoiceCount paid invoices totaling ₹${revenue.toStringAsFixed(0)} gross revenue and ₹${profit.toStringAsFixed(0)} net profit.",
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy_rounded, color: Colors.black, size: 18),
                label: const Text("Copy Report Summary", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: summaryText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Live report summary copied to clipboard")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final activeBranch = widget.appState.activeBranch;
        if (activeBranch?.id != _lastBranchId) {
          _lastBranchId = activeBranch?.id;
          WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSummary());
        }

        final branchInvs = widget.appState.branchInvoices;
        double localRev = branchInvs
            .where((i) => (i['status'] ?? '').toString().toLowerCase() == 'paid')
            .fold(0.0, (sum, i) => sum + ((i['grandTotal'] is num) ? (i['grandTotal'] as num).toDouble() : 0.0));
        if (localRev == 0.0 && widget.appState.todayRevenue > 0) {
          localRev = widget.appState.todayRevenue;
        }

        final metrics = (_summary?['metrics'] is Map) ? Map<String, dynamic>.from(_summary!['metrics']) : <String, dynamic>{};
        final double branchRev = (metrics['grossRevenue'] is num)
            ? (metrics['grossRevenue'] as num).toDouble()
            : localRev;
        final double branchExp = (metrics['totalExpenses'] is num)
            ? (metrics['totalExpenses'] as num).toDouble()
            : widget.appState.branchTotalExpenses;
        final double branchProfit = (metrics['netProfit'] is num)
            ? (metrics['netProfit'] as num).toDouble()
            : (branchRev - branchExp).clamp(0.0, double.infinity);
        final int branchServicesCount = (metrics['appointmentsCount'] is num)
            ? (metrics['appointmentsCount'] as num).toInt()
            : widget.appState.branchAppointments.length;
        final int paidInvoicesCount = (metrics['invoicesCount'] is num)
            ? (metrics['invoicesCount'] as num).toInt()
            : branchInvs.where((i) => (i['status'] ?? '').toString().toLowerCase() == 'paid').length;
        final double growthPct = (metrics['growthPercentage'] is num)
            ? (metrics['growthPercentage'] as num).toDouble()
            : 0.0;
        final String growthLabel = growthPct > 0
            ? "+${growthPct.toStringAsFixed(1)}%"
            : "${growthPct.toStringAsFixed(1)}%";
        final bool isPositiveGrowth = growthPct >= 0;

        final rawTrend = (_summary?['revenueTrend'] as List?) ?? [];
        final List<double> trendPoints = rawTrend
            .whereType<Map>()
            .map((e) => (e['amount'] is num) ? (e['amount'] as num).toDouble() : 0.0)
            .toList();

        final branchClientsCount = widget.appState.visibleCustomers.length;
        final branchChairs = widget.appState.salonChairs > 0 ? widget.appState.salonChairs : 8;
        final occupancyPct = widget.appState.seatsInUseCount > 0
            ? ((widget.appState.seatsInUseCount / branchChairs) * 100).toInt().clamp(0, 100)
            : 0;

        return Scaffold(
          backgroundColor: const Color(0xFF060706),
          appBar: AppBar(
            backgroundColor: const Color(0xFF060706),
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Reports",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.appState.branches.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  BranchTopDropdownPill(appState: widget.appState),
                ],
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                color: const Color(0xFF141815),
                onSelected: (val) {
                  setState(() => _selectedPeriod = val);
                  _fetchSummary();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: "Today", child: Text("Today", style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: "This Week", child: Text("This Week", style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: "This Month", child: Text("This Month", style: TextStyle(color: Colors.white))),
                ],
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141815),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedPeriod, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
                tooltip: "Salon Alerts",
                onPressed: () => showSalonNotificationModal(context, widget.appState),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF22C55E),
            onRefresh: _fetchSummary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter chips: Revenue, Services, Staff, Inventory
                  Row(
                    children: [
                      _buildChip(0, "Revenue"),
                      const SizedBox(width: 8),
                      _buildChip(1, "Services"),
                      const SizedBox(width: 8),
                      _buildChip(2, "Staff"),
                      const SizedBox(width: 8),
                      _buildChip(3, "Inventory"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hero Card with Branch Total Revenue & Real Data Line Chart
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101311),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Total Revenue",
                                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                                    ),
                                    if (activeBranch != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E2620),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          activeBranch.name,
                                          style: const TextStyle(color: Color(0xFF22C55E), fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                    if (_isLoading) ...[
                                      const SizedBox(width: 8),
                                      const SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF22C55E)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${branchRev.toInt()}",
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPositiveGrowth ? const Color(0xFF122C1A) : const Color(0xFF2C1215),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                growthLabel,
                                style: TextStyle(
                                  color: isPositiveGrowth ? const Color(0xFF22C55E) : Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Real Database Trend Line Chart
                        SizedBox(
                          height: 80,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _NeonWavePainter(points: trendPoints),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4 Metric cards in 2x2 grid (Scoped to Active Branch)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.calendar_today_outlined,
                          value: "$branchServicesCount",
                          label: "Appointments",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.people_outline_rounded,
                          value: "$branchClientsCount",
                          label: "Branch Clients",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.trending_up_rounded,
                          value: "₹${branchProfit.toInt()}",
                          label: "Net Profit",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.access_time_rounded,
                          value: "$occupancyPct%",
                          label: "Live Occupancy",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Active Chip Live Breakdown Card
                  _buildChipBreakdownCard(paidInvoicesCount),
                  const SizedBox(height: 16),

                  // Drill-down list items
                  _buildDrillDownTile(
                    "Sales Report",
                    Icons.receipt_long_outlined,
                    () => _showReportDetailsModal("Sales Report", revenue: branchRev, profit: branchProfit, invoiceCount: paidInvoicesCount),
                  ),
                  _buildDrillDownTile(
                    "Service Report",
                    Icons.pie_chart_outline_rounded,
                    () => _showReportDetailsModal("Service Report", revenue: branchRev, profit: branchProfit, invoiceCount: paidInvoicesCount),
                  ),
                  _buildDrillDownTile("Staff Performance", Icons.badge_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StaffManagementScreen(appState: widget.appState)),
                    );
                  }),
                  _buildDrillDownTile("Inventory Report", Icons.inventory_2_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InventoryScreen(appState: widget.appState)),
                    );
                  }),
                  _buildDrillDownTile("Salon Expenses", Icons.account_balance_wallet_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ExpensesScreen(appState: widget.appState)),
                    );
                  }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipBreakdownCard(int paidInvoicesCount) {
    final paymentBreakdown = (_summary?['paymentBreakdown'] is Map)
        ? Map<String, dynamic>.from(_summary!['paymentBreakdown'])
        : <String, dynamic>{};
    final topServices = (_summary?['serviceBreakdown'] is Map && _summary!['serviceBreakdown']['topServices'] is List)
        ? List<Map<String, dynamic>>.from(
            (_summary!['serviceBreakdown']['topServices'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];
    final staffPerf = (_summary?['staffPerformance'] is List)
        ? List<Map<String, dynamic>>.from(
            (_summary!['staffPerformance'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];

    String title = "Payment Breakdown ($paidInvoicesCount Bills)";
    List<Widget> rows = [];

    if (_selectedChip == 0) {
      final modes = ["UPI", "Cash", "Card", "Split", "Wallet"];
      for (final mode in modes) {
        final val = (paymentBreakdown[mode] is num) ? (paymentBreakdown[mode] as num).toDouble() : 0.0;
        rows.add(_breakdownRow(mode, "₹${val.toStringAsFixed(0)}"));
      }
    } else if (_selectedChip == 1) {
      title = "Top Services ($_selectedPeriod)";
      if (topServices.isEmpty) {
        rows.add(const Text("No billed services in this period yet.", style: TextStyle(color: Colors.white54, fontSize: 12)));
      } else {
        for (final s in topServices.take(5)) {
          final rev = (s['revenue'] is num) ? (s['revenue'] as num).toDouble() : 0.0;
          final bookings = (s['bookings'] is num) ? (s['bookings'] as num).toInt() : 0;
          rows.add(_breakdownRow("${s['name']} ($bookings)", "₹${rev.toStringAsFixed(0)}"));
        }
      }
    } else if (_selectedChip == 2) {
      title = "Staff Revenue Performance";
      if (staffPerf.isEmpty) {
        rows.add(const Text("No staff billing recorded in this period yet.", style: TextStyle(color: Colors.white54, fontSize: 12)));
      } else {
        for (final st in staffPerf.take(5)) {
          final rev = (st['revenue'] is num) ? (st['revenue'] as num).toDouble() : 0.0;
          final cnt = (st['servicesCount'] is num) ? (st['servicesCount'] as num).toInt() : 0;
          rows.add(_breakdownRow("${st['staffName']} ($cnt)", "₹${rev.toStringAsFixed(0)}"));
        }
      }
    } else {
      title = "Live Inventory Snapshot";
      final items = widget.appState.inventory;
      final lowStock = items.where((i) => i.stock <= i.minAlert).length;
      rows.add(_breakdownRow("Total SKUs", "${items.length}"));
      rows.add(_breakdownRow("Low Stock Alerts", "$lowStock"));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101311),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
          Text(value, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChip(int index, String label) {
    final isSelected = _selectedChip == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChip = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF101311),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101311),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF22C55E), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillDownTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF101311),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF22C55E), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NeonWavePainter extends CustomPainter {
  final List<double> points;

  _NeonWavePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.length >= 2 ? points : List<double>.filled(6, 0.0);
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    final offsets = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width : (i / (values.length - 1)) * size.width;
      final normalized = maxVal > 0 ? (values[i] / maxVal).clamp(0.0, 1.0) : 0.0;
      final y = size.height * (0.85 - normalized * 0.70);
      offsets.add(Offset(x, y));
    }

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill under curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF22C55E).withOpacity(0.35),
          const Color(0xFF22C55E).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Dot at latest point
    final dotPaint = Paint()..color = const Color(0xFF22C55E);
    canvas.drawCircle(offsets.last, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonWavePainter oldDelegate) => oldDelegate.points != points;
}
