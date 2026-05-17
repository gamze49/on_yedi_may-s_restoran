import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CiroEkrani extends StatelessWidget {
  const CiroEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ciro ve Analiz Paneli"),
          centerTitle: true,
          backgroundColor: Colors.brown[700],
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.orangeAccent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: "Genel"),
              Tab(icon: Icon(Icons.table_restaurant), text: "Masalar"),
              Tab(icon: Icon(Icons.person), text: "Garsonlar"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("ciro")
              .orderBy("tarih", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.brown));
            }

            var satislar = snapshot.data!.docs;

            if (satislar.isEmpty) {
              return const Center(child: Text("Henüz kaydedilmiş bir satış bulunamadı."));
            }

            DateTime simdi = DateTime.now();
            double toplamCiro = 0, aylikToplam = 0, gunlukToplam = 0;
            Map<String, double> masaCiroGunluk = {};
            Map<String, double> masaCiroAylik = {};
            Map<String, double> garsonCiroGunluk = {};
            Map<String, double> garsonCiroAylik = {};

            for (var satis in satislar) {
              var data = satis.data() as Map<String, dynamic>;

              double tutar = (data["toplam"] ?? data["toplamTutar"] ?? 0).toDouble();
              String masa = (data["masaNo"] ?? "Bilinmiyor").toString();

              String garsonAdi = data["ad"] ?? "Eski Kayıt";
              String rol = (data["role"] ?? "garson").toString().toLowerCase();

              toplamCiro += tutar;


              var tarihVerisi = data["tarih"] ?? data["zaman"];

              if (tarihVerisi != null) {
                DateTime satisTarihi = (tarihVerisi as Timestamp).toDate();

                masaCiroAylik[masa] = (masaCiroAylik[masa] ?? 0) + tutar;

                if (rol == "garson") {
                  garsonCiroAylik[garsonAdi] = (garsonCiroAylik[garsonAdi] ?? 0) + tutar;
                }


                bool ayniGun = satisTarihi.day == simdi.day &&
                    satisTarihi.month == simdi.month &&
                    satisTarihi.year == simdi.year;

                bool ayniAy = satisTarihi.month == simdi.month &&
                    satisTarihi.year == simdi.year;

                if (ayniGun) {
                  gunlukToplam += tutar;
                  masaCiroGunluk[masa] = (masaCiroGunluk[masa] ?? 0) + tutar;
                  if (rol == "garson") {
                    garsonCiroGunluk[garsonAdi] = (garsonCiroGunluk[garsonAdi] ?? 0) + tutar;
                  }
                }


                if (ayniAy) {
                  aylikToplam += tutar;
                }
              }
            }


            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () async => {},
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _ciroOzetKarti(toplamCiro, gunlukToplam, aylikToplam),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text("Son İşlemler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown)),
                        ),
                        _satisListesi(satislar),
                      ],
                    ),
                  ),
                ),
                _analizListesi(masaCiroGunluk, masaCiroAylik, "Masa"),
                _analizListesi(garsonCiroGunluk, garsonCiroAylik, "Garson"),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _analizListesi(Map<String, double> gunluk, Map<String, double> aylik, String etiket) {
    var siraliAnahtarlar = aylik.keys.toList()
      ..sort((a, b) => aylik[b]!.compareTo(aylik[a]!));

    if (siraliAnahtarlar.isEmpty) return const Center(child: Text("Henüz veri girişi yok."));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: siraliAnahtarlar.length,
      itemBuilder: (context, i) {
        String anahtar = siraliAnahtarlar[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.brown[400],
              child: Text("${i + 1}", style: const TextStyle(color: Colors.white)),
            ),
            title: Text("$etiket: $anahtar", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Bugün: ₺${gunluk[anahtar] ?? 0}\nGenel Toplam: ₺${aylik[anahtar] ?? 0}"),
            trailing: const Icon(Icons.trending_up, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget _ciroOzetKarti(double toplam, double gunluk, double aylik) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.brown[700]!, Colors.brown[400]!]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text("Bugünkü Kazanç", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 5),
          Text("₺${gunluk.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _altOzet("Bu Ay", aylik),
              Container(width: 1, height: 30, color: Colors.white24),
              _altOzet("Genel Toplam", toplam),
            ],
          )
        ],
      ),
    );
  }

  Widget _altOzet(String baslik, double miktar) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text("₺${miktar.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _satisListesi(List<QueryDocumentSnapshot> satislar) {
    int gosterilecekAdet = satislar.length > 10 ? 10 : satislar.length;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gosterilecekAdet,
      itemBuilder: (context, i) {
        var data = satislar[i].data() as Map<String, dynamic>;

        var tarihVerisi = data["tarih"] ?? data["zaman"];
        String formatliZaman = "00:00";

        if (tarihVerisi != null) {
          DateTime tarih = (tarihVerisi as Timestamp).toDate();
          formatliZaman = DateFormat('dd/MM HH:mm').format(tarih);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text("₺${data["toplam"] ?? data["toplamTutar"]} - Masa ${data["masaNo"]}"),
            subtitle: Text("Personel: ${data["ad"] ?? 'Eski Kayıt'}"),
            trailing: Text(formatliZaman, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }
}