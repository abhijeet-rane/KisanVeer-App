import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/models/scheme_model.dart';

void main() {
  group('SchemeModel.fromMap', () {
    test('applies empty-string defaults when fields are missing', () {
      final s = SchemeModel.fromMap(<String, dynamic>{});
      expect(s.id, '');
      expect(s.schemeName, '');
      expect(s.benefits, '');
      expect(s.applicableState, '');
      expect(s.applicableDistrict, '');
      expect(s.category, '');
      expect(s.viewBenefitsLink, isNull);
      expect(s.mahadbtApplyLink, isNull);
    });

    test('parses all fields including optional links', () {
      final s = SchemeModel.fromMap({
        'id': 'sc1',
        'scheme_name': 'PM-KISAN',
        'department_name': 'Agriculture',
        'overview': 'Income support',
        'benefits': '₹6000/yr',
        'eligibility': 'Land-holding farmers',
        'required_documents': 'Aadhaar, Bank details',
        'view_benefits_link': 'https://example.com/benefits',
        'mahadbt_apply_link': 'https://example.com/apply',
        'applicable_state': 'Maharashtra',
        'applicable_district': 'Pune',
        'category': 'Income',
        'created_at': '2026-04-21T10:00:00.000Z',
        'updated_at': '2026-04-21T11:00:00.000Z',
      });
      expect(s.schemeName, 'PM-KISAN');
      expect(s.viewBenefitsLink, 'https://example.com/benefits');
      expect(s.mahadbtApplyLink, 'https://example.com/apply');
      expect(s.applicableState, 'Maharashtra');
      expect(s.applicableDistrict, 'Pune');
      expect(s.category, 'Income');
    });
  });

  group('SchemeModel.fromJson', () {
    test('accepts space-separated ISO timestamps from Postgres', () {
      final s = SchemeModel.fromJson({
        'id': 'sc1',
        'scheme_name': 'X',
        'department_name': 'Y',
        'overview': '',
        'benefits': '',
        'eligibility': '',
        'required_documents': '',
        'created_at': '2026-04-21 10:00:00',
        'updated_at': '2026-04-21 11:00:00',
      });
      expect(s.createdAt.hour, 10);
      expect(s.updatedAt.hour, 11);
    });

    test('falls back updatedAt to createdAt when missing', () {
      final s = SchemeModel.fromJson({
        'id': 'sc1',
        'scheme_name': 'X',
        'department_name': 'Y',
        'overview': '',
        'benefits': '',
        'eligibility': '',
        'required_documents': '',
        'created_at': '2026-04-21T10:00:00.000Z',
      });
      expect(s.updatedAt, s.createdAt);
    });
  });

  group('SchemeModel.toMap / toJson', () {
    test('toJson emits a decodable JSON string', () {
      final s = SchemeModel(
        id: 'sc1',
        schemeName: 'PM-KISAN',
        departmentName: 'Agriculture',
        overview: '',
        benefits: '',
        eligibility: '',
        requiredDocuments: '',
        createdAt: DateTime.utc(2026, 4, 21, 10),
        updatedAt: DateTime.utc(2026, 4, 21, 11),
      );
      final encoded = s.toJson();
      final decoded = json.decode(encoded) as Map<String, dynamic>;
      expect(decoded['id'], 'sc1');
      expect(decoded['scheme_name'], 'PM-KISAN');
    });
  });

  group('SchemeModel.getRequiredDocumentsList', () {
    test('splits on newlines', () {
      final s = _scheme(
        requiredDocuments: 'Aadhaar card\nBank passbook\nLand record',
      );
      expect(s.getRequiredDocumentsList(), [
        'Aadhaar card',
        'Bank passbook',
        'Land record',
      ]);
    });

    test('splits on commas and trims whitespace', () {
      final s = _scheme(
        requiredDocuments: 'Aadhaar card,  Bank passbook , Land record ',
      );
      expect(s.getRequiredDocumentsList(), [
        'Aadhaar card',
        'Bank passbook',
        'Land record',
      ]);
    });

    test('handles literal "\\n" escape sequences from DB rows', () {
      final s = _scheme(requiredDocuments: 'Aadhaar\\nBank\\nLand');
      expect(s.getRequiredDocumentsList(), ['Aadhaar', 'Bank', 'Land']);
    });

    test('returns an empty list for empty/blank input', () {
      expect(
        _scheme(requiredDocuments: '').getRequiredDocumentsList(),
        isEmpty,
      );
      expect(
        _scheme(requiredDocuments: ' , , \n ').getRequiredDocumentsList(),
        isEmpty,
      );
    });
  });
}

SchemeModel _scheme({String requiredDocuments = ''}) => SchemeModel(
  id: 'sc1',
  schemeName: 'X',
  departmentName: 'Y',
  overview: '',
  benefits: '',
  eligibility: '',
  requiredDocuments: requiredDocuments,
  createdAt: DateTime.utc(2026, 4, 21),
  updatedAt: DateTime.utc(2026, 4, 21),
);
