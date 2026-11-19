import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';

class SalonOnboardingSheet extends StatefulWidget {
  final RuvexiAppState appState;
  final void Function(int targetTab)? onComplete;

  const SalonOnboardingSheet({
    super.key,
    required this.appState,
    this.onComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required RuvexiAppState appState,
    void Function(int targetTab)? onComplete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101211),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: Color(0xFFFACC15), width: 1.2),
      ),
      builder: (_) => SalonOnboardingSheet(
        appState: appState,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<SalonOnboardingSheet> createState() => _SalonOnboardingSheetState();
}

class _SalonOnboardingSheetState extends State<SalonOnboardingSheet> {
  int _step = 1; // 1: Salon & Branch, 2: UPI Billing, 3: First Service, 4: Ready for billing

  // Step 1: Salon & Branch
  late final TextEditingController _salonNameCtrl;
  late final TextEditingController _branchNameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  int _chairs = 6;

  // Step 2: Billing & UPI
  late final TextEditingController _upiIdCtrl;
  late final TextEditingController _payeeNameCtrl;

  // Step 3: First Service
  final _serviceNameCtrl = TextEditingController(text: "Signature Haircut & Styling");
  final _servicePriceCtrl = TextEditingController(text: "450");
  final _serviceDurationCtrl = TextEditingController(text: "30");
  String _serviceCategory = "Hair";

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _salonNameCtrl = TextEditingController(text: widget.appState.salonName == "Ruvexi Salon & Spa" ? "" : widget.appState.salonName);
    _branchNameCtrl = TextEditingController(text: widget.appState.activeBranchName.isEmpty ? "Main Studio" : widget.appState.activeBranchName);
    _cityCtrl = TextEditingController(text: widget.appState.salonCity);
    _addressCtrl = TextEditingController(text: widget.appState.salonAddress);
    _phoneCtrl = TextEditingController(text: widget.appState.salonPhone);
    _upiIdCtrl = TextEditingController(text: widget.appState.salonUpiId);
    _payeeNameCtrl = TextEditingController(text: widget.appState.salonName);
  }

  @override
  void dispose() {
    _salonNameCtrl.dispose();
    _branchNameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _upiIdCtrl.dispose();
    _payeeNameCtrl.dispose();
    _serviceNameCtrl.dispose();
    _servicePriceCtrl.dispose();
    _serviceDurationCtrl.dispose();
    super.dispose();
  }

  void _validateAndProceedToStep2() {
    setState(() => _errorMessage = null);
    if (_salonNameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter your Salon / Studio name.");
      return;
    }
    if (_branchNameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter your first branch / outlet name.");
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().length < 7) {
      setState(() => _errorMessage = "Please enter a valid salon phone number.");
      return;
    }
    if (_cityCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter city and full street address.");
      return;
    }
    if (_payeeNameCtrl.text.trim().isEmpty) {
      _payeeNameCtrl.text = _salonNameCtrl.text.trim();
    }
    setState(() => _step = 2);
  }

  void _validateAndProceedToStep3() {
    setState(() => _errorMessage = null);
    final upi = _upiIdCtrl.text.trim();
    if (upi.isEmpty || !upi.contains('@')) {
      setState(() => _errorMessage = "A valid UPI ID (e.g. salon@okaxis or 9876543210@ybl) is required for billing.");
      return;
    }
    setState(() => _step = 3);
  }

  Future<void> _handleCompleteOnboarding() async {
    setState(() => _errorMessage = null);
    if (_serviceNameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter your first service name.");
      return;
    }
    final price = double.tryParse(_servicePriceCtrl.text.trim());
    if (price == null || price < 0) {
      setState(() => _errorMessage = "Please enter a valid price in ₹.");
      return;
    }
    final duration = int.tryParse(_serviceDurationCtrl.text.trim());
    if (duration == null || duration < 5) {
      setState(() => _errorMessage = "Please enter duration (minimum 5 mins).");
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Update Salon details + UPI ID
      await widget.appState.updateSalonDetails(
        name: _salonNameCtrl.text.trim(),
        branch: _branchNameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        chairs: _chairs,
      );

      await widget.appState.updateSalonPaymentSettings(
        upiId: _upiIdCtrl.text.trim(),
        payeeName: _payeeNameCtrl.text.trim().isNotEmpty ? _payeeNameCtrl.text.trim() : _salonNameCtrl.text.trim(),
      );

      // 2. Add First Service to catalog
      final newService = ServiceItem(
        id: "srv_${DateTime.now().millisecondsSinceEpoch}",
        name: _serviceNameCtrl.text.trim(),
        category: _serviceCategory,
        price: price,
        durationMinutes: duration,
        description: "Standard ${_serviceCategory.toLowerCase()} service",
        popular: true,
      );
      await widget.appState.addService(newService);

      setState(() {
        _isSaving = false;
        _step = 4; // Celebration step
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('RuvexiApiException:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Indicator
            if (_step < 4) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Step $_step of 3: ${_step == 1 ? "Salon & First Branch" : _step == 2 ? "Billing & Direct UPI" : "Add First Service"}",
                    style: const TextStyle(
                      color: Color(0xFFFACC15),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _step / 3.0,
                backgroundColor: const Color(0xFF1F2220),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
            ],

            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // STEP 1
            if (_step == 1) _buildStep1(),

            // STEP 2
            if (_step == 2) _buildStep2(),

            // STEP 3
            if (_step == 3) _buildStep3(),

            // STEP 4: Celebration
            if (_step == 4) _buildStep4(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Set Up Your Studio & First Branch",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Enter your core salon details and primary branch location.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5),
        ),
        const SizedBox(height: 16),

        _buildTextField(_salonNameCtrl, "Salon / Studio Name *", Icons.store_rounded, hint: "e.g. Aura Luxury Hair & Spa"),
        const SizedBox(height: 12),
        _buildTextField(_branchNameCtrl, "First Branch Name *", Icons.location_on_outlined, hint: "e.g. Main Studio / Chikmagalur"),
        const SizedBox(height: 12),
        _buildTextField(_phoneCtrl, "Business Phone Number *", Icons.phone_android_rounded, hint: "+91 98765 43210", keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(_cityCtrl, "City *", Icons.location_city_rounded, hint: "e.g. Chikmagalur")),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141715),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF272B28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chair_alt_rounded, color: Color(0xFFFACC15), size: 18),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _chairs,
                    dropdownColor: const Color(0xFF141715),
                    underline: const SizedBox(),
                    items: [4, 6, 8, 12, 16].map((c) => DropdownMenuItem(value: c, child: Text("$c Chairs", style: const TextStyle(color: Colors.white, fontSize: 12.5)))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _chairs = v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(_addressCtrl, "Street Address / Area *", Icons.map_rounded, hint: "100ft Road, Basavanahalli"),
        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _validateAndProceedToStep2,
            child: const Text("Continue to Billing Setup →", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Billing & Direct Settlement",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Enter your UPI ID so customer billing QR codes credit 100% directly to your salon bank account.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          _upiIdCtrl,
          "Salon UPI ID (Required for QR Billing) *",
          Icons.qr_code_rounded,
          hint: "e.g. salonname@okaxis or 8296294666@ybl",
          isAccent: true,
        ),
        const SizedBox(height: 12),
        _buildTextField(_payeeNameCtrl, "Payee / Account Name", Icons.account_balance_rounded, hint: "e.g. OLG Unisex Salon"),
        const SizedBox(height: 22),

        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF272B28)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: () => setState(() => _step = 1),
              child: const Text("← Back", style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _validateAndProceedToStep3,
                child: const Text("Add First Service →", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final categories = ["Hair", "Beard & Grooming", "Skin & Spa", "Facial", "Massage", "Nails"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add Your First Service",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Add at least one service so your front desk can immediately bill walk-in clients.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5),
        ),
        const SizedBox(height: 16),

        _buildTextField(_serviceNameCtrl, "Service Name *", Icons.content_cut_rounded, hint: "e.g. Classic Haircut & Wash"),
        const SizedBox(height: 12),

        // Category selection
        const Text("Category", style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: categories.map((cat) {
            final isSelected = _serviceCategory == cat;
            return ChoiceChip(
              label: Text(cat, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              selectedColor: const Color(0xFFFACC15),
              backgroundColor: const Color(0xFF141715),
              side: BorderSide(color: isSelected ? const Color(0xFFFACC15) : const Color(0xFF272B28)),
              onSelected: (val) {
                if (val) setState(() => _serviceCategory = cat);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildTextField(_servicePriceCtrl, "Price (₹) *", Icons.currency_rupee_rounded, hint: "450", keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(_serviceDurationCtrl, "Duration (Mins) *", Icons.timer_outlined, hint: "30", keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 22),

        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF272B28)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: () => setState(() => _step = 2),
              child: const Text("← Back", style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : _handleCompleteOnboarding,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("Complete & Launch Studio", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF22C55E), width: 2),
          ),
          child: const Icon(Icons.celebration_rounded, color: Color(0xFF22C55E), size: 38),
        ),
        const SizedBox(height: 16),
        const Text(
          "You're Ready for Billing!",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Your first branch, direct UPI settlements, and initial service catalog are successfully linked. Register your first customer on Ruvexi to create your first invoice!",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Summary box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141715),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF272B28)),
          ),
          child: Column(
            children: [
              _buildSummaryRow("Salon & Outlet", "${_salonNameCtrl.text.trim()} (${_branchNameCtrl.text.trim()})"),
              const Divider(color: Color(0xFF272B28), height: 16),
              _buildSummaryRow("Direct UPI ID", _upiIdCtrl.text.trim(), isEmerald: true),
              const Divider(color: Color(0xFF272B28), height: 16),
              _buildSummaryRow("First Service", "${_serviceNameCtrl.text.trim()} • ₹${_servicePriceCtrl.text.trim()}", isGold: true),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete?.call(2); // Navigates to POS billing & registering customer
            },
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.black, size: 20),
            label: const Text(
              "Register Your First Customer",
              style: TextStyle(color: Colors.black, fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onComplete?.call(0);
          },
          child: const Text("Go to Overview Dashboard", style: TextStyle(color: Colors.white54, fontSize: 12.5)),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isEmerald = false, bool isGold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: isEmerald ? const Color(0xFF22C55E) : (isGold ? const Color(0xFFFACC15) : Colors.white),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              fontFamily: isEmerald ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isAccent = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isAccent ? const Color(0xFF22C55E) : Colors.white70, fontSize: 11.5, fontWeight: isAccent ? FontWeight.bold : FontWeight.w500)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141715),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isAccent ? const Color(0xFF22C55E).withValues(alpha: 0.6) : const Color(0xFF272B28), width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: isAccent ? const Color(0xFF22C55E) : Colors.white, fontSize: 13.5, fontFamily: isAccent ? 'monospace' : null, fontWeight: isAccent ? FontWeight.bold : FontWeight.normal),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12.5),
              prefixIcon: Icon(icon, color: isAccent ? const Color(0xFF22C55E) : Colors.white54, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
