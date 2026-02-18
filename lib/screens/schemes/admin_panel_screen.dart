import 'package:flutter/material.dart';
import '../../models/scheme_model.dart';
import '../../models/application_model.dart';
import '../../services/schemes_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final SchemesService _schemesService = SchemesService();
  int _tabIndex = 0;
  bool _isAdmin = false;
  bool _loading = true;
  String _error = '';

  // Scheme Manager
  List<SchemeModel> _schemes = [];
  // Application Manager
  List<ApplicationModel> _applications = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      final isAdmin = await _schemesService.isUserAdmin();
      if (!isAdmin) {
        setState(() {
          _isAdmin = false;
          _loading = false;
          _error = 'You are not authorized to access the admin panel.';
        });
        return;
      }
      setState(() { _isAdmin = true; });
      await _loadSchemes();
      await _loadApplications();
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
    setState(() { _loading = false; });
  }

  Future<void> _loadSchemes() async {
    try {
      final schemes = await _schemesService.getSchemes();
      setState(() { _schemes = schemes; });
    } catch (e) {
      setState(() { _error = 'Failed to load schemes: $e'; });
    }
  }

  Future<void> _loadApplications() async {
    try {
      final apps = await _schemesService.getAllApplications();
      setState(() { _applications = apps; });
    } catch (e) {
      setState(() { _error = 'Failed to load applications: $e'; });
    }
  }

  void _showSchemeDialog({SchemeModel? scheme}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: scheme?.schemeName ?? '');
    final deptController = TextEditingController(text: scheme?.departmentName ?? '');
    final overviewController = TextEditingController(text: scheme?.overview ?? '');
    final benefitsController = TextEditingController(text: scheme?.benefits ?? '');
    final eligibilityController = TextEditingController(text: scheme?.eligibility ?? '');
    final docsController = TextEditingController(text: scheme?.requiredDocuments ?? '');
    final viewLinkController = TextEditingController(text: scheme?.viewBenefitsLink ?? '');
    final mahadbtLinkController = TextEditingController(text: scheme?.mahadbtApplyLink ?? '');
    final stateController = TextEditingController(text: scheme?.applicableState ?? '');
    final districtController = TextEditingController(text: scheme?.applicableDistrict ?? '');
    final categoryController = TextEditingController(text: scheme?.category ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(scheme == null ? 'Add Scheme' : 'Edit Scheme'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameController, decoration: InputDecoration(labelText: 'Scheme Name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                TextFormField(controller: deptController, decoration: InputDecoration(labelText: 'Department'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                TextFormField(controller: overviewController, decoration: InputDecoration(labelText: 'Overview'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                TextFormField(controller: benefitsController, decoration: InputDecoration(labelText: 'Benefits'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                TextFormField(controller: eligibilityController, decoration: InputDecoration(labelText: 'Eligibility'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                TextFormField(controller: docsController, decoration: InputDecoration(labelText: 'Required Documents (comma separated)'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                TextFormField(controller: viewLinkController, decoration: InputDecoration(labelText: 'Benefits Link')),                
                TextFormField(controller: mahadbtLinkController, decoration: InputDecoration(labelText: 'MahaDBT Link')),
                TextFormField(controller: stateController, decoration: InputDecoration(labelText: 'Applicable State')),
                TextFormField(controller: districtController, decoration: InputDecoration(labelText: 'Applicable District')),
                TextFormField(controller: categoryController, decoration: InputDecoration(labelText: 'Category')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            child: Text(scheme == null ? 'Add' : 'Update'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final newScheme = SchemeModel(
                id: scheme?.id ?? '',
                schemeName: nameController.text,
                departmentName: deptController.text,
                overview: overviewController.text,
                benefits: benefitsController.text,
                eligibility: eligibilityController.text,
                requiredDocuments: docsController.text,
                viewBenefitsLink: viewLinkController.text,
                mahadbtApplyLink: mahadbtLinkController.text,
                applicableState: stateController.text,
                applicableDistrict: districtController.text,
                category: categoryController.text,
                createdAt: scheme?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              try {
                if (scheme == null) {
                  await _schemesService.createScheme(newScheme);
                } else {
                  await _schemesService.updateScheme(newScheme);
                }
                await _loadSchemes();
              } catch (e) {
                setState(() { _error = 'Failed to save scheme: $e'; });
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteSchemeDialog(SchemeModel scheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Scheme'),
        content: Text('Are you sure you want to delete this scheme?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            child: Text('Delete'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _schemesService.deleteScheme(scheme.id);
                await _loadSchemes();
              } catch (e) {
                setState(() { _error = 'Failed to delete scheme: $e'; });
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUpdateAppStatusDialog(ApplicationModel app) {
    final statusOptions = ['Pending', 'Approved', 'Rejected'];
    String? selectedStatus = app.status;
    final remarksController = TextEditingController(text: app.remarks ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Application Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => selectedStatus = v,
              decoration: InputDecoration(labelText: 'Status'),
            ),
            TextFormField(controller: remarksController, decoration: InputDecoration(labelText: 'Remarks')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            child: Text('Update'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _schemesService.updateApplicationStatus(app.id, selectedStatus ?? 'Pending', remarksController.text);
                await _loadApplications();
              } catch (e) {
                setState(() { _error = 'Failed to update status: $e'; });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: Text('Admin Panel')), body: Center(child: CircularProgressIndicator()));
    if (!_isAdmin) return Scaffold(appBar: AppBar(title: Text('Admin Panel')), body: Center(child: Text(_error)));
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Column(
        children: [
          TabBar(
            onTap: (i) => setState(() => _tabIndex = i),
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: 'Scheme Manager'),
              Tab(text: 'Application Manager'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                // Scheme Manager
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Scheme'),
                          onPressed: () => _showSchemeDialog(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _schemes.length,
                        itemBuilder: (context, i) {
                          final scheme = _schemes[i];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(scheme.schemeName),
                              subtitle: Text(scheme.departmentName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: Icon(Icons.edit), onPressed: () => _showSchemeDialog(scheme: scheme)),
                                  IconButton(icon: Icon(Icons.delete), onPressed: () => _showDeleteSchemeDialog(scheme)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Application Manager
                ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (context, i) {
                    final app = _applications[i];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(app.schemeName ?? 'Scheme'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Applicant: ${app.name}'),
                            Text('Status: ${app.status}'),
                            if (app.remarks != null && app.remarks!.isNotEmpty) Text('Remarks: ${app.remarks!}'),
                            Text('Submitted: ${app.submittedAt.toLocal().toString().split(".")[0]}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showUpdateAppStatusDialog(app),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
