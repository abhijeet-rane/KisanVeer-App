// lib/screens/marketplace/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/screens/marketplace/order_confirmation_screen.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/services/profile_service.dart';
import 'package:kisan_veer/services/supabase_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ProfileService _profileService = ProfileService();
  final SupabaseService _supabaseService = SupabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _razorpay = Razorpay();
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<Address> _savedAddresses = [];
  Address? _selectedAddress;
  bool _isLoading = true;
  bool _useNewAddress = false;
  bool _processingPayment = false;
  String? _razorpayError;

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadSavedAddresses();
    _loadProfileAddressIfNeeded();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final addresses = await _marketplaceService.getSavedAddresses();
      setState(() {
        _savedAddresses = addresses;
        if (addresses.isNotEmpty) {
          _selectedAddress = addresses.first;
        }
        _isLoading = false;
      });
      // If no addresses, try loading from profile
      if (addresses.isEmpty) {
        await _loadProfileAddressIfNeeded();
      }
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading addresses: $e')),
        );
      }
    }
  }

  Future<void> _loadProfileAddressIfNeeded() async {
    if (_savedAddresses.isNotEmpty) return;
    final userProfile = await _profileService.getUserProfile();
    if (userProfile != null && (userProfile.address.isNotEmpty || userProfile.city.isNotEmpty || userProfile.pincode.isNotEmpty)) {
      final profileAddress = Address(
        id: const Uuid().v4(),
        userId: userProfile.uid,
        name: userProfile.name,
        fullAddress: userProfile.address,
        city: userProfile.city,
        state: userProfile.state,
        pincode: userProfile.pincode,
        phone: userProfile.phoneNumber,
        isDefault: true,
      );
      setState(() {
        _savedAddresses.insert(0, profileAddress);
        _selectedAddress = profileAddress;
      });
    }
  }

  void _selectAddress(Address address) {
    setState(() {
      _selectedAddress = address;
      _useNewAddress = false;
    });
  }

  void _toggleNewAddress() {
    setState(() {
      _useNewAddress = !_useNewAddress;
      if (_useNewAddress) {
        _selectedAddress = null;
      } else if (_savedAddresses.isNotEmpty) {
        _selectedAddress = _savedAddresses.first;
      }
    });
  }

  Future<void> _saveNewAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final newAddress = Address(
      id: const Uuid().v4(),
      userId: await _marketplaceService.getCurrentUserId(),
      name: _nameController.text,
      fullAddress: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      pincode: _pincodeController.text,
      phone: _phoneController.text,
      isDefault: _savedAddresses.isEmpty,
    );

    try {
      await _marketplaceService.saveAddress(newAddress);
      setState(() {
        _savedAddresses.add(newAddress);
        _selectedAddress = newAddress;
        _useNewAddress = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    }
  }

  Future<void> _proceedToPayment() async {
    if (_useNewAddress && !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAddress == null && !_useNewAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add an address')),
      );
      return;
    }

    setState(() => _processingPayment = true);

    // Fetch Razorpay API key from Supabase
    String? apiKey = await _supabaseService.getPaymentApiKey('razorpay_key');
    if (apiKey == null) {
      setState(() => _processingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Unable to retrieve payment API key')),
      );
      return;
    }

    // Setup Razorpay options
    var options = {
      'key': apiKey,
      'amount': (widget.totalAmount * 100).toInt(), // Razorpay accepts amount in paisa
      'name': 'Kisan Veer',
      'description': 'Payment for marketplace order',
      'prefill': {
        'contact': _useNewAddress ? _phoneController.text : _selectedAddress!.phone,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
      setState(() {
        _processingPayment = false;
        _razorpayError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating payment: $e')),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment success: ${response.paymentId}');
    
    try {
      // Determine which address to use
      Address address;
      if (_useNewAddress) {
        // Create new address if user added one
        address = Address(
          id: const Uuid().v4(),
          userId: await _marketplaceService.getCurrentUserId(),
          name: _nameController.text,
          fullAddress: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
          pincode: _pincodeController.text,
          phone: _phoneController.text,
          isDefault: false,
        );
        
        // Save the address for future use
        await _marketplaceService.saveAddress(address);
      } else {
        // Use selected address
        address = _selectedAddress!;
      }
      
      // Create order using our updated service method
      final order = await _marketplaceService.createOrderFromCart(
        totalAmount: widget.totalAmount,
        address: address,
        paymentMethod: 'razorpay',
        paymentId: response.paymentId,
      );

      if (mounted) {
        setState(() => _processingPayment = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: order),
          ),
        );
      }
    } catch (e) {
      print('Error creating order: $e');
      if (mounted) {
        setState(() => _processingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: $e')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment error: ${response.message}');
    setState(() {
      _processingPayment = false;
      _razorpayError = response.message ?? 'Payment failed';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet: ${response.walletName}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment through: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryAddress(),
                  const SizedBox(height: 24),
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  _buildPaymentSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _toggleNewAddress,
                  child: Text(
                    _useNewAddress ? 'Use Saved\nAddress' : 'Add New',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_useNewAddress) ..._buildSavedAddresses(),
            if (_useNewAddress) _buildNewAddressForm(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSavedAddresses() {
    if (_savedAddresses.isEmpty) {
      return [
        const Text('No saved addresses. Please add a new address.'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _toggleNewAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add New Address'),
        ),
      ];
    }

    return [
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _savedAddresses.length,
        itemBuilder: (context, index) {
          final address = _savedAddresses[index];
          return RadioListTile<Address>(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  address.fullAddress,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            subtitle: Text(
              '${address.city}, ${address.state}, ${address.pincode}\n📞 ${address.phone}',
            ),
            value: address,
            groupValue: _selectedAddress,
            activeColor: AppColors.primary,
            onChanged: (Address? value) {
              if (value != null) _selectAddress(value);
            },
          );
        },
      ),
    ];
  }

  Widget _buildNewAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the recipient name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Full Address',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pincode';
                    }
                    if (value.length != 6 || int.tryParse(value) == null) {
                      return 'Please enter valid 6-digit pincode';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixText: '+91 ',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length != 10 || int.tryParse(value) == null) {
                      return 'Please enter valid 10-digit number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveNewAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                final product = item.product;
                if (product == null) return const SizedBox();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: product.imageUrls.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(product.imageUrls.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey[200],
                        ),
                        child: product.imageUrls.isEmpty
                            ? const Icon(Icons.image_not_supported, size: 25)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${product.price.toStringAsFixed(2)} × ${item.quantity} ${product.unit}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${(product.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₹${widget.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Delivery Fee'),
                Text('₹0.00'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/razorpay_logo.png',
                    width: 30,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.payment,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Razorpay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Radio(
                    value: true,
                    groupValue: true,
                    activeColor: AppColors.primary,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
            if (_razorpayError != null) ...[              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _razorpayError!,
                        style: TextStyle(
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Pay Now - ₹${widget.totalAmount.toStringAsFixed(2)}',
              onPressed: _processingPayment ? null : _proceedToPayment,
              color: AppColors.primary,
              textColor: Colors.white,
              isLoading: _processingPayment,
              icon: Icons.payment,
            ),
          ],
        ),
      ),
    );
  }
}