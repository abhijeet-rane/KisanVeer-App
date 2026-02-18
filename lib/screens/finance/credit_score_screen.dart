import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/services/financial_service.dart';

class CreditScoreScreen extends StatefulWidget {
  const CreditScoreScreen({Key? key}) : super(key: key);

  @override
  State<CreditScoreScreen> createState() => _CreditScoreScreenState();
}

class _CreditScoreScreenState extends State<CreditScoreScreen> {
  final _financialService = FinancialService();
  bool _isLoading = true;
  int _creditScore = 0;
  Map<String, double> _scoreFactors = {};

  @override
  void initState() {
    super.initState();
    _loadCreditScore();
  }

  Future<void> _loadCreditScore() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Calculate credit score based on financial data
      final score = await _financialService.calculateCreditScore();
      final factors = await _financialService.getCreditScoreFactors();

      setState(() {
        _creditScore = score;
        _scoreFactors = factors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading credit score: $e')),
        );
      }
    }
  }

  String _getCreditRating(int score) {
    if (score >= 750) return 'Excellent';
    if (score >= 700) return 'Good';
    if (score >= 650) return 'Fair';
    if (score >= 600) return 'Poor';
    return 'Very Poor';
  }

  Color _getCreditScoreColor(int score) {
    if (score >= 750) return Colors.green;
    if (score >= 700) return Colors.lightGreen;
    if (score >= 650) return Colors.orange;
    if (score >= 600) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Score'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadCreditScore,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildScoreCard(),
              const SizedBox(height: 24),
              _buildScoreFactors(),
              const SizedBox(height: 24),
              _buildRecommendations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Your Credit Score',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: _creditScore / 900,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCreditScoreColor(_creditScore),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _creditScore.toString(),
                      style: AppTextStyles.h1.copyWith(
                        color: _getCreditScoreColor(_creditScore),
                      ),
                    ),
                    Text(
                      _getCreditRating(_creditScore),
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildScoreFactors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score Factors', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            ..._scoreFactors.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(delay: 200.ms);
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommendations', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            _buildRecommendationItem(
              'Make timely loan payments',
              'Regular payments improve your credit score',
              Icons.schedule,
            ),
            _buildRecommendationItem(
              'Keep credit utilization low',
              'Try to use less than 30% of your credit limit',
              Icons.credit_card,
            ),
            _buildRecommendationItem(
              'Maintain long-term loans',
              'Longer credit history helps your score',
              Icons.history,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(delay: 400.ms);
  }

  Widget _buildRecommendationItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.subtitle),
      subtitle: Text(subtitle),
    );
  }
}
