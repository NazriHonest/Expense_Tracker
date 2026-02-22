import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// For jsonEncode if needed for file saving (or csv lib)
// If you want actual file saving on mobile, you'd need path_provider + permissions.
// For now, we'll display the raw CSV data in a dialog or copy to clipboard for MVP simplicity
// as "Download" behavior varies wildly on Android/iOS/Web.

import '../services/api_service.dart';
import '../widgets/glass_widgets.dart';

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
      final expenses = data['expenses'] as List;
      final income = data['income'] as List;

      StringBuffer csv = StringBuffer();
      csv.writeln("Type,Date,Category,Title,Amount,Notes");

      for (var e in expenses) {
        csv.writeln(
          "Expense,${e['date']},${e['category']},${e['title']},${e['amount']},${e['notes'] ?? ''}",
        );
      }
      for (var i in income) {
        csv.writeln(
          "Income,${i['date']},${i['category']},${i['title']},${i['amount']},${i['notes'] ?? ''}",
        );
      }

      setState(() => _exportData = csv.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_exportData != null) {
      Clipboard.setData(ClipboardData(text: _exportData!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("CSV copied to clipboard!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Export Data"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GlassBox(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.table_chart_rounded,
                    size: 50,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Export your entire transaction history to CSV format for use in Excel or Google Sheets.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchAndGenerateCSV,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text("Generate CSV"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_exportData != null) ...[
              Expanded(
                child: GlassBox(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      _exportData!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy_rounded),
                label: const Text("Copy to Clipboard"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
