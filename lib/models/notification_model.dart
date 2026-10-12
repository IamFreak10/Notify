import 'dart:convert';

class NotificationModel {
  final String id;
  final String? topic;
  final String event;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final int timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    this.topic,
    required this.event,
    required this.title,
    required this.body,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      topic: json['topic'] as String?,
      event: json['event'] ?? 'INFO',
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      timestamp: json['timestamp'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'event': event,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      topic: topic,
      event: event,
      title: title,
      body: body,
      data: data,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
