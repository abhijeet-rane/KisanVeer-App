import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/financial_models.dart';
import 'package:kisan_veer/screens/finance/loan_payment_screen.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_card.dart';

class LoanDetailsScreen extends StatelessWidget {
  final Loan loan;

  const LoanDetailsScreen({Key? key, required this.loan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = (loan.totalAmount - loan.remainingAmount) / loan.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.title),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan Progress',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: AppColors.primary,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: ₹${(loan.totalAmount - loan.remainingAmount).toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Remaining: ₹${loan.remainingAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan Details',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Total Amount', '₹${loan.totalAmount.toStringAsFixed(2)}'),
                  _buildDetailRow('Interest Rate',
                    loan.interestRate != null
                      ? '${loan.interestRate!.toStringAsFixed(2)}%'
                      : 'N/A'
                  ),
                  _buildDetailRow('Purpose', loan.purpose),
                  _buildDetailRow('Lender', loan.lenderName),
                  _buildDetailRow('Start Date',
                    '${loan.startDate.day}/${loan.startDate.month}/${loan.startDate.year}'
                  ),
                  if (loan.endDate != null)
                    _buildDetailRow('End Date',
                      '${loan.endDate!.day}/${loan.endDate!.month}/${loan.endDate!.year}'
                    ),
                  _buildDetailRow('Status', loan.status.toUpperCase()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: loan.remainingAmount > 0
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanPaymentScreen(
                      loan: loan,
                      onPaymentSuccess: () {
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                );
              }
                  : () {},  // Disable the button if the loan is fully repaid
              text: 'Make Payment',
              icon: Icons.payment,
              backgroundColor: loan.remainingAmount > 0 ? AppColors.primary : Colors.grey,
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
