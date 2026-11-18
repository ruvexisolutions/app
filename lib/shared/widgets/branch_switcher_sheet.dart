import 'package:flutter/material.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/features/business/screens/branches_management_screen.dart';

void showBranchSwitcherSheet(BuildContext context, RuvexiAppState appState) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BranchSwitcherSheet(appState: appState),
  );
}

class BranchSwitcherSheet extends StatelessWidget {
  final RuvexiAppState appState;

  const BranchSwitcherSheet({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101311),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.35)),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF22C55E), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Switch Branch Studio",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appState.branches.isNotEmpty
                          ? "${appState.branches.length} ${appState.branches.length == 1 ? 'outlet registered' : 'outlets registered'}"
                          : "Single primary atelier",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF71717A), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // List of Branches
          if (appState.branches.isNotEmpty) ...[
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: appState.branches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final b = appState.branches[index];
                  final isSelected = appState.activeBranch?.id == b.id;
                  return InkWell(
                    onTap: () {
                      appState.setActiveBranch(b);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Switched active branch to ${b.name}"),
                          backgroundColor: const Color(0xFF22C55E),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF22C55E).withOpacity(0.08)
                            : const Color(0xFF141815),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF27272A),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF22C55E).withOpacity(0.18)
                                  : const Color(0xFF101311),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.store_mall_directory_outlined,
                              color: isSelected ? const Color(0xFF22C55E) : Colors.white70,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    if (b.city.isNotEmpty) b.city,
                                    "${b.chairs} Chairs",
                                    if (b.phone.isNotEmpty) b.phone,
                                  ].join(" • "),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: Color(0xFF22C55E), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    "ACTIVE",
                                    style: TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF141815),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Color(0xFF22C55E), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.salonName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.salonLocation.isNotEmpty
                              ? appState.salonLocation
                              : "Main Flagship Studio",
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "PRIMARY",
                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Action Button: Add/Manage Outlets
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BranchesManagementScreen(appState: appState)),
                );
              },
              icon: const Icon(Icons.add_business_outlined, color: Color(0xFFFACC15), size: 16),
              label: const Text(
                "Manage & Add Outlets",
                style: TextStyle(color: Color(0xFFFACC15), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: const Color(0xFFFACC15).withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BranchTopDropdownPill extends StatelessWidget {
  final RuvexiAppState appState;

  const BranchTopDropdownPill({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final activeBranch = appState.activeBranch;
    final currentBranchLabel = activeBranch != null ? activeBranch.name : appState.salonName;
    final hasMultipleBranches = appState.branches.length > 1;

    return GestureDetector(
      onTap: () => showBranchSwitcherSheet(context, appState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: const Color(0xFF101311),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasMultipleBranches
                ? const Color(0xFF22C55E).withOpacity(0.35)
                : Colors.white.withOpacity(0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 14,
              color: hasMultipleBranches ? const Color(0xFF22C55E) : Colors.white70,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                currentBranchLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: hasMultipleBranches ? const Color(0xFF22C55E) : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
