import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/financial_models.dart';
import 'package:kisan_veer/services/financial_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_card.dart';
import 'package:kisan_veer/screens/finance/add_loan_screen.dart';
import 'package:kisan_veer/screens/finance/add_transaction_screen.dart';
import 'package:kisan_veer/screens/finance/credit_score_screen.dart';
import 'package:kisan_veer/screens/finance/loan_payment_screen.dart';
import 'package:kisan_veer/screens/finance/financial_reports_screen.dart';
import 'package:kisan_veer/screens/finance/loan_details_screen.dart';
import 'package:kisan_veer/widgets/loan_card.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final FinancialService _financialService = FinancialService();

  List<FinancialTransaction> _incomeTransactions = [];
  List<FinancialTransaction> _expenseTransactions = [];
  List<Loan> _loans = [];
  Map<String, double> _monthlyTotals = {};
  double _totalLoanAmount = 0;
  double _totalPaidAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load transactions
      final incomes = await _financialService.getIncomeTransactions();
      final expenses = await _financialService.getExpenseTransactions();
      final loans = await _financialService.getLoans();

      // Calculate totals for loans
      final totalLoanAmount =
          loans.fold<double>(0, (sum, loan) => sum + loan.totalAmount);
      final totalPaidAmount = loans.fold<double>(
          0, (sum, loan) => sum + (loan.totalAmount - loan.remainingAmount));

      // Fetch monthly totals using the same logic as reports
      final monthlyTotals = await _financialService.getMonthlyTotals(DateTime.now());
      final income = monthlyTotals['income'] ?? 0.0;
      final expense = monthlyTotals['expense'] ?? 0.0;
      final balance = income - expense;

      setState(() {
        _incomeTransactions = incomes;
        _expenseTransactions = expenses;
        _loans = loans;
        _monthlyTotals = {
          'income': income,
          'expense': expense,
          'balance': balance,
        };
        _totalLoanAmount = totalLoanAmount;
        _totalPaidAmount = totalPaidAmount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Financial Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Transactions'),
            Tab(text: 'Loans'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildTransactionsTab(),
                _buildLoansTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'finance_fab',
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardTab() {
    final totalIncome = _monthlyTotals['income'] ?? 0.0;
    final totalExpense = _monthlyTotals['expense'] ?? 0.0;
    final balance = _monthlyTotals['balance'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: AppTextStyles.subtitle.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: AppTextStyles.heading.copyWith(
                            color: balance >= 0 ? Colors.green : Colors.red,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBalanceItem(
                      'Income',
                      totalIncome,
                      Icons.arrow_upward,
                      Colors.green,
                    ),
                    _buildBalanceItem(
                      'Expenses',
                      totalExpense,
                      Icons.arrow_downward,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
          const SizedBox(height: 20),
          CustomButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinancialReportsScreen(),
                ),
              );
            },
            text: 'View Reports',
            icon: Icons.bar_chart,
          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
          const SizedBox(height: 20),
          _buildLoanSummary(),
          const SizedBox(height: 20),
          Text(
            'Recent Transactions',
            style: AppTextStyles.heading,
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          Column(
            children: _buildRecentTransactions(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRecentTransactions() {
    final allTransactions = [..._incomeTransactions, ..._expenseTransactions]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return allTransactions.take(5).map((transaction) {
      final isIncome = _incomeTransactions.contains(transaction);

      return CustomCard(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          title: Text(transaction.title),
          subtitle: Text(
            transaction.category,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ).animate().fadeIn().slideX();
    }).toList();
  }

  Widget _buildLoanSummary() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightGreen.shade700, Colors.lightGreen.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Summary',
              style: AppTextStyles.h2.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildLoanSummaryRow('Total Loans', _totalLoanAmount, Colors.indigo),
            const SizedBox(height: 12),
            _buildLoanSummaryRow('Total Paid', _totalPaidAmount, Colors.green),
            const SizedBox(height: 12),
            _buildLoanSummaryRow('Remaining', _totalLoanAmount - _totalPaidAmount, Colors.red),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreditScoreScreen(),
                  ),
                );
              },
              icon: Icon(Icons.analytics, color: Colors.white),
              label: Text(
                'View Credit Score',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY();
  }

  Widget _buildLoanSummaryRow(String title, double amount, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }





  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final wholePart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$wholePart.${parts[1]}';
  }

  Widget _buildTransactionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_incomeTransactions.isEmpty && _expenseTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: AppTextStyles.h3.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first transaction',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddTransactionScreen(isIncome: true),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                  text: 'Add Income',
                  icon: Icons.add,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                CustomButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddTransactionScreen(isIncome: false),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                  text: 'Add Expense',
                  icon: Icons.add,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      );
    }

    final allTransactions = [..._incomeTransactions, ..._expenseTransactions]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allTransactions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddTransactionScreen(isIncome: true),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      text: 'Add Income',
                      icon: Icons.add,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddTransactionScreen(isIncome: false),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      text: 'Add Expense',
                      icon: Icons.add,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }

          final transaction = allTransactions[index - 1];
          final isIncome = _incomeTransactions.contains(transaction);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CustomCard(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  transaction.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  transaction.category,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '₹${transaction.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),
          );
        },
      ),
    );
  }

  Widget _buildLoansTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _loans.isEmpty
            ? Center(
                child: Text(
                  'No loans found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _loans.length,
                itemBuilder: (context, index) {
                  final loan = _loans[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: LoanCard(
                      loan: loan,
                      onPaymentSuccess: _loadData,
                    ),
                  );
                },
              );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.add, color: Colors.green),
              ),
              title: const Text('Add Income'),
              onTap: () {
                Navigator.pop(context);
                _showAddTransactionScreen(true);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.remove, color: Colors.red),
              ),
              title: const Text('Add Expense'),
              onTap: () {
                Navigator.pop(context);
                _showAddTransactionScreen(false);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child:
                    const Icon(Icons.account_balance, color: AppColors.primary),
              ),
              title: const Text('Add Loan'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLoanScreen(),
                  ),
                );
                if (result == true) {
                  await _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTransactionScreen(bool isIncome) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(isIncome: isIncome),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }
}
