import 'package:medicine_reminder_app/models/medicine.dart';

abstract class DatabaseService {
  Stream<List<Medicine>> watchMedicines(String userId);
  Future<List<Medicine>> getMedicines(String userId);
  Future<Medicine> addMedicine(Medicine medicine);
  Future<void> updateMedicine(Medicine medicine);
  Future<void> deleteMedicine(String id);
}
