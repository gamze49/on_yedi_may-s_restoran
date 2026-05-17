import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (eminMi == true) {
      try {
        if (context.mounted) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Güle güle $personelAdi, çıkış yapılıyor..."),
              backgroundColor: Colors.brown,
              duration: const Duration(milliseconds: 800),
            ),
          );
        }


        await Future.delayed(const Duration(milliseconds: 500));


        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const GirisEkrani()),
                (route) => false,
          );
        }
      } catch (e) {
        debugPrint("Çıkış hatası: $e");
      }
    }
  }
}