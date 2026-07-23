import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicine_reminder_app/models/medicine.dart';
import 'package:medicine_reminder_app/services/database_service.dart';

class FirestoreDatabaseService implements DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Medicine>> watchMedicines(String userId) {
    return _firestore
        .collection('medicines')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Medicine.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<List<Medicine>> getMedicines(String userId) async {
    final snapshot = await _firestore
        .collection('medicines')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => Medicine.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Medicine> addMedicine(Medicine medicine) async {
    final docRef = await _firestore
        .collection('medicines')
        .add(medicine.toJson());
    return medicine.copyWith(id: docRef.id);
  }

  @override
  Future<void> updateMedicine(Medicine medicine) async {
    await _firestore
        .collection('medicines')
        .doc(medicine.id)
        .update(medicine.toJson());
  }

  @override
  Future<void> deleteMedicine(String id) async {
    await _firestore.collection('medicines').doc(id).delete();
  }
}
