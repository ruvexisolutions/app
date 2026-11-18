import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';
import 'package:ruvexi_mobile/shared/widgets/salon_notification_dialog.dart';

class ServicesPricingScreen extends StatefulWidget {
  final RuvexiAppState appState;

  const ServicesPricingScreen({super.key, required this.appState});

  @override
  State<ServicesPricingScreen> createState() => _ServicesPricingScreenState();
}

class _ServicesPricingScreenState extends State<ServicesPricingScreen> {
  int _selectedTab = 0; // 0: Services, 1: Packages
  int _selectedCategoryIndex = 0;

  List<String> get _categories {
    final set = <String>{};
    for (final s in widget.appState.catalog) {
      final c = s.category.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final sorted = set.toList()..sort();
    return ["All", ...sorted];
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: "10");
    final brandCtrl = TextEditingController(text: "Salon Professional");
    String category = "Hair Care";
    final categoriesList = ["Hair Care", "Skin Care", "Styling & Beard", "Hair Color", "Tools & Essentials"];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF101311),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF22C55E), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Color(0xFF22C55E), size: 20),
              SizedBox(width: 8),
              Text("Add Salon Retail Product", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Product Name *",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    hintText: "e.g. Moroccanoil Treatment Serum",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Retail Price (₹) *",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    hintText: "e.g. 650",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Current Stock Quantity *",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    hintText: "e.g. 15",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: brandCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Brand / Size",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    hintText: "e.g. L'Oreal / 100ml",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141815),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text("Category", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categoriesList.map((cat) {
                    final isSel = category == cat;
                    return GestureDetector(
                      onTap: () => setModalState(() => category = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF1B3822) : const Color(0xFF141815),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? const Color(0xFF22C55E) : Colors.transparent),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSel ? const Color(0xFF22C55E) : Colors.white60,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 10;
                if (name.isNotEmpty && price > 0) {
                  final newItem = InventoryItem(
                    id: "prod_${DateTime.now().millisecondsSinceEpoch}",
                    name: name,
                    category: category,
                    price: price,
                    stock: stock,
                    minAlert: 3,
                    sizeVolume: brandCtrl.text.trim(),
                    unit: "pcs",
                  );
                  widget.appState.addProduct(newItem);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$name added to salon retail products")),
                  );
                }
              },
              child: const Text("Save Product", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: "30");
    String category = "Hair";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF101311),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF22C55E), width: 1),
          ),
          title: const Text("Add New Service", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Service Name",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF141815),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Price (₹)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF141815),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Duration (minutes)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF141815),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                  final newSvc = ServiceItem(
                    id: "s_${DateTime.now().millisecondsSinceEpoch}",
                    name: nameCtrl.text.trim(),
                    category: category,
                    price: double.tryParse(priceCtrl.text) ?? 499.0,
                    durationMinutes: int.tryParse(durationCtrl.text) ?? 30,
                  );
                  widget.appState.addService(newSvc);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${newSvc.name} added to catalog")),
                  );
                }
              },
              child: const Text("Save Service", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          "Services",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF22C55E), size: 20),
            tooltip: "Sync Services",
            onPressed: () => widget.appState.syncWorkspace(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
            tooltip: "Salon Alerts",
            onPressed: () => showSalonNotificationModal(context, widget.appState),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.appState,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs: Services, Products, Packages
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _buildTab(0, "Services"),
                    const SizedBox(width: 8),
                    _buildTab(1, "Products"),
                    const SizedBox(width: 8),
                    _buildTab(2, "Packages"),
                  ],
                ),
              ),

              // Category chips
              if (_selectedTab == 0) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cats = _categories;
                      final cat = cats[index];
                      final isSelected = _selectedCategoryIndex == index;
                      final count = cat == "All"
                          ? widget.appState.catalog.length
                          : widget.appState.catalog.where((s) => s.category.toLowerCase() == cat.toLowerCase()).length;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF101311),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Text(
                            cat == "All" ? "All ($count)" : "$cat ($count)",
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Service items, Product items, or Package items
              Expanded(
                child: _selectedTab == 0
                    ? _buildServicesList()
                    : (_selectedTab == 1 ? _buildProductsList() : _buildPackagesList()),
              ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        color: const Color(0xFF060706),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_selectedTab == 0) {
                _showAddServiceDialog();
              } else if (_selectedTab == 1) {
                _showAddProductDialog();
              } else {
                _showAddServiceDialog();
              }
            },
            icon: const Icon(Icons.add, color: Colors.black, size: 20),
            label: Text(
              _selectedTab == 0
                  ? "Add Service"
                  : (_selectedTab == 1 ? "Add Product" : "Create Package"),
              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF101311),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    final cats = _categories;
    final catIndex = _selectedCategoryIndex >= cats.length ? 0 : _selectedCategoryIndex;
    final selectedCat = cats[catIndex];
    final list = widget.appState.catalog.where((s) {
      if (selectedCat == "All") return true;
      return s.category.toLowerCase() == selectedCat.toLowerCase();
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF101311),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF181D1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.content_cut, color: Color(0xFF22C55E), size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹${item.price.toInt()}",
                      style: const TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                "${item.durationMinutes} min",
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsList() {
    final products = widget.appState.inventory;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.white.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            const Text(
              "No Retail Products Yet",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Add shampoos, serums, waxes, and treatments to sell at POS.",
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        final isLow = item.isLowStock;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF101311),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF181D1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF22C55E), size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "₹${item.price.toInt()}",
                          style: const TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "• ${item.category}",
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLow ? const Color(0xFF2B1D11) : const Color(0xFF142419),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${item.stock} in stock",
                  style: TextStyle(
                    color: isLow ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackagesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      itemCount: widget.appState.packages.length,
      itemBuilder: (context, index) {
        final pkg = widget.appState.packages[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF101311),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pkg.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text("₹${pkg.price.toInt()}", style: const TextStyle(color: Color(0xFF22C55E), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Text(pkg.description, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: pkg.servicesIncluded.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141815),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

