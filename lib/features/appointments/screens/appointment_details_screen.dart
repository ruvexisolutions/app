import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';
import 'package:ruvexi_mobile/features/pos/screens/checkout_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final RuvexiAppState appState;
  final Appointment appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appState,
    required this.appointment,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late Appointment _appt;

  @override
  void initState() {
    super.initState();
    _appt = widget.appointment;
  }

  void _showActionToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF181C19),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: RuvexiTheme.primaryAccent, width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reschedule() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_appt.time),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: RuvexiTheme.primaryAccent,
              surface: Color(0xFF141815),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final newDateTime = DateTime(
        _appt.time.year,
        _appt.time.month,
        _appt.time.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      setState(() {
        _appt = Appointment(
          id: _appt.id,
          customerName: _appt.customerName,
          customerPhone: _appt.customerPhone,
          serviceName: _appt.serviceName,
          staffName: _appt.staffName,
          time: newDateTime,
          durationMinutes: _appt.durationMinutes,
          price: _appt.price,
          status: "Confirmed",
          notes: _appt.notes,
        );
      });
      _showActionToast("Appointment rescheduled to ${pickedTime.format(context)}");
    }
  }

  void _startService() {
    setState(() {
      _appt.status = "In Service";
    });
    widget.appState.updateAppointmentStatus(_appt.id, "In Service");
    _showActionToast("Service started for ${_appt.customerName}!");
  }

  void _proceedToCheckout() {
    // 1. Find or create matching Customer
    Customer? existingCustomer;
    for (final c in widget.appState.customers) {
      if (c.phone == _appt.customerPhone || (c.name.isNotEmpty && c.name.toLowerCase() == _appt.customerName.toLowerCase())) {
        existingCustomer = c;
        break;
      }
    }
    final customer = existingCustomer ?? Customer(
      id: 'cst_${DateTime.now().millisecondsSinceEpoch}',
      name: _appt.customerName,
      phone: _appt.customerPhone,
      email: '',
      visitsCount: 1,
      totalSpent: _appt.price,
      tag: 'Appointment',
    );
    if (existingCustomer == null) {
      widget.appState.addCustomer(customer);
    }
    widget.appState.posSelectedCustomer = customer;

    // 2. Find or create matching ServiceItem
    ServiceItem? matchedService;
    for (final s in widget.appState.catalog) {
      if (s.name.toLowerCase() == _appt.serviceName.toLowerCase()) {
        matchedService = s;
        break;
      }
    }
    final service = matchedService ?? ServiceItem(
      id: 'srv_appt_${DateTime.now().millisecondsSinceEpoch}',
      name: _appt.serviceName,
      price: _appt.price > 0 ? _appt.price : 300.0,
      durationMinutes: _appt.durationMinutes > 0 ? _appt.durationMinutes : 45,
      category: 'Haircut',
    );

    // 3. Populate POS Cart
    widget.appState.posCart.clear();
    widget.appState.posCart.add(CartItem(
      service: service,
      quantity: 1,
    ));

    // 4. Mark appointment as In Service
    widget.appState.updateAppointmentStatus(_appt.id, "In Service");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _appt.customerName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();

    return Scaffold(
      backgroundColor: const Color(0xFF060706),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060706),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Appointment Details",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
            onPressed: () => _reschedule(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF101311),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: RuvexiTheme.primaryAccent),
                        title: const Text("Mark as Completed", style: TextStyle(color: Colors.white)),
                        onTap: () {
                          widget.appState.updateAppointmentStatus(_appt.id, "Completed");
                          Navigator.pop(ctx);
                          _showActionToast("Marked as Completed");
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        title: const Text("Cancel Appointment", style: TextStyle(color: Colors.redAccent)),
                        onTap: () {
                          widget.appState.updateAppointmentStatus(_appt.id, "Cancelled");
                          Navigator.pop(ctx);
                          _showActionToast("Appointment cancelled");
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF122C1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
              ),
              child: Text(
                _appt.status,
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Customer Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101311),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF312E81),
                    child: Text(
                      initials,
                      style: const TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appt.customerName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _appt.customerPhone,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Phone Call Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_outlined, color: Colors.white70, size: 18),
                    ),
                    onPressed: () => _showActionToast("Calling ${_appt.customerPhone}..."),
                  ),
                  // WhatsApp Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 18),
                    ),
                    onPressed: () => _showActionToast("Opening WhatsApp with ${_appt.customerName}..."),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Service details
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF101311),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.content_cut_rounded, color: RuvexiTheme.primaryAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _appt.serviceName,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        "₹${_appt.price.toInt()}",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Color(0xFF1C221E), height: 1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: RuvexiTheme.primaryAccent, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appt.staffName,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Senior Stylist",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Color(0xFF1C221E), height: 1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: RuvexiTheme.primaryAccent, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tue, 09 Nov 2026",
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${TimeOfDay.fromDateTime(_appt.time).format(context)} (${_appt.durationMinutes} mins)",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101311),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description_outlined, color: Colors.white54, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _appt.notes.isNotEmpty ? _appt.notes : "No special instructions recorded.",
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Action Buttons
            if (_appt.status == "Completed")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _proceedToCheckout,
                  icon: const Icon(Icons.receipt_long, color: Colors.black, size: 18),
                  label: const Text(
                    "Re-Open / Generate New Bill",
                    style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _proceedToCheckout,
                      icon: const Icon(Icons.point_of_sale_rounded, color: Colors.black, size: 18),
                      label: Text(
                        _appt.price > 0
                            ? "Proceed to Billing (₹${_appt.price.toStringAsFixed(0)})"
                            : "Proceed to Billing & Checkout",
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reschedule,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: Colors.transparent,
                          ),
                          child: const Text(
                            "Reschedule",
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      if (_appt.status != "In Service") ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _startService,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF22C55E), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: const Color(0xFF101311),
                            ),
                            child: const Text(
                              "Start Service",
                              style: TextStyle(color: Color(0xFF22C55E), fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

