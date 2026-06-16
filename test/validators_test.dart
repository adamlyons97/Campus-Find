// Unit tests for the shared form validators.
//
// These cover Feature 1 (Authentication Hub — automatic field validation).
// They are intentionally pure-Dart: they do not touch Firebase, so they run
// fast with a plain `flutter test` and never need a configured backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:campusfind/features/auth/widgets/auth_validator_field.dart';

void main() {
  group('Validators.requiredField', () {
    test('returns an error for null / empty / whitespace', () {
      expect(Validators.requiredField(null), isNotNull);
      expect(Validators.requiredField(''), isNotNull);
      expect(Validators.requiredField('   '), isNotNull);
    });

    test('passes for non-empty input', () {
      expect(Validators.requiredField('Blue wallet'), isNull);
    });

    test('uses the supplied field name in the message', () {
      expect(Validators.requiredField('', field: 'Title'), contains('Title'));
    });
  });

  group('Validators.email', () {
    test('rejects empty and malformed addresses', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@iium.edu.my'), isNotNull);
    });

    test('accepts well-formed addresses', () {
      expect(Validators.email('ammar@live.iium.edu.my'), isNull);
      expect(Validators.email('staff.member@iium.edu.my'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty or short passwords', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
    });

    test('accepts passwords of at least 6 characters', () {
      expect(Validators.password('secret123'), isNull);
    });
  });
}
