import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../giris_ekrani.dart';

class AuthServis {
  // --- Çıkış Yapma ---
  static Future<void> isimliCikisYap(BuildContext context, String personelAdi) async {
    bool? eminMi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: Text("Sayın $personelAdi, hesabınızdan çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (eminMi == true) {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const GirisEkrani()),
              (route) => false,
        );
      }
    }
  }

  // --- YENİ MİMARİ: SADECE FIRESTORE KULLANARAK ŞİFRE DOĞRULAMA ---
  static Future<void> _firestoreSifreDogrula(String docId, String girilenSifre) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("kullanici")
        .doc(docId)
        .get();

    if (!userDoc.exists) {
      throw Exception("Kullanıcı veri tabanında bulunamadı.");
    }

    String veriTabanindakiSifre = userDoc['sifre'] ?? "";
    if (girilenSifre != veriTabanindakiSifre) {
      throw Exception("Mevcut şifreniz hatalı! Değişiklik onaylanmadı.");
    }
  }

  // --- SADECE FIRESTORE E-POSTA GÜNCELLEME ---
  static Future<void> sadeceEpostaGuncelle({
    required String userUid, // Profil ekranından gelen kullanıcının Firestore Doküman ID'si
    required String mevcutSifre,
    required String yeniEmail,
  }) async {
    // 1. Önce Firestore'dan mevcut şifreyi kontrol et
    await _firestoreSifreDogrula(userUid, mevcutSifre);

    // 2. Şifre doğruysa e-postayı doğrudan Firestore üzerinde güncelle
    await FirebaseFirestore.instance
        .collection("kullanici")
        .doc(userUid)
        .update({"email": yeniEmail});
  }

  // --- SADECE FIRESTORE ŞİFRE GÜNCELLEME ---
  static Future<void> sadeceSifreGuncelle({
    required String userUid, // Profil ekranından gelen kullanıcının Firestore Doküman ID'si
    required String mevcutSifre,
    required String yeniSifre,
  }) async {
    // 1. Önce Firestore'dan mevcut şifreyi kontrol et
    await _firestoreSifreDogrula(userUid, mevcutSifre);

    // 2. Şifre doğruysa şifreyi doğrudan Firestore üzerinde güncelle
    await FirebaseFirestore.instance
        .collection("kullanici")
        .doc(userUid)
        .update({"sifre": yeniSifre});
  }
}