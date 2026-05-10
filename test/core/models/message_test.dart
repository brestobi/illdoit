import 'package:flutter_test/flutter_test.dart';
import 'package:ill_do_it/core/models/message.dart';

void main() {
  group('Message Model Tests', () {
    test('should create a Message instance from JSON', () {
      final json = {
        'id': '1',
        'sender_id': 'sender_123',
        'receiver_id': 'receiver_456',
        'content': 'Hello world',
        'image_url': 'https://example.com/image.jpg',
        'is_read': false,
        'created_at': '2026-05-05T12:00:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.id, '1');
      expect(message.senderId, 'sender_123');
      expect(message.receiverId, 'receiver_456');
      expect(message.content, 'Hello world');
      expect(message.imageUrl, 'https://example.com/image.jpg');
      expect(message.isRead, false);
      expect(message.createdAt, DateTime.parse('2026-05-05T12:00:00Z'));
    });

    test('should convert Message instance to JSON', () {
      final message = Message(
        id: '2',
        senderId: 's1',
        receiverId: 'r1',
        content: 'Test content',
        createdAt: DateTime.parse('2026-05-05T12:00:00Z'),
      );

      final json = message.toJson();

      expect(json['id'], '2');
      expect(json['sender_id'], 's1');
      expect(json['receiver_id'], 'r1');
      expect(json['content'], 'Test content');
      expect(json['is_read'], false);
    });
  });
}
