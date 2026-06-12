import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/models/invoice.dart';

class InvoicePrinter {
  static Future<void> printInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    // Parse metadata if present in notes
    Map<String, dynamic>? metadata;
    String cleanNotes = invoice.notes ?? '';
    if (invoice.notes != null && invoice.notes!.trim().startsWith('{')) {
      try {
        metadata = jsonDecode(invoice.notes!);
        cleanNotes = metadata?['originalNotes']?.toString() ?? '';
      } catch (_) {
        // Fallback to normal notes
      }
    }

    final templateType = metadata?['templateType'] ?? 'classic';

    if (templateType == 'thermal') {
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            80 * PdfPageFormat.mm,
            200 * PdfPageFormat.mm,
            marginAll: 15,
          ),
          build: (pw.Context context) {
            return _buildThermalLayout(invoice, metadata);
          },
        ),
      );
    } else if (templateType == 'modern') {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildModernLayout(invoice, metadata, cleanNotes);
          },
        ),
      );
    } else {
      // Classic A4
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildClassicLayout(invoice, metadata, cleanNotes);
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.invoiceNumber}',
    );
  }

  static List<InvoiceItem> _consolidateItems(List<InvoiceItem> items) {
    final Map<String, List<InvoiceItem>> groups = {};
    final List<String> order = [];
    for (final item in items) {
      if (!groups.containsKey(item.name)) {
        groups[item.name] = [];
        order.add(item.name);
      }
      groups[item.name]!.add(item);
    }

    return order.map((name) {
      final group = groups[name]!;
      if (group.length == 1) return group.first;

      final totalQty = group.fold<int>(0, (sum, item) => sum + item.qty);
      final totalVal = group.fold<double>(
        0.0,
        (sum, item) => sum + (double.tryParse(item.total.toString()) ?? 0.0),
      );
      final effectiveMrp = totalQty > 0 ? (totalVal / totalQty) : 0.0;
      final totalGstAmount = group.fold<double>(
        0.0,
        (sum, item) =>
            sum + (double.tryParse(item.gstAmount.toString()) ?? 0.0),
      );

      final averagePrice = totalQty > 0
          ? group.fold<double>(
                  0.0,
                  (sum, item) => sum + (item.price * item.qty),
                ) /
                totalQty
          : 0.0;

      final combinedBatch = group.map((e) => e.batchNumber).toSet().join(', ');

      return group.first.copyWith(
        qty: totalQty,
        price: averagePrice,
        mrp: effectiveMrp,
        gstAmount: totalGstAmount,
        total: totalVal,
        batchNumber: combinedBatch,
      );
    }).toList();
  }

  // ==========================================
  // CLASSIC A4 LAYOUT
  // ==========================================
  static pw.Widget _buildClassicLayout(
    Invoice invoice,
    Map<String, dynamic>? metadata,
    String cleanNotes,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildClassicHeader(),
        pw.SizedBox(height: 20),
        _buildClassicInvoiceInfo(invoice, metadata),
        pw.SizedBox(height: 15),
        _buildClassicDivider(PdfColors.grey400),
        pw.SizedBox(height: 10),
        _buildClassicTable(invoice),
        pw.SizedBox(height: 20),
        _buildClassicSummary(invoice),
        if (cleanNotes.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            'Notes: $cleanNotes',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
        ],
        pw.Spacer(),
        _buildClassicDivider(PdfColors.grey400),
        pw.SizedBox(height: 10),
        _buildClassicFooter(),
      ],
    );
  }

  static pw.Widget _buildClassicHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'VIYAN MEDASSIST',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '123, Healthcare Street, Medical Hub, Bangalore',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'GSTIN: 29ABCDE1234F1Z1 | Ph: +91 98765 43210',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: const pw.BoxDecoration(
            color: PdfColors.teal50,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            'TAX INVOICE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal900,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClassicInvoiceInfo(
    Invoice invoice,
    Map<String, dynamic>? metadata,
  ) {
    final docName = metadata?['doctorName'] ?? '';
    final rxNo = metadata?['prescriptionNo'] ?? '';
    final custGst = metadata?['gstNumber'] ?? '';
    final address = metadata?['address'] ?? '';
    final payTerms = metadata?['paymentTerms'] ?? '';
    final dueDate = metadata?['dueDate'] ?? '';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILLED TO:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                invoice.patientName,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (invoice.patientPhone.isNotEmpty)
                pw.Text(
                  'Ph: ${invoice.patientPhone}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (custGst.isNotEmpty)
                pw.Text(
                  'GSTIN: $custGst',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (address.isNotEmpty)
                pw.Text(
                  'Address: $address',
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    'Invoice No: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    invoice.invoiceNumber,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Text(
                    'Invoice Date: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    invoice.date.split('T')[0],
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              if (dueDate.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text(
                      'Due Date: ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      dueDate.split('T')[0],
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
              if (payTerms.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text(
                      'Payment Terms: ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(payTerms, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
              if (docName.isNotEmpty || rxNo.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'PRESCRIPTION DETAILS:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                if (docName.isNotEmpty)
                  pw.Text(
                    'Doctor: $docName',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (rxNo.isNotEmpty)
                  pw.Text(
                    'Rx No: $rxNo',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClassicDivider(PdfColor color) {
    return pw.Container(height: 1, color: color);
  }

  static pw.Widget _buildClassicTable(Invoice invoice) {
    final consolidated = _consolidateItems(invoice.items);
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(0.8),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400),
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 1.5),
            ),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Medicine',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'MRP',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Disc',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'GST',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Amount',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        ...consolidated.map((item) {
          final itemTotalRaw = item.mrp * item.qty;
          final diff = itemTotalRaw - item.total;
          final double discountVal = diff > 0 ? diff.toDouble() : 0.0;

          return pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  item.name,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  item.qty.toString(),
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '₹${item.mrp.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  discountVal > 0
                      ? '₹${discountVal.toStringAsFixed(2)}'
                      : '0.00',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '${item.gst}%',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '₹${item.total.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildClassicSummary(Invoice invoice) {
    final cgst = invoice.gst / 2;
    final sgst = invoice.gst / 2;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    '₹${invoice.subtotal.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              if (invoice.discount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Discount',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.Text(
                      '-₹${invoice.discount.toStringAsFixed(2)}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CGST', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    '₹${cgst.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SGST', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    '₹${sgst.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.Text(
                      '₹${invoice.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        color: PdfColors.teal900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClassicFooter() {
    return pw.Center(
      child: pw.Text(
        'Thank you for visiting! Get well soon.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
  }

  // ==========================================
  // MODERN CORPORATE A4 LAYOUT
  // ==========================================
  static pw.Widget _buildModernLayout(
    Invoice invoice,
    Map<String, dynamic>? metadata,
    String cleanNotes,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Dark premium header block
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0F172A),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VIYAN MEDASSIST',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '123, Healthcare Street, Medical Hub, Bangalore',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey400,
                    ),
                  ),
                  pw.Text(
                    'GSTIN: 29ABCDE1234F1Z1 | Ph: +91 98765 43210',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey400,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0F766E),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Shaded side-by-side info blocks
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILLED TO',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      invoice.patientName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    if (invoice.patientPhone.isNotEmpty)
                      pw.Text(
                        'Ph: ${invoice.patientPhone}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    if (metadata?['gstNumber'] != null &&
                        metadata!['gstNumber'].toString().isNotEmpty)
                      pw.Text(
                        'GSTIN: ${metadata['gstNumber']}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    if (metadata?['address'] != null &&
                        metadata!['address'].toString().isNotEmpty)
                      pw.Text(
                        'Address: ${metadata['address']}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INVOICE INFO',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Inv Number:',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          invoice.invoiceNumber,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Date:',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          invoice.date.split('T')[0],
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (metadata?['dueDate'] != null &&
                        metadata!['dueDate'].toString().isNotEmpty)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Due Date:',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            metadata['dueDate'].split('T')[0],
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Terms:',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          metadata?['paymentTerms'] ?? 'Cash',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (metadata != null &&
                        ((metadata['doctorName'] != null &&
                                metadata['doctorName'].toString().isNotEmpty) ||
                            (metadata['prescriptionNo'] != null &&
                                metadata['prescriptionNo']
                                    .toString()
                                    .isNotEmpty))) ...[
                      pw.Divider(height: 12),
                      if (metadata['doctorName'] != null &&
                          metadata['doctorName'].toString().isNotEmpty)
                        pw.Text(
                          'Dr. ${metadata['doctorName']}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if (metadata['prescriptionNo'] != null &&
                          metadata['prescriptionNo'].toString().isNotEmpty)
                        pw.Text(
                          'Rx: ${metadata['prescriptionNo']}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey800,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Shaded alternate rows table
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(4.5),
            1: pw.FlexColumnWidth(0.8),
            2: pw.FlexColumnWidth(1.2),
            3: pw.FlexColumnWidth(1),
            4: pw.FlexColumnWidth(1),
            5: pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF0F172A),
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: pw.Text(
                    'Medicine',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: pw.Text(
                    'Qty',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: pw.Text(
                    'MRP',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: pw.Text(
                    'Disc',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: pw.Text(
                    'GST',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: pw.Text(
                    'Amount',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            ..._consolidateItems(invoice.items).asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isEven = idx % 2 == 0;
              final itemTotalRaw = item.mrp * item.qty;
              final diff = itemTotalRaw - item.total;
              final double discountVal = diff > 0 ? diff.toDouble() : 0.0;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColors.grey50,
                  border: const pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      item.name,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      item.qty.toString(),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      '₹${item.mrp.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      discountVal > 0
                          ? '₹${discountVal.toStringAsFixed(2)}'
                          : '0.00',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      '${item.gst}%',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      '₹${item.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 20),

        // Shaded totals block
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF0F172A),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Subtotal',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey400,
                        ),
                      ),
                      pw.Text(
                        '₹${invoice.subtotal.toStringAsFixed(2)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  if (invoice.discount > 0) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Discount',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.green300,
                          ),
                        ),
                        pw.Text(
                          '-₹${invoice.discount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.green300,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'GST Taxes',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey400,
                        ),
                      ),
                      pw.Text(
                        '₹${invoice.gst.toStringAsFixed(2)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(height: 12, color: PdfColors.grey800),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL DUE',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '₹${invoice.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (cleanNotes.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Notes: $cleanNotes',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
          ),
        ],
        pw.Spacer(),
        pw.Center(
          child: pw.Text(
            'Thank you for visiting! Get well soon.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // THERMAL POS RECEIPT LAYOUT
  // ==========================================
  static pw.Widget _buildThermalLayout(
    Invoice invoice,
    Map<String, dynamic>? metadata,
  ) {
    final payTerms = metadata?['paymentTerms'] ?? 'Cash';
    final docName = metadata?['doctorName'] ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            'VIYAN MEDASSIST',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(
          child: pw.Text(
            '123, Healthcare Street, Medical Hub',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Ph: +91 98765 43210 | GSTIN: 29ABCDE1234F1Z1',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '---------------------------------------------',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 4),

        pw.Text(
          'INV: ${invoice.invoiceNumber}\n'
          'DATE: ${invoice.date.split('T')[0]}\n'
          'CUST: ${invoice.patientName}\n'
          'TERMS: $payTerms',
          style: const pw.TextStyle(fontSize: 8, height: 1.3),
        ),
        if (docName.toString().isNotEmpty)
          pw.Text('DOC: Dr. $docName', style: const pw.TextStyle(fontSize: 8)),

        pw.SizedBox(height: 4),
        pw.Text(
          '---------------------------------------------',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 4),

        // Compact table
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.8),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400),
                ),
              ),
              children: [
                pw.Text(
                  'Item',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                pw.Text(
                  'Qty',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'MRP',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
                pw.Text(
                  'Total',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ),
            ..._consolidateItems(invoice.items).map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      item.name,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      item.qty.toString(),
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      '₹${item.mrp.toStringAsFixed(1)}',
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      '₹${item.total.toStringAsFixed(1)}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 4),
        pw.Text(
          '---------------------------------------------',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 4),

        // Calculations
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
            pw.Text(
              '₹${invoice.subtotal.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        if (invoice.discount > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Discount:',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.green),
              ),
              pw.Text(
                '-₹${invoice.discount.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.green),
              ),
            ],
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('GST Taxes:', style: const pw.TextStyle(fontSize: 8)),
            pw.Text(
              '₹${invoice.gst.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL AMOUNT:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '₹${invoice.total.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),

        pw.SizedBox(height: 8),
        pw.Text(
          '---------------------------------------------',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 10),

        // NATIVE CODE 128 BARCODE
        pw.Center(
          child: pw.Container(
            height: 25,
            width: 130,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: invoice.invoiceNumber,
              drawText: false,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            '*${invoice.invoiceNumber}*',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),

        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Text(
            'Thank you for shopping!\nVisit again.',
            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }
}
