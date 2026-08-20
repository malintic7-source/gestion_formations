class AuditLog {
  final String id;
  final String userNom;
  final String userRole;
  final String action;
  final String description;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userNom,
    required this.userRole,
    required this.action,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userNom': userNom,
      'userRole': userRole,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic value) {
      if (value is DateTime) return value;
      if (value != null && value.runtimeType.toString().contains('Timestamp')) {
        try {
          return (value as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return AuditLog(
      id: map['id'] ?? '',
      userNom: map['userNom'] ?? 'Système',
      userRole: map['userRole'] ?? 'Admin',
      action: map['action'] ?? 'ACTION',
      description: map['description'] ?? '',
      timestamp: parseTimestamp(map['timestamp']),
    );
  }
}
