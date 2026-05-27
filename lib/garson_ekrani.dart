import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'siparis_ekrani.dart';
import 'profil_ayarlari_ekrani.dart';

class GarsonEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid; // EKLENDİ
  const GarsonEkrani({
    super.key,
    required this.personelAdi,
    required this.userUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text(
          '508 RESTORAN MASALAR',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: Colors.white),
            tooltip: "Hesap Ayarları",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilAyarlariEkrani(
                    userUid: userUid, // DÜZELTME: uid geçiriliyor
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Çıkış Yap",
            onPressed: () => AuthServis.isimliCikisYap(context, personelAdi),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('masalar')
            .orderBy('masaNo')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Hata oluştu"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var masalar = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: masalar.length,
            itemBuilder: (context, index) {
              var masaVerisi =
              masalar[index].data() as Map<String, dynamic>;
              var masaId = masalar[index].id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SiparisEkrani(
                        masaId: masaId,
                        garsonAdi: personelAdi,
                      ),
                    ),
                  );
                },
                child: Card(
                  color: masaRengiGetir(masaVerisi['durum'] ?? 'bos'),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_bar,
                          size: 40, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        "Masa $masaId",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        masaKontrol(masaVerisi['durum'] ?? 'bos'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String masaKontrol(String durum) {
  if (durum == 'SiparisAlindi') return "Sipariş alındı";
  if (durum == 'bos') return "Boş";
  if (durum == 'odendi') return "Boş";
  if (durum == 'hazirlaniyor') return "Hazırlanıyor";
  if (durum == 'hazir') return "Hazır";
  return "Dolu";
}

Color masaRengiGetir(String durum) {
  if (durum == 'bos') return Colors.brown.shade200;
  if (durum == 'SiparisAlindi') return Colors.yellow[700]!;
  if (durum == 'odendi') return Colors.brown.shade200;
  if (durum == 'hazirlaniyor') return Colors.blue[300]!;
  if (durum == 'hazir') return Colors.green[400]!;
  return Colors.red[300]!;
}