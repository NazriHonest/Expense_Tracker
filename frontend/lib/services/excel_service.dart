import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/savings_goal.dart';
import '../models/budget.dart';

/// Excel export service for financial data
class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  final currencyFormat = NumberFormat.simpleCurrency();

  /// Export expenses to Excel
  Future<File> exportExpenses(List<Expense> expenses) async {
    final excel = Excel.createExcel();
    final sheet = excel['Expenses'];

    // Header row
    final headerRow = [
      'ID',
      'Title',
      'Amount',
      'Category',
      'Date',
      'Notes',
      'Wallet',
    ];
    _appendRow(sheet, headerRow);

    // Style header row
    for (var i = 0; i < headerRow.length; i++) {
      final cellIndex = CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0);
      final cell = sheet.cell(cellIndex);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.grey,
        fontColorHex: ExcelColor.white,
      );
    }

    // Data rows
    for (var i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      _appendRow(sheet, [
        expense.id?.toString() ?? '',
        expense.title,
        expense.amount,
        expense.category,
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.notes ?? '',
        expense.walletId?.toString() ?? '',
      ]);
    }

    // Auto-fit columns
    _autoFitColumns(sheet);

    return await _saveFile(
        excel, 'expenses_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
  }

  /// Export income to Excel
  Future<File> exportIncome(List<Income> incomes) async {
    final excel = Excel.createExcel();
    final sheet = excel['Income'];

    _appendRow(sheet, ['ID', 'Source', 'Amount', 'Category', 'Date', 'Notes']);

    for (var i = 0; i < 6; i++) {
      final cellIndex = CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0);
      final cell = sheet.cell(cellIndex);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.green,
        fontColorHex: ExcelColor.white,
      );
    }

    for (final income in incomes) {
      _appendRow(sheet, [
        income.id?.toString() ?? '',
        income.title, // Income uses 'title' not 'source'
        income.amount,
        income.category,
        DateFormat('yyyy-MM-dd').format(income.date),
        income.notes ?? '',
      ]);
    }

    _autoFitColumns(sheet);
    return await _saveFile(
        excel, 'income_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
  }

  /// Export comprehensive financial report
  Future<File> exportFinancialReport({
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<BudgetStatus> budgets,
    required List<SavingsGoal> goals,
  }) async {
    final excel = Excel.createExcel();

    // Summary Sheet
    final summarySheet = excel['Summary'];
    _createSummarySheet(summarySheet, expenses, incomes, budgets, goals);

    // Expenses Sheet
    final expensesSheet = excel['Expenses'];
    _createExpensesSheet(expensesSheet, expenses);

    // Income Sheet
    final incomeSheet = excel['Income'];
    _createIncomeSheet(incomeSheet, incomes);

    // Budgets Sheet
    final budgetsSheet = excel['Budgets'];
    _createBudgetsSheet(budgetsSheet, budgets);

    // Goals Sheet
    final goalsSheet = excel['Savings Goals'];
    _createGoalsSheet(goalsSheet, goals);

    return await _saveFile(
        excel, 'financial_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
  }

  void _createSummarySheet(
      Sheet sheet, List<Expense> expenses, List<Income> incomes, List<BudgetStatus> budgets, List<SavingsGoal> goals) {
    final totalIncome = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.limit);
    final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    final netSavings = totalIncome - totalExpenses;

    _appendRow(sheet, ['Financial Summary', '']);
    _appendRow(sheet, ['Generated', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())]);
    _appendRow(sheet, ['', '']);
    _appendRow(sheet, ['Total Income', currencyFormat.format(totalIncome)]);
    _appendRow(sheet, ['Total Expenses', currencyFormat.format(totalExpenses)]);
    _appendRow(sheet, ['Net Savings', currencyFormat.format(netSavings)]);
    _appendRow(sheet, ['', '']);
    _appendRow(sheet, ['Total Budget Limit', currencyFormat.format(totalBudget)]);
    _appendRow(sheet, ['Total Savings Goals', currencyFormat.format(totalSaved)]);

    // Style
    final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    headerCell.cellStyle = CellStyle(bold: true, fontSize: 16);
  }

  void _createExpensesSheet(Sheet sheet, List<Expense> expenses) {
    _appendRow(sheet, ['ID', 'Title', 'Amount', 'Category', 'Date', 'Notes', 'Wallet']);

    for (var i = 0; i < 7; i++) {
      final cellIndex = CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0);
      final cell = sheet.cell(cellIndex);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.red,
        fontColorHex: ExcelColor.white,
      );
    }

    for (final expense in expenses) {
      _appendRow(sheet, [
        expense.id?.toString() ?? '',
        expense.title,
        expense.amount,
        expense.category,
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.notes ?? '',
        expense.walletId?.toString() ?? '',
      ]);
    }

    _autoFitColumns(sheet);
  }

  void _createIncomeSheet(Sheet sheet, List<Income> incomes) {
    _appendRow(sheet, ['ID', 'Source', 'Amount', 'Category', 'Date', 'Notes']);

    for (var i = 0; i < 6; i++) {
      final cellIndex = CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0);
      final cell = sheet.cell(cellIndex);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.green,
        fontColorHex: ExcelColor.white,
      );
    }

    for (final income in incomes) {
      _appendRow(sheet, [
        income.id?.toString() ?? '',
        income.title,
        income.amount,
        income.category,
        DateFormat('yyyy-MM-dd').format(income.date),
        income.notes ?? '',
      ]);
    }

    _autoFitColumns(sheet);
  }

  void _createBudgetsSheet(Sheet sheet, List<BudgetStatus> budgets) {
    _appendRow(sheet, ['Category', 'Limit', 'Spent', 'Remaining', 'Month', 'Year']);

    for (final budget in budgets) {
      _appendRow(sheet, [
        budget.category,
        budget.limit,
        budget.spent,
        budget.remaining,
        budget.id?.toString() ?? '', // Using id as placeholder for month
        '', // Year placeholder (not available in BudgetStatus)
      ]);
    }

    _autoFitColumns(sheet);
  }

  void _createGoalsSheet(Sheet sheet, List<SavingsGoal> goals) {
    _appendRow(sheet, ['Goal', 'Target Amount', 'Current Amount', 'Progress %', 'Deadline']);

    for (final goal in goals) {
      final progress = goal.targetAmount > 0
          ? (goal.currentAmount / goal.targetAmount * 100)
          : 0.0;
      _appendRow(sheet, [
        goal.title, // Use 'title' instead of 'name'
        goal.targetAmount,
        goal.currentAmount,
        '${progress.toStringAsFixed(1)}%',
        DateFormat('yyyy-MM-dd').format(goal.targetDate),
      ]);
    }

    _autoFitColumns(sheet);
  }

  Future<File> _saveFile(Excel excel, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    await file.writeAsBytes(fileBytes);
    debugPrint('💾 Excel file saved: ${file.path}');

    return file;
  }

  /// Export year-over-year comparison
  Future<File> exportYearOverYearComparison(Map<int, List<Expense>> yearlyExpenses) async {
    final excel = Excel.createExcel();
    final sheet = excel['YoY Comparison'];

    // Get all categories
    final allCategories = <String>{};
    for (final expenses in yearlyExpenses.values) {
      for (final expense in expenses) {
        allCategories.add(expense.category);
      }
    }

    // Header row
    final header = ['Category'] + yearlyExpenses.keys.map((y) => y.toString()).toList();
    header.add('Change %');
    _appendRow(sheet, header);

    // Style header
    for (var i = 0; i < header.length; i++) {
      final cellIndex = CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0);
      final cell = sheet.cell(cellIndex);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }

    // Data rows by category
    final sortedYears = yearlyExpenses.keys.toList()..sort();
    for (final category in allCategories) {
      final row = <dynamic>[category];
      for (final year in sortedYears) {
        final yearExpenses = yearlyExpenses[year]!
            .where((e) => e.category == category)
            .fold<double>(0, (sum, e) => sum + e.amount);
        row.add(yearExpenses);
      }

      // Calculate change percentage
      if (sortedYears.length >= 2) {
        final lastYear = yearlyExpenses[sortedYears.last]!
            .where((e) => e.category == category)
            .fold<double>(0, (sum, e) => sum + e.amount);
        final prevYear = yearlyExpenses[sortedYears[sortedYears.length - 2]]!
            .where((e) => e.category == category)
            .fold<double>(0, (sum, e) => sum + e.amount);

        final change = prevYear > 0 ? ((lastYear - prevYear) / prevYear * 100) : 0;
        row.add(change);
      } else {
        row.add(0);
      }

      _appendRow(sheet, row);
    }

    _autoFitColumns(sheet);
    return await _saveFile(excel, 'yoy_comparison_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
  }

  /// Helper method to append a row with proper CellValue? types
  void _appendRow(Sheet sheet, List<dynamic> values) {
    final rowValues = values.map((v) {
      if (v is String) return v;
      if (v is num) return v;
      if (v is DateTime) return v;
      if (v is bool) return v;
      if (v == null) return null;
      return v.toString();
    }).toList();
    sheet.appendRow(rowValues as List<CellValue?>);
  }

  /// Helper method to auto-fit column widths
  void _autoFitColumns(Sheet sheet) {
    // Set a reasonable max column width (excel package doesn't have auto-fit)
    // We iterate through columns and set a fixed width
    for (var col = 0; col < 20; col++) {
      sheet.setColumnWidth(col, 15);
    }
  }
}
