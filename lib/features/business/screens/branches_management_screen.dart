import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';

class BranchesManagementScreen extends StatefulWidget {
  final RuvexiAppState appState;

  const BranchesManagementScreen({super.key, required this.appState});

  @override
  State<BranchesManagementScreen> createState() => _BranchesManagementScreenState();
}

class _BranchesManagementScreenState extends State<BranchesManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    await widget.appState.fetchBranches();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddBranchDialog() {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: widget.appState.salonLocation.isNotEmpty ? widget.appState.salonLocation : "Chikmagalur");
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final upiIdCtrl = TextEditingController();
    final upiPayeeCtrl = TextEditingController();
    int chairs = 6;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF101311),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF22C55E), width: 1),
          ),
          title: Row(
            children: const [
              Icon(Icons.store_mall_directory_outlined, color: Color(0xFF22C55E), size: 22),
              SizedBox(width: 8),
              Text(
                "Add New Branch Outlet",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Configure an additional salon studio, flagship outlet, or express kiosk.",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Branch Name *",
                    hintText: "e.g. Indiranagar Studio, Chickmagalur Flagship",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "City / Region *",
                    hintText: "e.g. Chikmagalur, Bengaluru, Mumbai",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Street Address",
                    hintText: "e.g. 401 Crescent Galleria, Aralimara Road",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Outlet Contact Number",
                    hintText: "+91 82962 94666",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: upiIdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Branch UPI ID (Optional)",
                    hintText: "Leave blank to use salon default UPI",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: upiPayeeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Branch UPI Payee Name (Optional)",
                    hintText: "e.g. Ruvexi Indiranagar",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Styling Chairs / Stations:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3822),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF22C55E)),
                      ),
                      child: Text("$chairs Chairs", style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                Slider(
                  value: chairs.toDouble(),
                  min: 1,
                  max: 24,
                  divisions: 23,
                  activeColor: const Color(0xFF22C55E),
                  inactiveColor: Colors.white24,
                  onChanged: (val) => setDlgState(() => chairs = val.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final city = cityCtrl.text.trim();
                      if (name.isEmpty || city.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Branch Name and City are required"), backgroundColor: Colors.amber),
                        );
                        return;
                      }

                      setDlgState(() => isSubmitting = true);
                      try {
                        await widget.appState.createBranch(
                          name: name,
                          city: city,
                          address: addressCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          chairs: chairs,
                          upiId: upiIdCtrl.text.trim(),
                          upiPayeeName: upiPayeeCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Branch '$name' created successfully!")),
                        );
                        setState(() {});
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to create branch: $e"), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("Create Branch", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBranchDialog(SalonBranch branch) {
    final nameCtrl = TextEditingController(text: branch.name);
    final cityCtrl = TextEditingController(text: branch.city);
    final addressCtrl = TextEditingController(text: branch.address);
    final phoneCtrl = TextEditingController(text: branch.phone);
    final upiIdCtrl = TextEditingController(text: branch.upiId);
    final upiPayeeCtrl = TextEditingController(text: branch.upiPayeeName);
    int chairs = branch.chairs;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF101311),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF22C55E), width: 1),
          ),
          title: Text(
            "Edit ${branch.name}",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Branch Name",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "City / Region",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Street Address",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Phone",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: upiIdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Branch UPI ID (Optional)",
                    hintText: "Leave blank to use salon default UPI",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: upiPayeeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Branch UPI Payee Name (Optional)",
                    labelStyle: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Chairs:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text("$chairs Stations", style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: chairs.toDouble(),
                  min: 1,
                  max: 24,
                  divisions: 23,
                  activeColor: const Color(0xFF22C55E),
                  onChanged: (val) => setDlgState(() => chairs = val.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.black),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDlgState(() => isSubmitting = true);
                      try {
                        await widget.appState.updateBranch(branch.id, {
                          'name': nameCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'chairs': chairs,
                          'upiId': upiIdCtrl.text.trim(),
                          'upiPayeeName': upiPayeeCtrl.text.trim(),
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Branch updated successfully!")),
                        );
                        setState(() {});
                      } catch (e) {
                        setDlgState(() => isSubmitting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBranch(SalonBranch branch) {
    if (widget.appState.branches.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot delete your only salon branch outlet.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101311),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        title: Text("Delete ${branch.name}?", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          "Are you sure you want to remove this branch? All associated chair rosters and history will be detached.",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.appState.deleteBranch(branch.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${branch.name} deleted successfully")),
                );
                setState(() {});
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to delete branch: $e"), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.appState.canSwitchBranch) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0F0E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101311),
          elevation: 0,
          title: const Text(
            "Branches & Outlets",
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.lock_person_outlined, color: Colors.amber, size: 30),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Branch Management Restricted",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Front desk receptionists are strictly locked to their single assigned branch (${widget.appState.activeBranch?.name ?? 'Assigned Branch'}). Outlet switching and branch network creation require Salon Owner privileges.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final branches = widget.appState.branches;
    final activeId = widget.appState.activeBranch?.id ?? (branches.isNotEmpty ? branches.first.id : "");

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101311),
        elevation: 0,
        title: const Text(
          "Branches & Outlets",
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadBranches,
            tooltip: "Refresh Branches",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : RefreshIndicator(
              color: const Color(0xFF22C55E),
              backgroundColor: const Color(0xFF101311),
              onRefresh: _loadBranches,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Top Overview Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF142418), Color(0xFF101612)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: Color(0xFF22C55E), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.appState.salonName,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${branches.length} ${branches.length == 1 ? 'Registered Outlet' : 'Registered Outlets'} • Multi-Branch Ready",
                                    style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Manage your multi-location salon network. Staff schedules, styling stations, and intake tickets can be filtered by individual branch location.",
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _showAddBranchDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("+ Add New Branch Outlet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "YOUR OUTLETS",
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),

                  if (branches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141815),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.location_city_outlined, color: Colors.white30, size: 40),
                          const SizedBox(height: 10),
                          const Text("No Outlets Found", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("Add your flagship studio to start multi-branch management.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF22C55E), side: const BorderSide(color: Color(0xFF22C55E))),
                            onPressed: _showAddBranchDialog,
                            child: const Text("+ Create Flagship Branch"),
                          ),
                        ],
                      ),
                    )
                  else
                    ...branches.map((b) {
                      final isCurrent = b.id == activeId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141815),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF22C55E) : Colors.white.withOpacity(0.08),
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          b.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (b.code.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.white24),
                                          ),
                                          child: Text(
                                            b.code,
                                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B3822),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF22C55E)),
                                    ),
                                    child: const Text(
                                      "ACTIVE OUTLET",
                                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (b.address.isNotEmpty || b.city.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined, color: Colors.white38, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      [b.address, b.city].where((s) => s.isNotEmpty).join(", "),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            if (b.phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, color: Colors.white38, size: 14),
                                  const SizedBox(width: 4),
                                  Text(b.phone, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${b.chairs} Styling Stations",
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                  onPressed: () => _showEditBranchDialog(b),
                                  tooltip: "Edit Branch",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => _confirmDeleteBranch(b),
                                  tooltip: "Delete Branch",
                                ),
                              ],
                            ),
                            if (!isCurrent) ...[
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF22C55E)),
                                    foregroundColor: const Color(0xFF22C55E),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    widget.appState.setActiveBranch(b);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Switched active outlet to ${b.name}")),
                                    );
                                    setState(() {});
                                  },
                                  child: const Text("Switch To This Outlet", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
