import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfService {
  // Colors
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _red = PdfColor.fromInt(0xFFD32F2F);
  static const _black = PdfColor.fromInt(0xFF212121);
  static const _gray = PdfColor.fromInt(0xFF757575);
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const _borderGray = PdfColor.fromInt(0xFFBDBDBD);
  static const _white = PdfColors.white;

  static Future<Uint8List> generateCustomerStatement({
    required String shopName,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> debts,
  }) async {
    final pdf = pw.Document();

    final customerName = customer['name'] as String? ?? '';
    final customerPhone = customer['phone'] as String? ?? '';

    // Split debts
    final unpaid = debts.where((d) => d['isPaid'] == false).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });

    final paid = debts.where((d) => d['isPaid'] == true).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });

    // Totals
    final totalDebt =
        unpaid.fold(0.0, (s, d) => s + (d['amount'] as num).toDouble());
    final generatedOn =
        DateFormat('dd MMM yyyy  hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        build: (ctx) => [
          // ── HEADER ──────────────────────────────────────
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  shopName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _green,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Customer Debt Statement',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11, color: _gray),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: _green, thickness: 1.5),
          pw.SizedBox(height: 14),

          // ── CUSTOMER INFO ────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _borderGray, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer Name',
                        style: pw.TextStyle(fontSize: 8, color: _gray)),
                    pw.SizedBox(height: 3),
                    pw.Text(customerName,
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: _black)),
                    pw.SizedBox(height: 2),
                    pw.Text(customerPhone,
                        style: pw.TextStyle(fontSize: 9, color: _gray)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated on',
                        style: pw.TextStyle(fontSize: 8, color: _gray)),
                    pw.SizedBox(height: 3),
                    pw.Text(generatedOn,
                        style: pw.TextStyle(fontSize: 9, color: _black)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ── OUTSTANDING BALANCE BOX ──────────────────────
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: pw.BoxDecoration(
              color: totalDebt > 0
                  ? const PdfColor.fromInt(0xFFFFEBEE)
                  : const PdfColor.fromInt(0xFFE8F5E9),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                  color: totalDebt > 0 ? _red : _green, width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Outstanding Balance',
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: totalDebt > 0 ? _red : _green),
                ),
                pw.Text(
                  ' ${totalDebt.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: totalDebt > 0 ? _red : _green),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── PENDING DEBTS TABLE ──────────────────────────
          if (unpaid.isNotEmpty) ...[
            pw.Text(
              'Pending Debts  (${unpaid.length})',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold, color: _red),
            ),
            pw.SizedBox(height: 8),
            _buildTable(unpaid, isPaid: false),
            pw.SizedBox(height: 20),
          ],

          // ── CLEARED DEBTS TABLE ──────────────────────────
          if (paid.isNotEmpty) ...[
            pw.Text(
              'Cleared Debts  (${paid.length})',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold, color: _green),
            ),
            pw.SizedBox(height: 8),
            _buildTable(paid, isPaid: true),
            pw.SizedBox(height: 20),
          ],

          // Empty state
          if (debts.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Text(
                  'No debt records found for this customer.',
                  style: pw.TextStyle(fontSize: 10, color: _gray),
                ),
              ),
            ),

          // ── FOOTER ──────────────────────────────────────
        ],
      ),
    );

    return pdf.save();
  }

  // ── Table builder ────────────────────────────────────────
  static pw.Widget _buildTable(
    List<Map<String, dynamic>> rows, {
    required bool isPaid,
  }) {
    const headerColor = PdfColor.fromInt(0xFFEEEEEE);

    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      // Fixed column widths for consistent alignment
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // #
        1: const pw.FixedColumnWidth(90), // Date
        2: const pw.FlexColumnWidth(), // Description (flexible)
        3: const pw.FixedColumnWidth(80), // Amount
        4: const pw.FixedColumnWidth(48), // Status
      },
      children: [
        // ── Header row ───────────────────────────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _cell('#', bold: true, center: true),
            _cell('Date', bold: true),
            _cell('Description', bold: true),
            _cell('Amount', bold: true, right: true),
            _cell('Status', bold: true, center: true),
          ],
        ),

        // ── Data rows ────────────────────────────────────
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;

          final date = DateTime.tryParse(row['date'] as String? ?? '');
          final dateStr =
              date != null ? DateFormat('dd MMM yyyy').format(date) : '-';
          final amount = (row['amount'] as num).toDouble();
          final desc = row['description'] as String? ?? '-';
          final bg = i.isEven ? _white : _lightGray;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _cell('${i + 1}', center: true, color: _gray, small: true),
              _cell(dateStr, color: _gray, small: true),
              _cell(desc, color: _black),
              _cell(
                ' ${amount.toStringAsFixed(2)}',
                right: true,
                bold: true,
                color: isPaid ? _green : _red,
              ),
              _statusCell(isPaid),
            ],
          );
        }),

        // ── Total row ────────────────────────────────────
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
          children: [
            _cell('', center: true),
            _cell(''),
            _cell('Total', bold: true, color: _black),
            _cell(
              ' ${rows.fold(0.0, (s, r) => s + (r['amount'] as num).toDouble()).toStringAsFixed(2)}',
              right: true,
              bold: true,
              color: isPaid ? _green : _red,
            ),
            _cell(''),
          ],
        ),
      ],
    );
  }

  // ── Cell helpers ─────────────────────────────────────────
  static pw.Widget _cell(
    String text, {
    bool bold = false,
    bool center = false,
    bool right = false,
    bool small = false,
    PdfColor color = _black,
  }) {
    pw.TextAlign align = pw.TextAlign.left;
    if (center) align = pw.TextAlign.center;
    if (right) align = pw.TextAlign.right;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: small ? 8 : 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _statusCell(bool isPaid) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: pw.BoxDecoration(
              color: isPaid
                  ? const PdfColor.fromInt(0xFFE8F5E9)
                  : const PdfColor.fromInt(0xFFFFEBEE),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              isPaid ? 'Paid' : 'Due',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: isPaid ? _green : _red,
              ),
            ),
          ),
        ),
      );
}
