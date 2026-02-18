import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kisan_veer/models/financial_models.dart';

class FinancialService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Income Methods
  Future<List<FinancialTransaction>> getIncomeTransactions() async {
    final response = await _supabase
        .from('income_transactions')
        .select()
        .order('transaction_date', ascending: false);

    return (response as List)
        .map((json) => FinancialTransaction.fromJson(json))
        .toList();
  }

  Future<void> addIncomeTransaction(
      String title,
      String category,
      double amount,
      DateTime date,
      ) async {
    await _supabase.from('income_transactions').insert({
      'title': title,
      'category': category,
      'amount': amount,
      'transaction_date': date.toIso8601String(),
      'user_id': _supabase.auth.currentUser!.id,
    });
  }

  // Expense Methods
  Future<List<FinancialTransaction>> getExpenseTransactions() async {
    final response = await _supabase
        .from('expense_transactions')
        .select()
        .order('transaction_date', ascending: false);

    return (response as List)
        .map((json) => FinancialTransaction.fromJson(json))
        .toList();
  }

  Future<void> addExpenseTransaction(
      String title,
      String category,
      double amount,
      DateTime date,
      ) async {
    await _supabase.from('expense_transactions').insert({
      'title': title,
      'category': category,
      'amount': amount,
      'transaction_date': date.toIso8601String(),
      'user_id': _supabase.auth.currentUser!.id,
    });
  }

  // Loan Methods
  Future<List<Loan>> getLoans() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('loans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Loan.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Loan> addLoan(Loan loan) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final loanData = {
        ...loan.toJson(),
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response =
      await _supabase.from('loans').insert(loanData).select().single();

      return Loan.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLoanRemainingAmount(
      String loanId,
      double paymentAmount,
      String paymentMethod,
      ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get current loan data - using proper ID column
      final loanResponse = await _supabase
          .from('loans')
          .select()
          .eq('id', loanId)
          .maybeSingle(); // Use maybeSingle instead of single to avoid exceptions

      // Check if loan exists
      if (loanResponse == null) {
        throw Exception('Loan not found with ID: $loanId');
      }

      final loan = Loan.fromJson(loanResponse);
      final newRemainingAmount = loan.remainingAmount - paymentAmount;

      // Update loan remaining amount
      await _supabase.from('loans').update({
        'remaining_amount': newRemainingAmount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', loanId);

      // Add payment record
      await _supabase.from('loan_payments').insert({
        'loan_id': loanId,
        'amount': paymentAmount,
        'payment_method': paymentMethod,
        'payment_date': DateTime.now().toIso8601String(),
        'user_id': userId,
      });
    } catch (e) {
      print('Error updating loan: $e');
      rethrow;
    }
  }

  Future<List<LoanPayment>> getLoanPayments(String loanId) async {
    try {
      final response = await _supabase
          .from('loan_payments')
          .select()
          .eq('loan_id', loanId)
          .order('payment_date');

      return (response as List)
          .map((json) => LoanPayment.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Analytics Methods
  Future<Map<String, double>> getMonthlyTotals(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final incomeTransactions = await getIncomeTransactions();
    final expenseTransactions = await getExpenseTransactions();

    final monthlyIncome = incomeTransactions
        .where((t) =>
    t.transactionDate
        .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold<double>(0, (sum, t) => sum + t.amount);

    final monthlyExpense = expenseTransactions
        .where((t) =>
    t.transactionDate
        .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold<double>(0, (sum, t) => sum + t.amount);

    return {
      'income': monthlyIncome,
      'expense': monthlyExpense,
    };
  }

  Future<Map<String, List<FinancialTransaction>>> getTransactionHistory(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final incomeTransactions = await getIncomeTransactions();
      final expenseTransactions = await getExpenseTransactions();

      final filteredIncome = incomeTransactions
          .where((t) =>
      t.transactionDate
          .isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.transactionDate.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      final filteredExpenses = expenseTransactions
          .where((t) =>
      t.transactionDate
          .isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.transactionDate.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      return {
        'income': filteredIncome,
        'expenses': filteredExpenses,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, double>> getFinancialSummary() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .rpc('calculate_balance', params: {'user_id': userId}).single();

    return {
      'currentBalance': (response['current_balance'] ?? 0).toDouble(),
      'totalIncome': (response['total_income'] ?? 0).toDouble(),
      'totalExpenses': (response['total_expenses'] ?? 0).toDouble(),
    };
  }

  Future<Map<String, List<double>>> getMonthlyTrends(int numberOfMonths) async {
    List<double> incomes = List.filled(numberOfMonths, 0.0);
    List<double> expenses = List.filled(numberOfMonths, 0.0);

    final now = DateTime.now();

    for (int i = 0; i < numberOfMonths; i++) {
      final month = DateTime(now.year, now.month - i);
      final totals = await getMonthlyTotals(month);
      // Store in reverse order (oldest first)
      incomes[numberOfMonths - 1 - i] = totals['income'] ?? 0;
      expenses[numberOfMonths - 1 - i] = totals['expense'] ?? 0;
    }

    return {
      'income': incomes,
      'expense': expenses,
    };
  }

  Future<int> calculateCreditScore() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's financial data
      final loans = await getLoans();
      final incomeTransactions = await getIncomeTransactions();
      final expenseTransactions = await getExpenseTransactions();

      // Calculate payment history score (40% weight)
      double paymentHistoryScore = await _calculatePaymentHistoryScore(loans);

      // Calculate credit utilization score (30% weight)
      double creditUtilizationScore = _calculateCreditUtilizationScore(loans);

      // Calculate income stability score (20% weight)
      double incomeStabilityScore =
      _calculateIncomeStabilityScore(incomeTransactions);

      // Calculate expense management score (10% weight)
      double expenseManagementScore = _calculateExpenseManagementScore(
        incomeTransactions,
        expenseTransactions,
      );

      // Calculate final score (base: 300, max additional: 600)
      int finalScore = 300 +
          ((paymentHistoryScore * 240) +
              (creditUtilizationScore * 180) +
              (incomeStabilityScore * 120) +
              (expenseManagementScore * 60))
              .round();

      // Ensure score is within valid range
      return finalScore.clamp(300, 900);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, double>> getCreditScoreFactors() async {
    try {
      final loans = await getLoans();
      final incomeTransactions = await getIncomeTransactions();
      final expenseTransactions = await getExpenseTransactions();

      return {
        'Payment History': await _calculatePaymentHistoryScore(loans),
        'Credit Utilization': _calculateCreditUtilizationScore(loans),
        'Income Stability': _calculateIncomeStabilityScore(incomeTransactions),
        'Expense Management': _calculateExpenseManagementScore(
          incomeTransactions,
          expenseTransactions,
        ),
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<double> _calculatePaymentHistoryScore(List<Loan> loans) async {
    if (loans.isEmpty) return 0.5; // Neutral score for no loan history

    int totalPayments = 0;
    int onTimePayments = 0;

    for (final loan in loans) {
      // Skip loans with empty ID
      if (loan.id.isEmpty) continue;
      
      try {
        final payments = await getLoanPayments(loan.id);
        totalPayments += payments.length;

        // Count payments made before or on due date
        onTimePayments += payments.where((payment) {
          DateTime endDate = loan.endDate ?? DateTime.now();
          return payment.paymentDate.isBefore(endDate) ||
              payment.paymentDate.isAtSameMomentAs(endDate);
        }).length;
      } catch (e) {
        print('Error getting payments for loan ${loan.id}: $e');
        // Continue with other loans if one fails
        continue;
      }
    }

    return totalPayments > 0 ? onTimePayments / totalPayments : 0.5;
  }

  double _calculateCreditUtilizationScore(List<Loan> loans) {
    if (loans.isEmpty) return 0.8; // Good score for no loans

    double totalLoanAmount = 0;
    double totalRemainingAmount = 0;

    for (final loan in loans) {
      totalLoanAmount += loan.totalAmount;
      totalRemainingAmount += loan.remainingAmount;
    }

    if (totalLoanAmount == 0) return 0.8;

    // Calculate utilization ratio (lower is better)
    double utilizationRatio = totalRemainingAmount / totalLoanAmount;

    // Convert to score (1 - ratio, but ensure it's between 0 and 1)
    return (1 - utilizationRatio).clamp(0.0, 1.0);
  }

  double _calculateIncomeStabilityScore(
      List<FinancialTransaction> incomeTransactions) {
    if (incomeTransactions.isEmpty) return 0.5; // Neutral score for no history

    // Group transactions by month
    final monthlyIncomes = <String, double>{};
    for (final transaction in incomeTransactions) {
      final monthKey =
          '${transaction.transactionDate.year}-${transaction.transactionDate.month}';
      monthlyIncomes[monthKey] =
          (monthlyIncomes[monthKey] ?? 0) + transaction.amount;
    }

    if (monthlyIncomes.length < 2)
      return 0.6; // Slightly above neutral for new users

    // Calculate income stability based on variance
    final values = monthlyIncomes.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    final standardDeviation = sqrt(variance);

    // Calculate coefficient of variation (lower is better)
    final cv = standardDeviation / mean;

    // Convert to score (1 - normalized cv, but ensure it's between 0 and 1)
    return (1 - (cv / 2)).clamp(0.0, 1.0);
  }

  double _calculateExpenseManagementScore(
      List<FinancialTransaction> incomeTransactions,
      List<FinancialTransaction> expenseTransactions,
      ) {
    if (incomeTransactions.isEmpty) return 0.5; // Neutral score for no history

    // Calculate total income and expenses
    final totalIncome = incomeTransactions.fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount,
    );

    final totalExpenses = expenseTransactions.fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount,
    );

    if (totalIncome == 0) return 0.5;

    // Calculate expense ratio (lower is better)
    final expenseRatio = totalExpenses / totalIncome;

    // Convert to score (1 - normalized ratio, but ensure it's between 0 and 1)
    return (1 - (expenseRatio / 1.5)).clamp(0.0, 1.0);
  }
}
