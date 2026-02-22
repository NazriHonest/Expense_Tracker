import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class PdfService {
  static Future<void> generateFinancialReport({
    required List<Expense> expenses,
    required double totalSpent,
    required double totalSaved,
    required double budgetLimit,
    required double budgetSpent,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat.yMMMd().format(DateTime.now());
    final remainingBudget = budgetLimit - budgetSpent;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // 1. Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Financial Summary Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Monthly Statement',
                    style: const pw.TextStyle(color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Text(dateStr, style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 30),

          // 2. Financial Metrics Grid
          pw.Row(
            children: [
              _buildMetricCard(
                "Global Spent",
                "\$${totalSpent.toStringAsFixed(2)}",
                PdfColors.red700,
              ),
              pw.SizedBox(width: 20),
              _buildMetricCard(
                "Total Saved",
                "\$${totalSaved.toStringAsFixed(2)}",
                PdfColors.green700,
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              _buildMetricCard(
                "Budget Limit",
                "\$${budgetLimit.toStringAsFixed(2)}",
                PdfColors.blueGrey700,
              ),
              pw.SizedBox(width: 20),
              _buildMetricCard(
                "Remaining Budget",
                "\$${remainingBudget.toStringAsFixed(2)}",
                remainingBudget < 0 ? PdfColors.red : PdfColors.blue700,
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // 3. Transaction Table Title
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          // 4. Table (Maintaining your style)
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            context: context,
            data: <List<String>>[
              <String>['Date', 'Title', 'Category', 'Amount'],
              ...expenses.map(
                (e) => [
                  DateFormat.yMd().format(e.date),
                  e.title,
                  e.category,
                  '\$${e.amount.toStringAsFixed(2)}',
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Helper to build the visual cards in the PDF
  static pw.Widget _buildMetricCard(
    String title,
    String value,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
