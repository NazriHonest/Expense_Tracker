import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _isLoading = false;
  String? _exportData;

  Future<void> _fetchAndGenerateCSV() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getExportData();

      // Handle potential null or empty data
      final expenses = data['expenses'] as List? ?? [];
      final income = data['income'] as List? ?? [];

      StringBuffer csv = StringBuffer();
      csv.writeln("Type,Date,Category,Title,Amount,Notes");

      for (var e in expenses) {
        csv.writeln(
          "Expense,${e['date'] ?? ''},${e['category'] ?? ''},${e['title'] ?? ''},${e['amount'] ?? 0},${e['notes'] ?? ''}",
        );
      }
      for (var i in income) {
        csv.writeln(
          "Income,${i['date'] ?? ''},${i['category'] ?? ''},${i['title'] ?? ''},${i['amount'] ?? 0},${i['notes'] ?? ''}",
        );
      }

      if (mounted) {
        setState(() => _exportData = csv.toString());

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "CSV generated successfully! ${expenses.length + income.length} transactions",
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_exportData != null) {
      Clipboard.setData(ClipboardData(text: _exportData!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("CSV copied to clipboard!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Export Data"),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.table_chart_rounded,
                      size: 40,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Export your entire transaction history to CSV format for use in Excel or Google Sheets.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: _isLoading ? null : _fetchAndGenerateCSV,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded),
                              SizedBox(width: 8),
                              Text("Generate CSV"),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CSV Preview
            if (_exportData != null) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CSV Preview",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _exportData!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy_rounded),
                label: const Text("Copy to Clipboard"),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
