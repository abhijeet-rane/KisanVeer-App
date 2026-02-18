import 'package:flutter/material.dart';
import '../../models/application_model.dart';
import '../../services/schemes_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({Key? key}) : super(key: key);

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final SchemesService _schemesService = SchemesService();
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final apps = await _schemesService.getUserApplications();
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load applications: $e';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Applications')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _applications.isEmpty
                  ? Center(child: Text('No applications found.'))
                  : ListView.builder(
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final app = _applications[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            title: Text(app.schemeName ?? 'Scheme'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  app.status,
                                  style: TextStyle(color: _statusColor(app.status)),
                                ),
                                SizedBox(height: 4),
                                Text('Submitted: ${app.submittedAt.toLocal().toString().split(".")[0]}'),
                                if (app.remarks != null && app.remarks!.isNotEmpty)
                                  Text('Remarks: ${app.remarks!}', style: TextStyle(color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
