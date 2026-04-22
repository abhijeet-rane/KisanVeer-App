import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/financial_models.dart';
import 'package:kisan_veer/screens/finance/loan_details_screen.dart';
import 'package:kisan_veer/screens/finance/loan_payment_screen.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 loan card for the finance Loans tab.
///
/// Title + active/closed status chip, three info columns (amount /
/// rate / due), a thick repayment progress bar, and Details +
/// Make-payment actions wired to [AppPageRoute].
class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    required this.onPaymentSuccess,
  });

  final Loan loan;
  final VoidCallback onPaymentSuccess;

  @override
  Widget build(BuildContext context) {
    final paid = loan.totalAmount - loan.remainingAmount;
    final progress = loan.totalAmount == 0
        ? 0.0
        : (paid / loan.totalAmount).clamp(0.0, 1.0);
    final isActive = loan.remainingAmount > 0;
    final pct = (progress * 100).toStringAsFixed(0);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loan.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.primary : AppColors.success)
                      .withValues(alpha: 0.12),
                  borderRadius: AppRadii.brFull,
                ),
                child: Text(
                  isActive ? 'Active' : 'Closed',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isActive ? AppColors.primary : AppColors.success,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  label: 'Amount',
                  value: '₹${loan.totalAmount.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: 'Interest',
                  value: '${loan.interestRate}%',
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: 'Due date',
                  value: _formatDate(loan.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Repayment progress',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '$pct%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          ClipRRect(
            borderRadius: AppRadii.brFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid ₹${paid.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Remaining ₹${loan.remainingAmount.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Details',
                  variant: AppButtonVariant.tertiary,
                  size: AppButtonSize.md,
                  leadingIcon: Icons.info_outline_rounded,
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(AppPageRoute.of(LoanDetailsScreen(loan: loan)));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: AppButton(
                  label: 'Pay',
                  size: AppButtonSize.md,
                  leadingIcon: Icons.payments_rounded,
                  onPressed: isActive
                      ? () {
                          Navigator.of(context).push(
                            AppPageRoute.of(
                              LoanPaymentScreen(
                                loan: loan,
                                onPaymentSuccess: onPaymentSuccess,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('d MMM yy').format(date);
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
