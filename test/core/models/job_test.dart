import 'package:flutter_test/flutter_test.dart';
import 'package:ill_do_it/core/models/job.dart';

void main() {
  group('Job Model', () {
    test('isExpired returns true for past deadline', () {
      final job = Job(
        id: '1',
        clientId: 'c1',
        title: 'Test Job',
        description: 'Description',
        category: 'Category',
        budget: 100,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(job.isExpired, isTrue);
    });

    test('isUrgent returns true for < 2 days', () {
      final job = Job(
        id: '2',
        clientId: 'c2',
        title: 'Urgent Job',
        description: 'Description',
        category: 'Category',
        budget: 200,
        deadline: DateTime.now().add(const Duration(hours: 24)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(job.isUrgent, isTrue);
    });
  });
}
