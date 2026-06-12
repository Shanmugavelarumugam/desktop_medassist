import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _branchNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _loadShopDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _shopNameController.text =
            prefs.getString('shop_name') ?? 'Viyan Medicare';
        _branchNameController.text =
            prefs.getString('shop_branch') ?? 'Main Branch';
        _phoneController.text =
            prefs.getString('shop_phone') ?? '+91 98765 43210';
        _emailController.text =
            prefs.getString('shop_email') ?? 'contact@viyanmedicare.com';
        _addressController.text =
            prefs.getString('shop_address') ??
            '123 Health Ave, Medical District, Chennai, TN';
        _gstinController.text =
            prefs.getString('shop_gstin') ?? '33AABCV1234F1Z5';
        _licenseController.text =
            prefs.getString('shop_license') ?? 'DL-12345/M/2026';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveShopDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_name', _shopNameController.text.trim());
      await prefs.setString('shop_branch', _branchNameController.text.trim());
      await prefs.setString('shop_phone', _phoneController.text.trim());
      await prefs.setString('shop_email', _emailController.text.trim());
      await prefs.setString('shop_address', _addressController.text.trim());
      await prefs.setString(
        'shop_gstin',
        _gstinController.text.trim().toUpperCase(),
      );
      await prefs.setString('shop_license', _licenseController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Shop Profile updated successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
            width: 320,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to save shop details.'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            width: 320,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    const textDark = Color(0xFF1E293B);
    const borderGrey = Color(0xFFE2E8F0);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryTeal));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderGrey, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: primaryTeal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop Profile',
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your pharmacy/clinic details and regulatory licenses',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(color: borderGrey, height: 1),
                const SizedBox(height: 32),

                // Grid layout for fields
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Store Info
                        _buildSectionHeader('Store Information'),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(
                          isMobile: isMobile,
                          children: [
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                label: 'Shop/Pharmacy Name',
                                controller: _shopNameController,
                                hint: 'e.g. Viyan Medicare',
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter shop name' : null,
                              ),
                            ),
                            if (!isMobile) const SizedBox(width: 24),
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                label: 'Branch Name',
                                controller: _branchNameController,
                                hint: 'e.g. Main Branch',
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter branch name' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Section: Contact Info
                        _buildSectionHeader('Contact Details'),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(
                          isMobile: isMobile,
                          children: [
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                label: 'Phone Number',
                                controller: _phoneController,
                                hint: 'e.g. +91 98765 43210',
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter phone number' : null,
                              ),
                            ),
                            if (!isMobile) const SizedBox(width: 24),
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                label: 'Email Address',
                                controller: _emailController,
                                hint: 'e.g. contact@shop.com',
                                validator: (v) {
                                  if (v!.isEmpty) return 'Enter email';
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Address',
                          controller: _addressController,
                          hint: 'Enter full pharmacy address',
                          maxLines: 2,
                          validator: (v) => v!.isEmpty ? 'Enter address' : null,
                        ),
                        const SizedBox(height: 32),

                        // Section: Legal details
                        _buildSectionHeader('Regulatory & Tax Details'),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(
                          isMobile: isMobile,
                          children: [
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                label: 'GSTIN',
                                controller: _gstinController,
                                hint: 'Enter 15-digit GSTIN',
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter GSTIN' : null,
                              ),
                            ),
                            if (!isMobile) const SizedBox(width: 24),
                            Expanded(
                              flex: isMobile ? 0 : 1,
                              child: _buildTextField(
                                label: 'Drug License Number',
                                controller: _licenseController,
                                hint: 'Enter drug license number',
                                validator: (v) => v!.isEmpty
                                    ? 'Enter Drug License Number'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveShopDetails,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save Shop Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            children
                .map((w) => w is Expanded ? w.child : w)
                .expand((w) => [w, const SizedBox(height: 20)])
                .toList()
              ..removeLast(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
