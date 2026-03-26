import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<void> ilkKurulumMasalariOlustur() async {
    WriteBatch batch = _db.batch();

    for (int i = 1; i <= 50; i++) {
      String docId = i.toString().padLeft(2, '0');

      DocumentReference docRef = _db.collection('masalar').doc(docId);

      batch.set(docRef, {
        'masaNo': i,
        'durum': 'bos',
        'kisiSayisi': 0,
        'aktif': true,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      print("Başarılı: 40 masa sisteme eklendi.");
    } catch (e) {
      print("Hata oluştu: $e");
    }
  }
}