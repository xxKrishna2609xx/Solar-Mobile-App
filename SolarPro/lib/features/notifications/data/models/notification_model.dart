class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'lead', 'job', 'kedl_file', 'kedl_demand', 'payment', 'ticket', 'system'
  final String? targetId;
  final String? targetRole; // Scoped to role
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.targetRole,
    this.isRead = false,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'system',
      targetId: json['target_id']?.toString(),
      targetRole: json['target_role']?.toString().toLowerCase(),
      isRead: json['is_read'] == true || json['read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      if (targetId != null) 'target_id': targetId,
      if (targetRole != null) 'target_role': targetRole,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? targetId,
    String? targetRole,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetRole: targetRole ?? this.targetRole,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
