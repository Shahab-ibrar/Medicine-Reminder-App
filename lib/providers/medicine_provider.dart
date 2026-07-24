import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:medicine_reminder_app/models/medicine.dart';
import 'package:medicine_reminder_app/services/notification_service.dart';
import 'package:medicine_reminder_app/services/service_locator.dart';

class MedicineProvider with ChangeNotifier {
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _userId;
  StreamSubscription<List<Medicine>>? _medicinesSubscription;
  Timer? _missedCheckTimer;
  final NotificationService _notificationService = NotificationService();

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;

  void updateUserId(String? newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;

    _medicinesSubscription?.cancel();
    _missedCheckTimer?.cancel();

    if (_userId != null && _userId!.isNotEmpty) {
      _isLoading = true;
      notifyListeners();

      _medicinesSubscription = locator.databaseService
          .watchMedicines(_userId!)
          .listen(
            (medsList) {
              _medicines = medsList;
              _isLoading = false;
              _checkAndAutoUpdateMissed();
              notifyListeners();
            },
            onError: (err) {
              debugPrint('MedicineProvider watch error: $err');
              _isLoading = false;
              notifyListeners();
            },
          );

      _missedCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _checkAndAutoUpdateMissed();
      });
    } else {
      _medicines = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndAutoUpdateMissed() async {
    bool updatedAny = false;
    for (var medicine in _medicines) {
      if (medicine.status == 'Pending' && medicine.isOverdue) {
        final updatedMed = medicine.copyWith(status: 'Missed');
        await locator.databaseService.updateMedicine(updatedMed);
        await _notificationService.cancelNotification(medicine.notificationId);
        updatedAny = true;
      }
    }
    if (updatedAny) {
      notifyListeners();
    }
  }

  // ─── Scheduling helper ───────────────────────────────────────────────────────

  /// Schedules (or re-schedules) the notification for [medicine].
  /// Uses repeating scheduling for Daily/Weekly/Monthly, one-time otherwise.
  Future<void> _scheduleNotificationForMedicine(Medicine medicine) async {
    await _notificationService.cancelNotification(medicine.notificationId);

    if (medicine.status != 'Pending') return;

    final scheduledTime = medicine.scheduledDateTime;
    final now = DateTime.now();

    // For one-time, only schedule if in the future
    if (medicine.repeatType == 'One Time' && scheduledTime.isBefore(now)) return;

    await _notificationService.scheduleRepeatingNotification(
      id: medicine.notificationId,
      title: 'Medication Reminder: ${medicine.medicineName}',
      body:
          'It\'s time to take your dosage: ${medicine.dosage}${medicine.notes.isNotEmpty ? ' (${medicine.notes})' : ''}',
      scheduledDateTime: scheduledTime,
      repeatType: medicine.repeatType,
      payload: medicine.id,
    );
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  Future<bool> addMedicine({
    required String name,
    required String dosage,
    required String date,
    required String time,
    required String notes,
    String repeatType = 'One Time', // new optional parameter
  }) async {
    if (_userId == null) return false;

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(1000000);

    final medicine = Medicine(
      id: '',
      userId: _userId!,
      medicineName: name,
      dosage: dosage,
      date: date,
      time: time,
      notes: notes,
      status: 'Pending',
      notificationId: notificationId,
      repeatType: repeatType,
    );

    try {
      final savedMed = await locator.databaseService.addMedicine(medicine);
      await _scheduleNotificationForMedicine(savedMed);
      return true;
    } catch (e) {
      debugPrint('Error adding medicine: $e');
      return false;
    }
  }

  Future<bool> updateMedicine(Medicine medicine) async {
    try {
      await locator.databaseService.updateMedicine(medicine);
      await _scheduleNotificationForMedicine(medicine);
      return true;
    } catch (e) {
      debugPrint('Error updating medicine: $e');
      return false;
    }
  }

  Future<bool> deleteMedicine(Medicine medicine) async {
    try {
      await locator.databaseService.deleteMedicine(medicine.id);
      await _notificationService.cancelNotification(medicine.notificationId);
      return true;
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      return false;
    }
  }

  Future<bool> markAsTaken(Medicine medicine) async {
    final updated = medicine.copyWith(status: 'Taken');
    return await updateMedicine(updated);
  }

  Future<bool> markAsMissed(Medicine medicine) async {
    final updated = medicine.copyWith(status: 'Missed');
    return await updateMedicine(updated);
  }

  /// Marks medicine as Skipped (new status for Feature 3).
  Future<bool> markAsSkipped(Medicine medicine) async {
    final updated = medicine.copyWith(status: 'Skipped');
    return await updateMedicine(updated);
  }

  Future<bool> markAsPending(Medicine medicine) async {
    final updated = medicine.copyWith(status: 'Pending');
    return await updateMedicine(updated);
  }

  @override
  void dispose() {
    _medicinesSubscription?.cancel();
    _missedCheckTimer?.cancel();
    super.dispose();
  }
}
