import 'package:cloud_firestore/cloud_firestore.dart';

class MenuService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> menuOlustur() async {

    WriteBatch batch = _db.batch();

    List menuListesi = [

      {
        "ad": "Mantar Çorbası",
        "fiyat": 60,
        "kategori": "Çorbalar",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/mantar_corbasi.jpg?alt=media&token=34f3dc55-d061-4f90-b644-72abdf33acb8",
        "aktif": true,
      },

      {
        "ad": "Ezogelin Çorbası",
        "fiyat": 65,
        "kategori": "Çorbalar",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/ezogelin_corbasi.jpg?alt=media&token=e0144e23-ebea-4a21-95f0-152aa497d1aa",
        "aktif": true,
      },

      {
        "ad": "Tavuk Çorbası",
        "fiyat": 70,
        "kategori": "Çorbalar",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/tavuk_corbasi.jpg?alt=media&token=0cc099db-3985-45c2-a546-003a97304ecb",
        "aktif": true,
      },


      {
        "ad": "Tantuni",
        "fiyat": 180,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/tantuni.jpg?alt=media&token=4d009451-98a8-4c01-aae9-36de1da19cd6",
        "aktif": true,
      },

      {
        "ad": "Pizza",
        "fiyat": 170,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/pizza.jpg?alt=media&token=66d55144-92f9-4956-bf59-c07f7ebd4346",
        "aktif": true,
      },

      {
        "ad": "Hamburger",
        "fiyat": 150,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/hamburger.jpg?alt=media&token=ccece7ce-ffdd-4be1-b9e2-3c37f23e960b",
        "aktif": true,
      },


      {
        "ad": "Turşu Suyu",
        "fiyat": 40,
        "kategori": "İçecek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/tursu_suyu.jpg?alt=media&token=6166732c-9b85-4fd5-9087-9e693a786f23",
        "aktif": true,
      },

      {
        "ad": "Meyve Suyu",
        "fiyat": 25,
        "kategori": "İçecek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/meyve_suyu.jpg?alt=media&token=c2886ab1-178a-471a-9d60-c87bd1eb41ad",
        "aktif": true,
      },

      {
        "ad": "Su",
        "fiyat": 10,
        "kategori": "İçecek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/su.jpg?alt=media&token=4be986bc-c40c-4786-b2de-5968c879b15b",
        "aktif": true,
      },


      {
        "ad": "Katmer",
        "fiyat": 120,
        "kategori": "Tatlı",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/katmer.jpg?alt=media&token=6360433b-7c9f-489a-bf1b-b32f822f746d",
        "aktif": true,
      },

      {
        "ad": "Kazandibi",
        "fiyat": 80,
        "kategori": "Tatlı",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/kazandibi.jpg?alt=media&token=a8816102-dec3-4a13-aa07-a3a2626bf552",
        "aktif": true,
      },

    ];


    for (var urun in menuListesi) {

      DocumentReference ref =
      _db.collection("menu").doc();

      batch.set(ref, urun);
    }

    await batch.commit();

    print("MENÜ EKLENDİ");
  }
}