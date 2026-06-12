import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/purchase.dart';
import '../notifier/purchase_notifier.dart';

class EditSupplierDialog extends ConsumerStatefulWidget {
  final Supplier supplier;
  const EditSupplierDialog({super.key, required this.supplier});

  @override
  ConsumerState<EditSupplierDialog> createState() => _EditSupplierDialogState();
}

class _EditSupplierDialogState extends ConsumerState<EditSupplierDialog>
    with SingleTickerProviderStateMixin {
  static const _primaryTeal = Color(0xFF0D9488);
  static const _primaryLight = Color(0xFF14B8A6);
  static const _surface = Color(0xFFF8FAFC);
  static const _textDark = Color(0xFF0F172A);
  static const _textSub = Color(0xFF475569);
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _cardBg = Colors.white;
  static const _danger = Color(0xFFEF4444);

  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  int _activeTab = 0;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;
  late String _supplierType;
  late String _status;

  late TextEditingController _drugLicenseController;
  DateTime? _expiryDate;
  late bool _isPreferred;
  late TextEditingController _leadTimeController;
  late TextEditingController _paymentTermsController;
  late TextEditingController _creditLimitController;

  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;

  bool _submitting = false;

  static const _stepLabels = ['General Info', 'Compliance', 'Bank Details'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });

    _nameController = TextEditingController(text: widget.supplier.name);
    _phoneController = TextEditingController(text: widget.supplier.phone);
    _emailController = TextEditingController(text: widget.supplier.email);
    _gstController = TextEditingController(text: widget.supplier.gstNumber);
    _addressController = TextEditingController(text: widget.supplier.address);
    _contactPersonController = TextEditingController(text: widget.supplier.contactPerson ?? '');
    _supplierType = widget.supplier.supplierType ?? 'DISTRIBUTOR';
    _status = widget.supplier.status.toUpperCase();
    if (_status != 'ACTIVE' && _status != 'INACTIVE' && _status != 'BLACKLISTED') {
      _status = 'ACTIVE';
    }

    _drugLicenseController = TextEditingController(text: widget.supplier.drugLicenseNumber ?? '');
    _expiryDate = widget.supplier.licenseExpiry != null && widget.supplier.licenseExpiry!.isNotEmpty
        ? DateTime.tryParse(widget.supplier.licenseExpiry!)
        : null;
    _isPreferred = widget.supplier.isPreferred;
    _leadTimeController = TextEditingController(text: widget.supplier.leadTimeDays.toString());
    _paymentTermsController = TextEditingController(text: widget.supplier.paymentTermsDays.toString());
    _creditLimitController = TextEditingController(text: widget.supplier.creditLimit?.toString() ?? '');

    _bankNameController = TextEditingController(text: widget.supplier.bankName ?? '');
    _accountNumberController = TextEditingController(text: widget.supplier.accountNumber ?? '');
    _ifscController = TextEditingController(text: widget.supplier.ifscCode ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _drugLicenseController.dispose();
    _leadTimeController.dispose();
    _paymentTermsController.dispose();
    _creditLimitController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryTeal,
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      setState(() => _submitting = true);

      final updated = widget.supplier.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gstNumber: _gstController.text.trim().toUpperCase(),
        address: _addressController.text.trim(),
        supplierType: _supplierType,
        contactPerson: _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
        status: _status,
        drugLicenseNumber: _drugLicenseController.text.trim().isEmpty
            ? null
            : _drugLicenseController.text.trim(),
        licenseExpiry: _expiryDate?.toIso8601String(),
        isPreferred: _isPreferred,
        leadTimeDays: int.tryParse(_leadTimeController.text) ?? 7,
        paymentTermsDays: int.tryParse(_paymentTermsController.text) ?? 30,
        creditLimit: double.tryParse(_creditLimitController.text),
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim().isEmpty
            ? null
            : _ifscController.text.trim().toUpperCase(),
      );

      ref.read(purchaseNotifierProvider.notifier).editSupplierLocal(updated);
      setState(() => _submitting = false);
      Navigator.of(context).pop(true);
      _showSnack('Supplier updated successfully!', _primaryTeal);
    } else {
      _showSnack('Please correct the validation errors in the form.', _danger);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 780,
        height: 680,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _surface,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              _buildStepper(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildGeneralTab(),
                      _buildComplianceTab(),
                      _buildBankTab(),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 16, 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryTeal, _primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Supplier Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.supplier.name,
                    style: TextStyle(fontSize: 13, color: _textMuted),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: _cardBg,
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _activeTab;
          final isDone = i < _activeTab;
          final isLast = i == 2;
          return Expanded(
            child: Row(
              children: [
                _buildStepDot(i, isActive, isDone),
                const SizedBox(width: 10),
                Text(
                  _stepLabels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _primaryTeal : _textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: isDone ? _primaryTeal : _border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepDot(int i, bool isActive, bool isDone) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? _primaryTeal
            : isActive
                ? Colors.white
                : _border,
        border: Border.all(
          color: isActive ? _primaryTeal : _border,
          width: 2,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? _primaryTeal : _textMuted,
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _primaryTeal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: _primaryTeal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionCard(
            'Basic Information',
            Icons.info_outline_rounded,
            [
              _buildRow([
                _buildField(
                  label: 'Supplier Name',
                  hint: 'e.g. Acme Pharmaceuticals Ltd',
                  controller: _nameController,
                  icon: Icons.store_rounded,
                  required: true,
                ),
                const SizedBox(width: 16),
                _buildDropdown(
                  label: 'Supplier Type',
                  value: _supplierType,
                  icon: Icons.category_rounded,
                  items: const ['WHOLESALER', 'DISTRIBUTOR', 'MANUFACTURER'],
                  onChanged: (v) => setState(() => _supplierType = v),
                ),
              ]),
              const SizedBox(height: 16),
              _buildRow([
                _buildField(
                  label: 'Contact Person',
                  hint: 'e.g. John Doe',
                  controller: _contactPersonController,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(width: 16),
                _buildDropdownStatus(),
              ]),
              const SizedBox(height: 16),
              _buildRow([
                _buildField(
                  label: 'Phone Number',
                  hint: 'e.g. +91 9876543210',
                  controller: _phoneController,
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  required: true,
                ),
                const SizedBox(width: 16),
                _buildField(
                  label: 'Email Address',
                  hint: 'e.g. orders@acme.com',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),
              ]),
              const SizedBox(height: 16),
              _buildRow([
                _buildField(
                  label: 'GST Number',
                  hint: 'e.g. 22AAAAA1111A1Z1',
                  controller: _gstController,
                  icon: Icons.receipt_long_outlined,
                  required: true,
                ),
              ]),
              const SizedBox(height: 16),
              _buildRow([
                _buildField(
                  label: 'Business Address',
                  hint: 'Enter full business address details...',
                  controller: _addressController,
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  required: true,
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceTab() {
    final expiryText = _expiryDate == null
        ? 'Select Expiry Date'
        : DateFormat('dd MMM yyyy').format(_expiryDate!);
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionCard(
            'License & Regulatory',
            Icons.verified_outlined,
            [
              _buildRow([
                _buildField(
                  label: 'Drug License Number',
                  hint: 'e.g. DL-123456',
                  controller: _drugLicenseController,
                  icon: Icons.assignment_outlined,
                ),
                const SizedBox(width: 16),
                _buildDateField(
                  label: 'License Expiry Date',
                  value: expiryText,
                  icon: Icons.calendar_month_outlined,
                  onTap: () => _selectExpiryDate(context),
                  hasValue: _expiryDate != null,
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Supplier Preferences',
            Icons.tune_outlined,
            [
              _buildPreferredToggle(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Terms & Credit',
            Icons.description_outlined,
            [
              _buildRow([
                _buildField(
                  label: 'Lead Time (Days)',
                  hint: 'e.g. 7',
                  controller: _leadTimeController,
                  icon: Icons.schedule_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(width: 16),
                _buildField(
                  label: 'Payment Terms (Days)',
                  hint: 'e.g. 30',
                  controller: _paymentTermsController,
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(width: 16),
                _buildField(
                  label: 'Credit Limit (₹)',
                  hint: 'e.g. 500000',
                  controller: _creditLimitController,
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionCard(
            'Bank Account Details',
            Icons.account_balance_outlined,
            [
              _buildRow([
                _buildField(
                  label: 'Bank Name',
                  hint: 'e.g. State Bank of India',
                  controller: _bankNameController,
                  icon: Icons.business_outlined,
                ),
                const SizedBox(width: 16),
                _buildField(
                  label: 'Account Number',
                  hint: 'e.g. 1092837465',
                  controller: _accountNumberController,
                  icon: Icons.numbers_outlined,
                ),
              ]),
              const SizedBox(height: 16),
              _buildRow([
                _buildField(
                  label: 'IFSC Code',
                  hint: 'e.g. SBIN0001234',
                  controller: _ifscController,
                  icon: Icons.qr_code_rounded,
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryTeal.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryTeal.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: _primaryTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bank details are optional but recommended for automated payment processing.',
                    style: TextStyle(fontSize: 12, color: _textSub, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferredToggle() {
    return InkWell(
      onTap: () => setState(() => _isPreferred = !_isPreferred),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isPreferred ? _primaryTeal.withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isPreferred ? _primaryTeal.withValues(alpha: 0.25) : _border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isPreferred ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isPreferred ? _primaryTeal : _textMuted,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Supplier',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _isPreferred ? _primaryTeal : _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Preferred suppliers are prioritized in automated purchase workflows.',
                    style: TextStyle(fontSize: 12, color: _textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isPreferred ? _primaryTeal : _border,
              ),
              padding: const EdgeInsets.all(2),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isPreferred ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_activeTab > 0)
            TextButton.icon(
              onPressed: () => _tabController.animateTo(_activeTab - 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: _textSub,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  side: BorderSide(color: _border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  foregroundColor: _textSub,
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              if (_activeTab < 2)
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(_activeTab + 1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    backgroundColor: _primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              if (_activeTab == 2)
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_submitting ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    backgroundColor: _primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(children: children);
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _textMuted),
              const SizedBox(width: 6),
              Text(
                required ? '$label *' : label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textSub,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.normal),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primaryTeal, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _danger, width: 1.2),
              ),
            ),
            validator: required
                ? (val) => (val == null || val.trim().isEmpty) ? '$label is required' : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textSub,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w500),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted),
                items: items.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e[0] + e.substring(1).toLowerCase()),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownStatus() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle_outlined, size: 14, color: _textMuted),
              const SizedBox(width: 6),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textSub,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _status,
                isExpanded: true,
                style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w500),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  DropdownMenuItem(value: 'BLACKLISTED', child: Text('Blacklisted')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textSub,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: hasValue ? _textDark : _textMuted,
                        fontSize: 14,
                        fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 16, color: _textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
