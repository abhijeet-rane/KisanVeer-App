import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/scheme_model.dart';
import '../../services/schemes_service.dart';
import 'application_form_screen.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final String schemeId;
  const SchemeDetailsScreen({Key? key, required this.schemeId}) : super(key: key);

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> {
  final SchemesService _schemesService = SchemesService();
  SchemeModel? _scheme;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadScheme();
  }

  Future<void> _loadScheme() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final scheme = await _schemesService.getSchemeById(widget.schemeId);
      setState(() {
        _scheme = scheme;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load scheme details: $e';
        _isLoading = false;
      });
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _scheme == null
                  ? const Center(child: Text('Scheme not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card for scheme title and department
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            color: Colors.teal[50],
                            margin: const EdgeInsets.only(bottom: 18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.policy, color: Colors.teal, size: 28),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _scheme!.schemeName,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.account_balance, size: 20, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Department: ${_scheme!.departmentName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Overview
                          Text(
                            _scheme!.overview,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          const Divider(height: 32, thickness: 1.2),
                          // Benefits section
                          Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.orange, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Benefits',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _scheme!.benefits.trim().isNotEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _scheme!.benefits,
                                    style: const TextStyle(fontSize: 15, height: 1.5),
                                  ),
                                )
                              : const Text('For Benefits Provided Please Refer Below Document.'),
                          const SizedBox(height: 18),
                          // Eligibility section
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: Colors.blue, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Eligibility',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _scheme!.eligibility.replaceAll(r'\n', '\n').replaceAll('\\n', '\n').replaceAll(RegExp(r'\n+'), '\n').replaceAll('\\', '\\'),
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Required Documents section
                          Row(
                            children: [
                              const Icon(Icons.description, color: Colors.green, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Required Documents',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ..._scheme!.getRequiredDocumentsList().map((doc) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_box_outlined, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(doc, style: const TextStyle(fontSize: 15))),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 18),
                          if (_scheme!.viewBenefitsLink != null && _scheme!.viewBenefitsLink!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextButton.icon(
                                icon: const Icon(Icons.open_in_new, color: Colors.teal),
                                label: const Text('View More Benefits'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _launchURL(_scheme!.viewBenefitsLink!),
                              ),
                            ),
                          if (_scheme!.mahadbtApplyLink != null && _scheme!.mahadbtApplyLink!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextButton.icon(
                                icon: const Icon(Icons.open_in_new, color: Colors.blue),
                                label: const Text('Apply on MahaDBT'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _launchURL(_scheme!.mahadbtApplyLink!),
                              ),
                            ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 3,
                                shadowColor: Colors.greenAccent,
                              ),
                              child: const Text('Apply via App'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ApplicationFormScreen(scheme: _scheme!),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
