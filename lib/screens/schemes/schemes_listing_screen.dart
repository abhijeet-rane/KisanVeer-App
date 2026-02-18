import 'package:flutter/material.dart';
import '../../models/scheme_model.dart';
import '../../services/schemes_service.dart';
import '../../services/profile_service.dart';
import 'scheme_details_screen.dart';
import 'my_applications_screen.dart';
import 'admin_panel_screen.dart'; // Add this import statement

class SchemesListingScreen extends StatefulWidget {
  const SchemesListingScreen({Key? key}) : super(key: key);

  @override
  State<SchemesListingScreen> createState() => _SchemesListingScreenState();
}

class _SchemesListingScreenState extends State<SchemesListingScreen> {
  final SchemesService _schemesService = SchemesService();
  final ProfileService _profileService = ProfileService();

  List<SchemeModel> _schemes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String? _selectedState = '';
  String? _selectedDistrict = '';
  TextEditingController _searchController = TextEditingController();

  bool _isAdmin = false; // Add this variable

  // Add these lists for dropdowns
  final List<String> _states = [
    'Maharashtra', 'Gujarat', 'Madhya Pradesh', 'Rajasthan', 'Karnataka', 'Uttar Pradesh', 'Punjab', 'Haryana', 'Bihar', 'West Bengal', 'Tamil Nadu', 'Andhra Pradesh', 'Telangana', 'Kerala', 'Odisha', 'Chhattisgarh', 'Jharkhand', 'Assam', 'Goa', 'Delhi', 'Others'
  ];
  final Map<String, List<String>> _districtMap = {
    'Maharashtra': ['Pune', 'Mumbai', 'Nagpur', 'Nashik', 'Aurangabad', 'Solapur', 'Kolhapur', 'Others'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Others'],
    // ... add more states and districts as needed
    'Others': ['Others']
  };

  List<String> get _districts => _districtMap[_selectedState] ?? ['Others'];

  @override
  void initState() {
    super.initState();
    _checkAdmin(); // Call this function
    _loadUserProfileAndSchemes();
  }

  Future<void> _checkAdmin() async {
    try {
      final isAdmin = await _schemesService.isUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (_) {
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadUserProfileAndSchemes() async {
    try {
      final profile = await _profileService.getUserProfile();
      setState(() {
        _selectedState = profile?.state ?? '';
        _selectedDistrict = profile?.city ?? '';
      });
      await _loadSchemes();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final schemes = await _schemesService.getSchemes(
        state: _selectedState ?? '',
        district: _selectedDistrict ?? '',
        searchQuery: _searchController.text,
      );
      setState(() {
        _schemes = schemes;
        _isLoading = false;
      });
    } catch (e, stack) {
      setState(() {
        _errorMessage = 'Failed to load schemes: $e';
        _isLoading = false;
      });
      // Print error and stack trace to the console for debugging
      print('Error in _loadSchemes:');
      print(e);
      print(stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Government Schemes'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPanelScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.assignment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApplicationsScreen(),
                ),
              );
            },
            tooltip: 'My Applications',
          ),
        ],
      ),
      // DO NOT wrap this Column in a SingleChildScrollView if you use Expanded below!
      // If you want the whole page to be scrollable, use SingleChildScrollView + Column, but REMOVE Expanded from children.
      body: Column(
        children: [
          // Search bar and filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search schemes or departments...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadSchemes();
                  },
                ),
              ),
              onSubmitted: (_) => _loadSchemes(),
            ),
          ),
          // State and district dropdowns + Filter button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // State Dropdown (first line)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: _states.contains(_selectedState) ? _selectedState : null,
                  items: _states.map((state) => DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value;
                      _selectedDistrict = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // District Dropdown (second line)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: _districts.contains(_selectedDistrict) ? _selectedDistrict : null,
                  items: _districts.map((district) => DropdownMenuItem(
                    value: district,
                    child: Text(district),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter Button (third line)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadSchemes,
                    child: const Text('Filter'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          // Only the list is scrollable, not the entire page
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _schemes.isEmpty
                        ? Center(child: Text('No schemes found.'))
                        : ListView.builder(
                            itemCount: _schemes.length,
                            itemBuilder: (context, index) {
                              final scheme = (_schemes.isNotEmpty &&
                                      index < _schemes.length &&
                                      _schemes[index] != null)
                                  ? _schemes[index]
                                  : null;
                              if (scheme == null) {
                                return SizedBox.shrink();
                              }
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                elevation: 2,
                                child: ListTile(
                                  isThreeLine: true,
                                  title: Text(
                                    scheme.schemeName ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    scheme.departmentName ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: SizedBox(
                                    width: 120, // Set a reasonable width for the button
                                    child: ElevatedButton(
                                      child: Text('View Details'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SchemeDetailsScreen(
                                                    schemeId: scheme.id ?? ''),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
