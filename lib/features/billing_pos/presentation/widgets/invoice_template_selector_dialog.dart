import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifier/billing_notifier.dart';

class InvoiceTemplate {
  final String id;
  final String name;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  const InvoiceTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });
}

const List<InvoiceTemplate> templates = [
  InvoiceTemplate(
    id: 'classic',
    name: 'Premium Corporate',
    subtitle: 'Sleek Navy Enterprise',
    primaryColor: Color(0xFF1E3A8A),
    secondaryColor: Color(0xFFEFF6FF),
    accentColor: Color(0xFF3B82F6),
  ),
  InvoiceTemplate(
    id: 'amethyst',
    name: 'Bold Amethyst',
    subtitle: 'Creative Digital Studio',
    primaryColor: Color(0xFF6D28D9),
    secondaryColor: Color(0xFFF5F3FF),
    accentColor: Color(0xFF8B5CF6),
  ),
  InvoiceTemplate(
    id: 'emerald',
    name: 'Emerald Eco-Mint',
    subtitle: 'Organic Minimal Luxe',
    primaryColor: Color(0xFF047857),
    secondaryColor: Color(0xFFECFDF5),
    accentColor: Color(0xFF10B981),
  ),
  InvoiceTemplate(
    id: 'executive',
    name: 'Executive Standard',
    subtitle: 'Clean Compliance',
    primaryColor: Color(0xFFBE185D),
    secondaryColor: Color(0xFFFDF2F8),
    accentColor: Color(0xFFEC4899),
  ),
  InvoiceTemplate(
    id: 'modern',
    name: 'Modern Pro',
    subtitle: 'Minimalist Sans-Serif',
    primaryColor: Color(0xFF0F172A),
    secondaryColor: Color(0xFFF8FAFC),
    accentColor: Color(0xFF64748B),
  ),
  InvoiceTemplate(
    id: 'thermal',
    name: 'Thermal POS Receipt',
    subtitle: 'Compact 80mm Roll',
    primaryColor: Color(0xFF374151),
    secondaryColor: Color(0xFFF3F4F6),
    accentColor: Color(0xFF4B5563),
  ),
];

class InvoiceTemplateSelectorDialog extends ConsumerStatefulWidget {
  const InvoiceTemplateSelectorDialog({super.key});

  @override
  ConsumerState<InvoiceTemplateSelectorDialog> createState() => _InvoiceTemplateSelectorDialogState();
}

class _InvoiceTemplateSelectorDialogState extends ConsumerState<InvoiceTemplateSelectorDialog> {
  late String _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = ref.read(activeTemplateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final activeTemplate = templates.firstWhere((t) => t.id == _selectedTemplateId, orElse: () => templates.first);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
          maxHeight: 750,
        ),
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dashboard_customize_rounded, color: Color(0xFFBE185D), size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Choose Invoice Template',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select the visual design for generated PDF and physical prints. Select one of 6 unique layouts.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 2. Middle Body
            Expanded(
              child: Row(
                children: [
                  // Left Side: Template Grid List
                  Expanded(
                    flex: 4,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        final isSelected = template.id == _selectedTemplateId;
                        return _buildTemplateCard(template, isSelected);
                      },
                    ),
                  ),

                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                  // Right Side: Live Instant Preview
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.4),
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text(
                                'LIVE INSTANT PREVIEW',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Card(
                                elevation: 4,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                color: Colors.white,
                                child: Container(
                                  width: activeTemplate.id == 'thermal' ? 320 : double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  child: _buildPreviewLayout(activeTemplate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 3. Footer Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(activeTemplateProvider.notifier).setTemplate(_selectedTemplateId);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Set as Active Template', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(InvoiceTemplate template, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTemplateId = template.id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Color(0x0F1E3A8A), blurRadius: 8, offset: Offset(0, 4))]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Miniature layout mockup
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                padding: const EdgeInsets.all(8),
                child: _buildMiniMockup(template),
              ),
            ),
            const SizedBox(height: 8),
            // Title & Description
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        template.subtitle,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMockup(InvoiceTemplate template) {
    if (template.id == 'thermal') {
      return Center(
        child: Container(
          width: 50,
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(height: 3, width: 20, color: template.primaryColor),
              const SizedBox(height: 2),
              Container(height: 2, width: 35, color: Colors.grey[300]),
              const SizedBox(height: 2),
              Container(height: 2, width: 35, color: Colors.grey[300]),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(10, (idx) => Container(width: 2, height: 10, color: Colors.black, margin: const EdgeInsets.symmetric(horizontal: 0.5))),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(height: 4, width: 25, color: template.primaryColor),
            Container(height: 3, width: 15, color: template.accentColor),
          ],
        ),
        const SizedBox(height: 6),
        // Recipient row
        Container(height: 3, width: 40, color: Colors.grey[300]),
        const SizedBox(height: 4),
        // Item rows mock
        Expanded(
          child: Column(
            children: List.generate(3, (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(height: 2, width: 20, color: Colors.grey[200]),
                  const Spacer(),
                  Container(height: 2, width: 6, color: Colors.grey[200]),
                  const SizedBox(width: 4),
                  Container(height: 2, width: 6, color: Colors.grey[200]),
                ],
              ),
            )),
          ),
        ),
        // Bottom total
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(height: 4, width: 18, color: template.accentColor),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewLayout(InvoiceTemplate template) {
    if (template.id == 'thermal') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'VIYAN MEDASSIST',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
          Center(
            child: Text('123, Healthcare Street, Medical Hub', style: TextStyle(fontSize: 8, color: Colors.grey[600])),
          ),
          Center(
            child: Text('Ph: +91 98765 43210 | GSTIN: 29ABCDE1234F1Z1', style: TextStyle(fontSize: 8, color: Colors.grey[600])),
          ),
          const SizedBox(height: 8),
          const Text('--------------------------------------------', style: TextStyle(fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 4),
          const Text(
            'INV: INV-SAMPLE-001\n'
            'DATE: 06-Jun-2026\n'
            'CUST: Johnathan Doe Ltd.',
            style: TextStyle(fontSize: 8, fontFamily: 'monospace', height: 1.3),
          ),
          const SizedBox(height: 4),
          const Text('--------------------------------------------', style: TextStyle(fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 4),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(2),
            },
            children: const [
              TableRow(
                children: [
                  Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
                  Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.center),
                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8), textAlign: TextAlign.right),
                ],
              ),
              TableRow(
                children: [
                  Text('Atorvastatin 10mg', style: TextStyle(fontSize: 7, fontFamily: 'monospace')),
                  Text('2', style: TextStyle(fontSize: 7, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  Text('₹295.72', style: TextStyle(fontSize: 7, fontFamily: 'monospace'), textAlign: TextAlign.right),
                ],
              ),
              TableRow(
                children: [
                  Text('Azee 500 Tablets', style: TextStyle(fontSize: 7, fontFamily: 'monospace')),
                  Text('1', style: TextStyle(fontSize: 7, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  Text('₹584.15', style: TextStyle(fontSize: 7, fontFamily: 'monospace'), textAlign: TextAlign.right),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('--------------------------------------------', style: TextStyle(fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: TextStyle(fontSize: 8, fontFamily: 'monospace')),
              Text('₹785.60', style: TextStyle(fontSize: 8, fontFamily: 'monospace')),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GST (12%):', style: TextStyle(fontSize: 8, fontFamily: 'monospace')),
              Text('₹94.27', style: TextStyle(fontSize: 8, fontFamily: 'monospace')),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL AMOUNT:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              Text('₹879.87', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(24, (index) => Container(
              width: (index % 4 == 0 || index % 5 == 0) ? 3.0 : 1.5,
              height: 26,
              color: Colors.black,
              margin: const EdgeInsets.symmetric(horizontal: 1),
            )),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('*INV-SAMPLE-001*', style: TextStyle(fontSize: 7, fontFamily: 'monospace')),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top style line
        Container(height: 6, color: template.primaryColor),
        const SizedBox(height: 20),

        // Company Details Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: template.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'h',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HARI45',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Global Solutions Enterprise',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'GSTIN: N/A\nEMAIL: hari45@bnxmail.com',
                  style: TextStyle(fontSize: 9, height: 1.4, color: Color(0xFF334155)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: template.secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('INVOICE NO.', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                  const Text('INV-SAMPLE-001', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  const Text('DATE ISSUED', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                  const Text('6/5/2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // recipient, payment mode, currency
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: template.primaryColor, width: 3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BILL RECIPIENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    SizedBox(height: 6),
                    Text('Johnathan Doe Ltd.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('742 Evergreen Terrace,\nSpringfield, US', style: TextStyle(fontSize: 9, color: Color(0xFF475569), height: 1.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYMENT MODE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    SizedBox(height: 6),
                    Text('UPI / Credit Card', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('Terms: Net 30', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENCY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Text('INR (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: template.primaryColor)),
                    const SizedBox(height: 2),
                    const Text('Indian Rupee', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // table
        Table(
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.8),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: template.primaryColor, width: 1.5)),
              ),
              children: const [
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Service / Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF64748B)))),
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF64748B)), textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('Consulting & System Design', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[800]))),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('10', style: TextStyle(fontSize: 8), textAlign: TextAlign.center)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('₹1,500.00', style: TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('₹15,000.00', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('Annual Maintenance Contract (AMC)', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[800]))),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('1', style: TextStyle(fontSize: 8), textAlign: TextAlign.center)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('₹4,500.00', style: TextStyle(fontSize: 8), textAlign: TextAlign.right)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('₹4,500.00', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // summary
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 180,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      const Text('₹19,500.00', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax (GST 18%):', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      const Text('₹3,510.00', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Due:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('₹23,010.00', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: template.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
