import 'package:cloud_firestore/cloud_firestore.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> menuOlustur() async {
    WriteBatch batch = _db.batch();


    List menuListesi = [

      {
        "ad": "Tantuni",
        "fiyat": 180,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Ftantuni%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Adana Kebap",
        "fiyat": 220,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Fadanakebap.jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Etli Ekmek",
        "fiyat": 200,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Fetliekmek.jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Bıçak Arası",
        "fiyat": 250,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Fb%C4%B1%C3%A7akaras%C4%B1.jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Hamburger",
        "fiyat": 320,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Fhamburger%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Lahmacun",
        "fiyat": 160,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Flahmacun.jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Muş Köftesi",
        "fiyat": 260,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Fmuskofte.jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Pizza",
        "fiyat": 240,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Fpizza%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Yağ Somonu",
        "fiyat": 240,
        "kategori": "Ana Yemek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fana_yemek%2Fyagsomonu.jpg?alt=media",
        "aktif": true,
      },


      {
        "ad": "Mantar Çorbası",
        "fiyat": 60,
        "kategori": "Çorbalar",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fcorbalar%2Fmantar_corbasi%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Et Suyu Çorbası",
        "fiyat": 65,
        "kategori": "Çorbalar",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fcorbalar%2Fetsuyu%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Mercimek Çorbası",
        "fiyat": 55,
        "kategori": "Çorbalar",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fcorbalar%2Fmercimekcorbasi%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Tavuk Suyu Çorbası",
        "fiyat": 70,
        "kategori": "Çorbalar",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fcorbalar%2Ftavuk_corbasi%20(1).jpg?alt=media",
        "aktif": true,
      },


      {
        "ad": "Mevsim Salata",
        "fiyat": 50,
        "kategori": "Salata",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fsalatalar%2Fmevsim%20salalta.jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Çoban Salata",
        "fiyat": 55,
        "kategori": "Salata",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fsalatalar%2F%C3%A7oban%20salata.jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Gavurdağı Salatası",
        "fiyat": 80,
        "kategori": "Salata",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Fsalatalar%2Fgavurda%C4%9F%20salata.jpg?alt=media",
        "aktif": true,
      },


      {
        "ad": "Katmer",
        "fiyat": 120,
        "kategori": "Tatlı",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ftatlilar%2Fkatmer%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Sütlaç",
        "fiyat": 75,
        "kategori": "Tatlı",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ftatlilar%2Fs%C3%BCtlac%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Baklava",
        "fiyat": 150,
        "kategori": "Tatlı",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ftatlilar%2Fbaklava%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Künefe",
        "fiyat": 130,
        "kategori": "Tatlı",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ftatlilar%2Fkunefe%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Kazandibi",
        "fiyat": 70,
        "kategori": "Tatlı",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ftatlilar%2Fkazandibi%20(1).jpg?alt=media",
        "aktif": true,
      },


      {
        "ad": "Ayran",
        "fiyat": 20,
        "kategori": "İçecek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ficecekler%2Fayran%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Turşu Suyu",
        "fiyat": 25,
        "kategori": "İçecek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ficecekler%2Ftursu_suyu%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Su",
        "fiyat": 10,
        "kategori": "İçecek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ficecekler%2Fsu%20(1).jpg?alt=media",
        "aktif": true,
      },
      {
        "ad": "Şalgam Suyu",
        "fiyat": 25,
        "kategori": "İçecek",
        "resimUrl": "https://firebasestorage.googleapis.com/v0/b/restoranuygulamasi-f5c17.firebasestorage.app/o/menu_resimleri%2Ficecekler%2Fsalgam%20(1).jpg?alt=media",
        "aktif": true,
      },
    ];

    for (var urun in menuListesi) {
      DocumentReference ref = _db.collection("menu").doc();
      batch.set(ref, urun);
    }

    await batch.commit();
    print("YENİ GENİŞLETİLMİŞ MENÜ BAŞARIYLA EKLENDİ");
  }
}