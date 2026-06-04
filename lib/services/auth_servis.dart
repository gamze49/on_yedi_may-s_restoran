import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../giris_ekrani.dart';

class AuthServis {

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


  static Future<void> sadeceEpostaGuncelle({
    required String userUid,
    required String mevcutSifre,
    required String yeniEmail,
  }) async {

    await _firestoreSifreDogrula(userUid, mevcutSifre);

    await FirebaseFirestore.instance
        .collection("kullanici")
        .doc(userUid)
        .update({"email": yeniEmail});
  }

  static Future<void> sadeceSifreGuncelle({
    required String userUid,
    required String mevcutSifre,
    required String yeniSifre,
  }) async {

    await _firestoreSifreDogrula(userUid, mevcutSifre);

    await FirebaseFirestore.instance
        .collection("kullanici")
        .doc(userUid)
        .update({"sifre": yeniSifre});
  }
}