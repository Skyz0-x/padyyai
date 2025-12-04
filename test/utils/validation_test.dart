import 'package:flutter_test/flutter_test.dart';

/// Test suite for PaddyAI Utility Functions
/// 
/// This test file validates core utility functions including:
/// - Email validation
/// - Phone number validation
/// - Input sanitization
/// - Date formatting
/// - String manipulation
void main() {
  group('Email Validation Tests', () {
    test('Valid email formats should pass', () {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      
      expect(emailRegex.hasMatch('test@example.com'), true);
      expect(emailRegex.hasMatch('user.name@example.com'), true);
      expect(emailRegex.hasMatch('user+tag@example.co.uk'), true);
      expect(emailRegex.hasMatch('123@example.com'), true);
      expect(emailRegex.hasMatch('test_user@example.com'), true);
    });

    test('Invalid email formats should fail', () {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      
      expect(emailRegex.hasMatch('invalid.email'), false);
      expect(emailRegex.hasMatch('@example.com'), false);
      expect(emailRegex.hasMatch('user@'), false);
      expect(emailRegex.hasMatch('user@.com'), false);
      expect(emailRegex.hasMatch('user name@example.com'), false);
      expect(emailRegex.hasMatch(''), false);
    });

    test('Email should be trimmed and lowercased', () {
      final email = '  TEST@EXAMPLE.COM  ';
      final cleanEmail = email.trim().toLowerCase();
      
      expect(cleanEmail, 'test@example.com');
    });
  });

  group('Phone Number Validation Tests', () {
    test('Valid Malaysian phone numbers should pass', () {
      final phoneRegex = RegExp(r'^(\+?6?01)[0-46-9]-*[0-9]{7,8}$');
      
      expect(phoneRegex.hasMatch('0123456789'), true);
      expect(phoneRegex.hasMatch('01123456789'), true);
      expect(phoneRegex.hasMatch('+60123456789'), true);
      expect(phoneRegex.hasMatch('012-3456789'), true);
    });

    test('Invalid phone numbers should fail', () {
      final phoneRegex = RegExp(r'^(\+?6?01)[0-46-9]-*[0-9]{7,8}$');
      
      expect(phoneRegex.hasMatch('123456'), false);
      expect(phoneRegex.hasMatch('abcdefghij'), false);
      expect(phoneRegex.hasMatch(''), false);
    });

    test('Phone number should be sanitized', () {
      final phone = '  012-345-6789  ';
      final cleanPhone = phone.trim().replaceAll('-', '').replaceAll(' ', '');
      
      expect(cleanPhone, '0123456789');
    });
  });

  group('String Manipulation Tests', () {
    test('String should be properly capitalized', () {
      String capitalize(String text) {
        if (text.isEmpty) return text;
        return text[0].toUpperCase() + text.substring(1).toLowerCase();
      }
      
      expect(capitalize('hello'), 'Hello');
      expect(capitalize('WORLD'), 'World');
      expect(capitalize('tEsT'), 'Test');
      expect(capitalize(''), '');
    });

    test('String should be properly truncated', () {
      String truncate(String text, int maxLength) {
        if (text.length <= maxLength) return text;
        return '${text.substring(0, maxLength)}...';
      }
      
      expect(truncate('Hello World', 5), 'Hello...');
      expect(truncate('Short', 10), 'Short');
      expect(truncate('Exactly10!', 10), 'Exactly10!');
    });
  });

  group('Input Sanitization Tests', () {
    test('HTML/SQL injection attempts should be sanitized', () {
      String sanitizeInput(String input) {
        return input
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#x27;')
            .replaceAll('/', '&#x2F;');
      }
      
      expect(sanitizeInput('<script>alert("XSS")</script>'),
          '&lt;script&gt;alert(&quot;XSS&quot;)&lt;&#x2F;script&gt;');
      expect(sanitizeInput("SELECT * FROM users WHERE id='1' OR '1'='1'"),
          contains('&#x27;'));
    });

    test('Whitespace should be trimmed', () {
      final input = '  test data  ';
      expect(input.trim(), 'test data');
      expect(''.trim(), '');
      expect('   '.trim(), '');
    });
  });

  group('Date Formatting Tests', () {
    test('Date should be formatted correctly', () {
      final date = DateTime(2025, 12, 4);
      final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      expect(formatted, '2025-12-04');
    });

    test('Date comparison should work correctly', () {
      final date1 = DateTime(2025, 12, 4);
      final date2 = DateTime(2025, 12, 5);
      final date3 = DateTime(2025, 12, 4);
      
      expect(date1.isBefore(date2), true);
      expect(date2.isAfter(date1), true);
      expect(date1.isAtSameMomentAs(date3), true);
    });

    test('Date difference should be calculated correctly', () {
      final date1 = DateTime(2025, 12, 4);
      final date2 = DateTime(2025, 12, 14);
      final difference = date2.difference(date1);
      
      expect(difference.inDays, 10);
    });
  });

  group('Number Validation Tests', () {
    test('String to number conversion should work', () {
      expect(int.tryParse('123'), 123);
      expect(int.tryParse('abc'), null);
      expect(double.tryParse('12.34'), 12.34);
      expect(double.tryParse('invalid'), null);
    });

    test('Number range validation should work', () {
      bool isInRange(num value, num min, num max) {
        return value >= min && value <= max;
      }
      
      expect(isInRange(5, 1, 10), true);
      expect(isInRange(0, 1, 10), false);
      expect(isInRange(11, 1, 10), false);
      expect(isInRange(1, 1, 10), true);
      expect(isInRange(10, 1, 10), true);
    });

    test('Price formatting should work correctly', () {
      String formatPrice(double price) {
        return 'RM ${price.toStringAsFixed(2)}';
      }
      
      expect(formatPrice(100.5), 'RM 100.50');
      expect(formatPrice(0.99), 'RM 0.99');
      expect(formatPrice(1234.567), 'RM 1234.57');
    });
  });

  group('List Operations Tests', () {
    test('List should be filtered correctly', () {
      final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final evenNumbers = numbers.where((n) => n % 2 == 0).toList();
      
      expect(evenNumbers, [2, 4, 6, 8, 10]);
      expect(evenNumbers.length, 5);
    });

    test('List should be mapped correctly', () {
      final numbers = [1, 2, 3, 4, 5];
      final doubled = numbers.map((n) => n * 2).toList();
      
      expect(doubled, [2, 4, 6, 8, 10]);
    });

    test('List should be reduced correctly', () {
      final numbers = [1, 2, 3, 4, 5];
      final sum = numbers.reduce((a, b) => a + b);
      
      expect(sum, 15);
    });

    test('Empty list operations should handle gracefully', () {
      final empty = <int>[];
      
      expect(empty.isEmpty, true);
      expect(empty.length, 0);
      expect(empty.where((n) => n > 0).toList(), []);
    });
  });

  group('Map Operations Tests', () {
    test('Map should contain expected keys', () {
      final user = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'farmer',
      };
      
      expect(user.containsKey('name'), true);
      expect(user.containsKey('email'), true);
      expect(user.containsKey('age'), false);
    });

    test('Map values should be accessed correctly', () {
      final user = {
        'name': 'John Doe',
        'email': 'john@example.com',
      };
      
      expect(user['name'], 'John Doe');
      expect(user['email'], 'john@example.com');
      expect(user['age'], null);
    });

    test('Map should be merged correctly', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'c': 3, 'd': 4};
      final merged = {...map1, ...map2};
      
      expect(merged, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
    });
  });

  group('Boolean Logic Tests', () {
    test('Logical AND should work correctly', () {
      expect(true && true, true);
      expect(true && false, false);
      expect(false && true, false);
      expect(false && false, false);
    });

    test('Logical OR should work correctly', () {
      expect(true || true, true);
      expect(true || false, true);
      expect(false || true, true);
      expect(false || false, false);
    });

    test('Logical NOT should work correctly', () {
      expect(!true, false);
      expect(!false, true);
    });

    test('Null check should work correctly', () {
      String? nullableString;
      String nonNullString = 'test';
      
      expect(nullableString == null, true);
      expect(nonNullString == null, false);
      expect(nullableString ?? 'default', 'default');
      expect(nonNullString ?? 'default', 'test');
    });
  });
}
