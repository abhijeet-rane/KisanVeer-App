import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/scheme_model.dart';
import '../../models/application_model.dart';
import '../../services/schemes_service.dart';
import '../../services/profile_service.dart';

class ApplicationFormScreen extends StatefulWidget {
  final SchemeModel scheme;
  const ApplicationFormScreen({Key? key, required this.scheme})
      : super(key: key);

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SchemesService _schemesService = SchemesService();
  final ProfileService _profileService = ProfileService();

  String? _name;
  String? _phoneNumber;
  String? _state;
  String? _district;
  double? _landholding;
  String? _casteCategory;
  List<File> _selectedFiles = [];
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getUserProfile();
      setState(() {
        _name = profile?.name ?? '';
        _phoneNumber = profile?.phoneNumber ?? '';
        _state = profile?.state ?? '';
        _district = profile?.city ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user profile: $e';
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles =
            result.paths.whereType<String>().map((p) => File(p)).toList();
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });
    try {
      final uploadedFileUrls =
          await _schemesService.uploadApplicationDocuments(_selectedFiles);
      // Use the public method from SchemesService to get the current user id
      final userId = _schemesService.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'You must be logged in to submit an application.';
        });
        return;
      }
      final appModel = ApplicationModel(
        id: '',
        userId: userId,
        schemeId: widget.scheme.id,
        name: _name!,
        phoneNumber: _phoneNumber!,
        state: _state!,
        district: _district!,
        landholding: _landholding!,
        casteCategory: _casteCategory!,
        uploadedFiles: uploadedFileUrls,
        status: 'Pending',
        remarks: null,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _schemesService.createApplication(appModel);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Application submitted successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit application: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  List<String> _getDistrictsForState(String? state) {
    final districtMap = {
      'Maharashtra': [
        'Pune',
        'Mumbai',
        'Nagpur',
        'Nashik',
        'Aurangabad',
        'Solapur',
        'Kolhapur',
        'Others'
      ],
      'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Others'],
      'Madhya Pradesh': [
        'Indore',
        'Bhopal',
        'Jabalpur',
        'Gwalior',
        'Ujjain',
        'Others'
      ],
      'Rajasthan': ['Jaipur', 'Jodhpur', 'Kota', 'Ajmer', 'Udaipur', 'Others'],
      'Karnataka': [
        'Bengaluru',
        'Mysuru',
        'Mangaluru',
        'Hubballi-Dharwad',
        'Belagavi',
        'Others'
      ],
      'Uttar Pradesh': [
        'Lucknow',
        'Kanpur',
        'Ghaziabad',
        'Agra',
        'Varanasi',
        'Others'
      ],
      'Punjab': [
        'Ludhiana',
        'Amritsar',
        'Jalandhar',
        'Patiala',
        'Bathinda',
        'Others'
      ],
      'Haryana': [
        'Faridabad',
        'Gurugram',
        'Rohtak',
        'Hisar',
        'Panipat',
        'Others'
      ],
      'Bihar': [
        'Patna',
        'Gaya',
        'Bhagalpur',
        'Muzaffarpur',
        'Darbhanga',
        'Others'
      ],
      'West Bengal': [
        'Kolkata',
        'Asansol',
        'Siliguri',
        'Durgapur',
        'Bardhaman',
        'Others'
      ],
      'Tamil Nadu': [
        'Chennai',
        'Coimbatore',
        'Madurai',
        'Tiruchirappalli',
        'Salem',
        'Others'
      ],
      'Andhra Pradesh': [
        'Visakhapatnam',
        'Vijayawada',
        'Guntur',
        'Nellore',
        'Kurnool',
        'Others'
      ],
      'Telangana': [
        'Hyderabad',
        'Warangal',
        'Karimnagar',
        'Nizamabad',
        'Khammam',
        'Others'
      ],
      'Kerala': [
        'Thiruvananthapuram',
        'Kochi',
        'Kozhikode',
        'Thrissur',
        'Kollam',
        'Others'
      ],
      'Odisha': [
        'Bhubaneswar',
        'Cuttack',
        'Rourkela',
        'Berhampur',
        'Sambalpur',
        'Others'
      ],
      'Chhattisgarh': [
        'Raipur',
        'Bilaspur',
        'Durg',
        'Rajnandgaon',
        'Korba',
        'Others'
      ],
      'Jharkhand': [
        'Ranchi',
        'Jamshedpur',
        'Dhanbad',
        'Bokaro',
        'Deoghar',
        'Others'
      ],
      'Assam': [
        'Guwahati',
        'Silchar',
        'Dibrugarh',
        'Jorhat',
        'Nagaon',
        'Others'
      ],
      'Goa': ['Panaji', 'Vasco da Gama', 'Margao', 'Mapusa', 'Ponda', 'Others'],
      'Delhi': [
        'New Delhi',
        'North Delhi',
        'South Delhi',
        'East Delhi',
        'West Delhi',
        'Others'
      ],
      'Others': ['Others']
    };
    return districtMap[state] ?? ['Others'];
  }

  List<String> _getStates() {
    return [
      'Maharashtra',
      'Gujarat',
      'Madhya Pradesh',
      'Rajasthan',
      'Karnataka',
      'Uttar Pradesh',
      'Punjab',
      'Haryana',
      'Bihar',
      'West Bengal',
      'Tamil Nadu',
      'Andhra Pradesh',
      'Telangana',
      'Kerala',
      'Odisha',
      'Chhattisgarh',
      'Jharkhand',
      'Assam',
      'Goa',
      'Delhi',
      'Others'
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Apply for Scheme')),
      body: _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scheme: ${widget.scheme.schemeName}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _name,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name required' : null,
                      onSaved: (v) => _name = v,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      initialValue: _phoneNumber,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Phone required' : null,
                      onSaved: (v) => _phoneNumber = v,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'State'),
                      value: _state != null && _getStates().contains(_state)
                          ? _state
                          : null,
                      items: _getStates()
                          .map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _state = value;
                          _district = null;
                        });
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select state' : null,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'District'),
                      value: _district != null &&
                              _getDistrictsForState(_state).contains(_district)
                          ? _district
                          : null,
                      items: _getDistrictsForState(_state)
                          .map((district) => DropdownMenuItem(
                                value: district,
                                child: Text(district),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _district = value;
                        });
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select district' : null,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                          labelText: 'Landholding (acres/hectares)'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Landholding required'
                          : null,
                      onSaved: (v) => _landholding = double.tryParse(v ?? ''),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Caste Category'),
                      items: ['SC', 'ST', 'OBC', 'General']
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Select caste category'
                          : null,
                      onChanged: (v) => _casteCategory = v,
                    ),
                    SizedBox(height: 16),
                    Text('Upload Required Documents:'),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.attach_file),
                      label: Text('Pick Files'),
                      onPressed: _pickFiles,
                    ),
                    if (_selectedFiles.isNotEmpty)
                      ..._selectedFiles
                          .map((f) => Text(f.path.split('/').last))
                          .toList(),
                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Submit Application'),
                        onPressed: _isSubmitting ? null : _submitApplication,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
