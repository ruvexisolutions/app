import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ruvexi_mobile/core/network/api_config.dart';
import 'package:ruvexi_mobile/core/state/ruvexi_state.dart';
import 'package:ruvexi_mobile/core/theme/ruvexi_theme.dart';

Future<void> showInviteReceptionistSheet(BuildContext context, RuvexiAppState appState) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => InviteReceptionistSheet(appState: appState),
  );
}

class InviteReceptionistSheet extends StatefulWidget {
  final RuvexiAppState appState;

  const InviteReceptionistSheet({super.key, required this.appState});

  @override
  State<InviteReceptionistSheet> createState() => _InviteReceptionistSheetState();
}

class _InviteReceptionistSheetState extends State<InviteReceptionistSheet> {
  final _emailController = TextEditingController();
  String? _selectedBranchId;
  bool _isLoading = false;
  String? _errorMessage;
  String? _generatedLink;
  String? _invitedEmail;
  bool _hasCopied = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.appState.activeBranch != null) {
      _selectedBranchId = widget.appState.activeBranch!.id;
    } else if (widget.appState.branches.isNotEmpty) {
      _selectedBranchId = widget.appState.branches.first.id;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid work email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.appState.inviteReceptionist(
        email: email,
        branchId: _selectedBranchId,
      );

      final rawInviteUrl = res['inviteUrl'] as String?;
      if (rawInviteUrl == null || rawInviteUrl.isEmpty) {
        throw Exception(res['message'] ?? 'Could not generate invitation link');
      }

      final fullUrl = rawInviteUrl.startsWith('http')
          ? rawInviteUrl
          : '${RuvexiApiConfig.webAppUrl}$rawInviteUrl';

      setState(() {
        _generatedLink = fullUrl;
        _invitedEmail = email;
        _emailSent = res['emailSent'] == true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedLink == null) return;
    await Clipboard.setData(ClipboardData(text: _generatedLink!));
    setState(() => _hasCopied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite link copied to clipboard!'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 2),
        ),
      );
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hasCopied = false);
    });
  }

  Future<void> _shareOnWhatsApp() async {
    if (_generatedLink == null) return;

    String branchLabel = widget.appState.salonName;
    if (_selectedBranchId != null) {
      final match = widget.appState.branches.where((b) => b.id == _selectedBranchId);
      if (match.isNotEmpty) {
        branchLabel = match.first.name;
      }
    }

    final message =
        'Hi! You have been invited to join ${widget.appState.salonName} ($branchLabel) as Front Desk Receptionist on Ruvexi.\n\nPlease tap this link to set your password and access your front desk terminal:\n$_generatedLink';

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Link copied to clipboard instead.')),
        );
        _copyToClipboard();
      }
    }
  }

  void _resetForm() {
    setState(() {
      _generatedLink = null;
      _invitedEmail = null;
      _emailController.clear();
      _errorMessage = null;
      _hasCopied = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
        top: 20,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Sheet Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFFFACC15), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Invite Front Desk Receptionist",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Binds staff strictly to ${widget.appState.salonName}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Content: Form vs Success State
            if (_generatedLink == null) _buildInviteForm() else _buildSuccessState(),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informational Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141815),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Text(
            "Generate a single-use registration link. Upon opening, the receptionist sets their password and immediately gains front desk POS access locked exclusively to ${widget.appState.salonName}.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Email Field
        Text(
          "RECEPTIONIST WORK EMAIL",
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF71717A), size: 18),
            hintText: "receptionist@your-salon.com",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF141815),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF27272A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF27272A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFACC15), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Branch Selection (if branches exist)
        if (widget.appState.branches.isNotEmpty) ...[
          Text(
            "ALLOT TO BRANCH STUDIO",
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141815),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBranchId,
                isExpanded: true,
                dropdownColor: const Color(0xFF141815),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFACC15)),
                items: widget.appState.branches.map((b) {
                  return DropdownMenuItem<String>(
                    value: b.id,
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, color: Color(0xFF22C55E), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${b.name} (${b.city.isNotEmpty ? b.city : 'Studio'})",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (b.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "PRIMARY",
                              style: TextStyle(color: Color(0xFF22C55E), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBranchId = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "The receptionist will be restricted strictly to this location's appointments, POS cash drawer, and staff.",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
          ),
          const SizedBox(height: 16),
        ],

        // Single-Salon Security Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF181D1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF22C55E), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4),
                    children: const [
                      TextSpan(
                        text: "Strict Single-Salon Security: ",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "A receptionist can strictly belong to only one salon. Their credentials and access are permanently isolated to your salon.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF27272A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGenerateInvite,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.link_rounded, color: Colors.black, size: 18),
                label: Text(
                  _isLoading ? "Generating Link..." : "Create 1-Click Invite",
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Color(0xFF22C55E)),
                    children: [
                      const TextSpan(text: "Invitation generated for "),
                      TextSpan(
                        text: _invitedEmail ?? "",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_emailSent) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              "✓ Direct invitation email also sent via Resend",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Single-Use URL Box
        Text(
          "SINGLE-USE ENROLLMENT URL (VALID 48 HOURS)",
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141815),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  _generatedLink ?? "",
                  style: const TextStyle(
                    color: Color(0xFFFACC15),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _copyToClipboard,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hasCopied ? const Color(0xFF22C55E) : const Color(0xFFFACC15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasCopied ? Icons.check : Icons.copy_rounded,
                        color: Colors.black,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasCopied ? "Copied" : "Copy",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Share Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareOnWhatsApp,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                label: const Text(
                  "Share on WhatsApp",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.person_add_alt, color: Colors.white70, size: 16),
                label: const Text(
                  "Invite Another",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFF27272A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Close button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Done",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
