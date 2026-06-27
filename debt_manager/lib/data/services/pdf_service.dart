import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfService {
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _red = PdfColor.fromInt(0xFFD32F2F);
  static const _black = PdfColor.fromInt(0xFF212121);
  static const _gray = PdfColor.fromInt(0xFF757575);
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const _borderGray = PdfColor.fromInt(0xFFBDBDBD);
  static const _white = PdfColors.white;

  // ────────────────────────────────────────────────────────────
  // CUSTOMER STATEMENT  (debts + credits)
  // ────────────────────────────────────────────────────────────
  static Future<Uint8List> generateCustomerStatement({
    required String shopName,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> debts,
    required List<Map<String, dynamic>> credits, // ← added
  }) async {
    final pdf = pw.Document();

    final customerName = customer['name'] as String? ?? '';
    final customerPhone = customer['phone'] as String? ?? '';
    final customerAddress = customer['address'] as String? ?? '';

    final unpaid = debts.where((d) => d['isPaid'] == false).toList()
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
    final paid = debts.where((d) => d['isPaid'] == true).toList()
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
    final sortedCredits = [...credits]
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

    final totalDebt = unpaid.fold(0.0, (s, d) => s + _amt(d));
    final totalCredit = sortedCredits.fold(0.0, (s, c) => s + _amt(c));
    final netBalance = (totalDebt - totalCredit).clamp(0.0, double.infinity);
    final generatedOn =
        DateFormat('dd MMM yyyy  hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        build: (ctx) => [
          // ── Header ────────────────────────────────────────
          _header(shopName, 'Customer Statement'),
          pw.SizedBox(height: 10),
          pw.Divider(color: _green, thickness: 1.5),
          pw.SizedBox(height: 14),

          // ── Customer info ──────────────────────────────────
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
                    if (customerAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(customerAddress,
                          style: pw.TextStyle(fontSize: 9, color: _gray)),
                    ],
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

          // ── Three summary boxes ────────────────────────────
          pw.Row(children: [
            _summaryBox('Total Debt', ' ${totalDebt.toStringAsFixed(2)}', _red),
            pw.SizedBox(width: 8),
            _summaryBox(
                'Total Credit', ' ${totalCredit.toStringAsFixed(2)}', _green),
            pw.SizedBox(width: 8),
            _summaryBox('Net Outstanding', ' ${netBalance.toStringAsFixed(2)}',
                netBalance > 0 ? _red : _green,
                bold: true),
          ]),
          pw.SizedBox(height: 20),

          // ── Pending debts ──────────────────────────────────
          if (unpaid.isNotEmpty) ...[
            _sectionTitle('Pending Debts  (${unpaid.length})', _red),
            pw.SizedBox(height: 8),
            _debtTable(unpaid, isPaid: false),
            pw.SizedBox(height: 20),
          ],

          // ── Credits received ───────────────────────────────
          if (sortedCredits.isNotEmpty) ...[
            _sectionTitle(
                'Credits Received  (${sortedCredits.length})', _green),
            pw.SizedBox(height: 8),
            _creditTable(sortedCredits),
            pw.SizedBox(height: 20),
          ],

          // ── Cleared debts ──────────────────────────────────
          if (paid.isNotEmpty) ...[
            _sectionTitle('Cleared Debts  (${paid.length})', _gray),
            pw.SizedBox(height: 8),
            _debtTable(paid, isPaid: true),
            pw.SizedBox(height: 20),
          ],

          if (debts.isEmpty && credits.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Text('No records found for this customer.',
                    style: pw.TextStyle(fontSize: 10, color: _gray)),
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  // ────────────────────────────────────────────────────────────
  // DASHBOARD REPORT  (all customers summary)
  // ────────────────────────────────────────────────────────────
  static Future<Uint8List> generateDashboardReport({
    required String shopName,
    required List<Map<String, dynamic>> customers,
  }) async {
    final pdf = pw.Document();

    final generatedOn =
        DateFormat('dd MMM yyyy  hh:mm a').format(DateTime.now());

    final sorted = [...customers]..sort((a, b) {
        final ba = (a['netBalance'] as num?)?.toDouble() ?? 0;
        final bb = (b['netBalance'] as num?)?.toDouble() ?? 0;
        return bb.compareTo(ba);
      });

    final grandTotal = customers.fold(
        0.0, (s, c) => s + ((c['netBalance'] as num?)?.toDouble() ?? 0));
    final totalCustomers = customers.length;
    final withDue = customers
        .where((c) => ((c['netBalance'] as num?)?.toDouble() ?? 0) > 0)
        .length;
    final settled = totalCustomers - withDue;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        build: (ctx) => [
          // ── Header ────────────────────────────────────────
          pw.Center(
            child: pw.Column(children: [
              pw.Text(shopName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _green)),
              pw.SizedBox(height: 4),
              pw.Text('All Customer Debt Report',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11, color: _gray)),
              pw.SizedBox(height: 3),
              pw.Text('Generated on  $generatedOn',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 8, color: _gray)),
            ]),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: _green, thickness: 1.5),
          pw.SizedBox(height: 14),

          // ── 4 summary boxes ────────────────────────────────
          pw.Row(children: [
            _summaryBox(
                'Total Outstanding', '${grandTotal.toStringAsFixed(2)}', _red,
                bold: true),
            pw.SizedBox(width: 8),
            _summaryBox('Total Customers', '$totalCustomers', _black),
            pw.SizedBox(width: 8),
            _summaryBox('With Due', '$withDue', _red),
            pw.SizedBox(width: 8),
            _summaryBox('Settled', '$settled', _green),
          ]),
          pw.SizedBox(height: 20),

          // ── Customer table ─────────────────────────────────

          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: _borderGray, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FixedColumnWidth(88),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FixedColumnWidth(90),
              5: const pw.FixedColumnWidth(50),
            },
            children: [
              // Header
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
                children: [
                  _cell('No.', bold: true, center: true),
                  _cell('Name', bold: true),
                  _cell('Phone', bold: true),
                  _cell('Address', bold: true),
                  _cell('Outstanding', bold: true, right: true),
                  _cell('Status', bold: true, center: true),
                ],
              ),

              // Data rows
              ...sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final balance = (c['netBalance'] as num?)?.toDouble() ?? 0;
                final hasDue = balance > 0;
                final bg = i.isEven ? _white : _lightGray;
                final address = c['address'] as String? ?? '-';

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell('${i + 1}', center: true, color: _gray, small: true),
                    _cell(c['name'] as String? ?? '', bold: true),
                    _cell(c['phone'] as String? ?? '',
                        color: _gray, small: true),
                    _cell(address, color: _gray, small: true),
                    _cell('${balance.toStringAsFixed(2)}',
                        right: true, bold: true, color: hasDue ? _red : _green),
                    _statusCell(!hasDue),
                  ],
                );
              }),

              // ── Grand total row ────────────────────────────
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
                children: [
                  _cell('', center: true),
                  _cell('Grand Total', bold: true, color: _black),
                  _cell(''),
                  _cell(''),
                  _cell(
                    ' ${grandTotal.toStringAsFixed(2)}',
                    right: true,
                    bold: true,
                    color: _red,
                  ),
                  _cell(''),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
        ],
      ),
    );

    return pdf.save();
  }

  // ────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ────────────────────────────────────────────────────────────

  static pw.Widget _header(String shopName, String subtitle) => pw.Center(
        child: pw.Column(children: [
          pw.Text(shopName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.SizedBox(height: 4),
          pw.Text(subtitle,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 11, color: _gray)),
        ]),
      );

  static pw.Widget _sectionTitle(String title, PdfColor color) =>
      pw.Row(children: [
        pw.Container(
            width: 3,
            height: 14,
            decoration: pw.BoxDecoration(
                color: color, borderRadius: pw.BorderRadius.circular(2))),
        pw.SizedBox(width: 6),
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
      ]);

  static pw.Widget _summaryBox(
    String label,
    String value,
    PdfColor color, {
    bool bold = false,
  }) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: color, width: 1.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: color)),
              pw.SizedBox(height: 5),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      );

  // ── Debt table ─────────────────────────────────────────────
  static pw.Widget _debtTable(
    List<Map<String, dynamic>> rows, {
    required bool isPaid,
  }) {
    final total = rows.fold(0.0, (s, r) => s + _amt(r));

    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(88),
        2: const pw.FlexColumnWidth(),
        3: const pw.FixedColumnWidth(82),
        4: const pw.FixedColumnWidth(46),
      },
      children: [
        // Header
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
          children: [
            _cell('#', bold: true, center: true),
            _cell('Date', bold: true),
            _cell('Description', bold: true),
            _cell('Amount', bold: true, right: true),
            _cell('Status', bold: true, center: true),
          ],
        ),

        // Data
        ...rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          final bg = i.isEven ? _white : _lightGray;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _cell('${i + 1}', center: true, color: _gray, small: true),
              _cell(_fmtDate(row['date']), color: _gray, small: true),
              _cell(row['description'] as String? ?? '-', color: _black),
              _cell('₹ ${_amt(row).toStringAsFixed(2)}',
                  right: true, bold: true, color: isPaid ? _green : _red),
              _statusCell(isPaid),
            ],
          );
        }),

        // Total row
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
          children: [
            _cell('', center: true),
            _cell(''),
            _cell('Total', bold: true, color: _black),
            _cell(' ${total.toStringAsFixed(2)}',
                right: true, bold: true, color: isPaid ? _green : _red),
            _cell(''),
          ],
        ),
      ],
    );
  }

  // ── Credit table ───────────────────────────────────────────
  static pw.Widget _creditTable(List<Map<String, dynamic>> rows) {
    final total = rows.fold(0.0, (s, r) => s + _amt(r));

    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(88),
        2: const pw.FlexColumnWidth(),
        3: const pw.FixedColumnWidth(82),
      },
      children: [
        // Header
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
          children: [
            _cell('#', bold: true, center: true),
            _cell('Date', bold: true),
            _cell('Note', bold: true),
            _cell('Amount', bold: true, right: true),
          ],
        ),

        // Data
        ...rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          final bg = i.isEven ? _white : _lightGray;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _cell('${i + 1}', center: true, color: _gray, small: true),
              _cell(_fmtDate(row['date']), color: _gray, small: true),
              _cell(row['description'] as String? ?? '-', color: _black),
              _cell(' ${_amt(row).toStringAsFixed(2)}',
                  right: true, bold: true, color: _green),
            ],
          );
        }),

        // Total row
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
          children: [
            _cell('', center: true),
            _cell(''),
            _cell('Total', bold: true, color: _black),
            _cell(' ${total.toStringAsFixed(2)}',
                right: true, bold: true, color: _green),
          ],
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  static double _amt(Map<String, dynamic> row) =>
      (row['amount'] as num).toDouble();

  static DateTime _dateOf(Map<String, dynamic> row) =>
      DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime(0);

  static String _fmtDate(dynamic raw) {
    final d = DateTime.tryParse(raw as String? ?? '');
    return d != null ? DateFormat('dd MMM yyyy').format(d) : '-';
  }

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
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: small ? 8 : 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          )),
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
