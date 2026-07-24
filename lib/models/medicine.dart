/// Represents a single medicine reminder entry.
///
/// New fields added (all backward-compatible with defaults):
///   - [repeatType]: 'One Time' | 'Daily' | 'Weekly' | 'Monthly' (default 'One Time')
///
/// Existing status values: 'Pending', 'Taken', 'Missed'
/// New status value added:  'Skipped'
class Medicine {
  final String id;
  final String userId;
  final String medicineName;
  final String dosage;
  final String date; // yyyy-MM-dd
  final String time; // hh:mm a (e.g. 08:00 AM)
  final String notes;
  final String status; // Pending, Taken, Missed, Skipped
  final int notificationId;
  final String repeatType; // One Time, Daily, Weekly, Monthly

  Medicine({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.dosage,
    required this.date,
    required this.time,
    required this.notes,
    required this.status,
    required this.notificationId,
    this.repeatType = 'One Time', // default keeps existing records compatible
  });

  DateTime get scheduledDateTime {
    try {
      final dateParts = date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final timeClean = time.trim();
      final amPm = timeClean.substring(timeClean.length - 2).toUpperCase();
      final timeParts =
          timeClean.substring(0, timeClean.length - 2).trim().split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (amPm == 'PM' && hour < 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  bool get isOverdue {
    if (status != 'Pending') return false;
    final now = DateTime.now();
    return now.isAfter(scheduledDateTime);
  }

  Medicine copyWith({
    String? id,
    String? userId,
    String? medicineName,
    String? dosage,
    String? date,
    String? time,
    String? notes,
    String? status,
    int? notificationId,
    String? repeatType,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      date: date ?? this.date,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      notificationId: notificationId ?? this.notificationId,
      repeatType: repeatType ?? this.repeatType,
    );
  }

  factory Medicine.fromJson(Map<String, dynamic> json, String id) {
    return Medicine(
      id: id,
      userId: json['userId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Pending',
      notificationId: json['notificationId'] ?? 0,
      repeatType: json['repeatType'] ?? 'One Time', // backward-compatible default
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'medicineName': medicineName,
      'dosage': dosage,
      'date': date,
      'time': time,
      'notes': notes,
      'status': status,
      'notificationId': notificationId,
      'repeatType': repeatType, // new field written on all saves
    };
  }
}
