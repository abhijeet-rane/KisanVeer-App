import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:kisan_veer/models/financial_models.dart';
import 'package:kisan_veer/services/financial_service.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class LoanPaymentScreen extends StatefulWidget {
  final Loan loan;
  final VoidCallback onPaymentSuccess;

  const LoanPaymentScreen({
    Key? key,
    required this.loan,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  State<LoanPaymentScreen> createState() => _LoanPaymentScreenState();
}

class _LoanPaymentScreenState extends State<LoanPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late Razorpay _razorpay;
  final FinancialService _financialService = FinancialService();
  bool _isProcessing = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _razorpay.clear();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      await _financialService.updateLoanRemainingAmount(
        widget.loan.id,
        amount,
        'Razorpay',
      );

      // Play success sound
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      await _audioPlayer.onPlayerComplete.first;

      // Insert payment details into Supabase
      await Supabase.instance.client
          .from('loan_payments')
          .insert({
        'loan_id': widget.loan.id,
        'amount': amount,
        'payment_method': 'Razorpay',
        'transaction_id': response.paymentId, // Store transaction ID
        'timestamp': DateTime.now().toIso8601String(), // Add timestamp
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Successful!')),
        );

        widget.onPaymentSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating loan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _startPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    if (amount > widget.loan.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount cannot exceed remaining loan balance')),
      );
      return;
    }

    // Fetch API key from Supabase
  final supabaseService = SupabaseService();
  String? apiKey = await supabaseService.getpaymentApiKey('razorpay_key');

  if (apiKey == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: Unable to retrieve API key')),
    );
    return;
  }

    var options = {
      'key': apiKey,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'KisanVeer',
      'description': 'Loan Payment - ${widget.loan.title}',
      'prefill': {
        'contact': '', // Add user's phone number if available
        'email': '', // Add user's email if available
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make Payment'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Loan Title', widget.loan.title),
                      _buildDetailRow(
                          'Total Amount', '₹${widget.loan.totalAmount}'),
                      _buildDetailRow(
                          'Remaining', '₹${widget.loan.remainingAmount}'),
                      _buildDetailRow(
                          'Account No.', widget.loan.accountNumber ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Payment Amount',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid amount';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (amount > widget.loan.remainingAmount) {
                    return 'Amount cannot exceed remaining balance';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _startPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
