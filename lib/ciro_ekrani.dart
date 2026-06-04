import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CiroEkrani extends StatelessWidget {
  const CiroEkrani({super.key});

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);
  static const Color _kremZemin = Color(0xFFFAF7F2);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _kremZemin,
        appBar: AppBar(
          title: const Text("Ciro & Analiz", style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
          backgroundColor: _anaKahve,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: "Genel"),
              Tab(icon: Icon(Icons.table_restaurant_outlined, size: 18), text: "Masalar"),
              Tab(icon: Icon(Icons.person_outline, size: 18), text: "Garsonlar"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("ciro")
              .orderBy("tarih", descending: true)
              .snapshots(),
          builder: (context, ciroSnapshot) {
            if (ciroSnapshot.hasError) return Center(child: Text("Hata: ${ciroSnapshot.error}"));
            if (ciroSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _anaKahve));
            }

            List<Map<String, dynamic>> tumSatislar = [];
            if (ciroSnapshot.hasData) {
              for (var doc in ciroSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                tumSatislar.add({...data, '_docId': doc.id});
              }
            }

            if (tumSatislar.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 60, color: Colors.brown.shade200),
                    const SizedBox(height: 12),
                    Text("Henüz satış kaydı bulunamadı.", style: TextStyle(color: Colors.brown.shade300, fontSize: 15)),
                  ],
                ),
              );
            }

            DateTime simdi = DateTime.now();
            double toplamCiro = 0, aylikToplam = 0, gunlukToplam = 0;
            Map<String, double> masaCiroGunluk = {};
            Map<String, double> masaCiroAylik = {};
            Map<String, double> garsonCiroGunluk = {};
            Map<String, double> garsonCiroAylik = {};

            for (var data in tumSatislar) {
              double tutar = 0;
              if (data["toplam"] != null) tutar = (data["toplam"] as num).toDouble();
              else if (data["toplamTutar"] != null) tutar = (data["toplamTutar"] as num).toDouble();
              else if (data["toplam_tutar"] != null) tutar = (data["toplam_tutar"] as num).toDouble();

              String masa = (data["masaNo"] ?? "Bilinmiyor").toString();
              String garsonAdi = data["ad"] ?? data["garsonAdi"] ?? data["garson"] ?? "Bilinmiyor";

              toplamCiro += tutar;
              var tarihVerisi = data["tarih"] ?? data["zaman"];

              if (tarihVerisi != null) {
                DateTime satisTarihi = (tarihVerisi as Timestamp).toDate();
                masaCiroAylik[masa] = (masaCiroAylik[masa] ?? 0) + tutar;
                garsonCiroAylik[garsonAdi] = (garsonCiroAylik[garsonAdi] ?? 0) + tutar;

                bool ayniGun = satisTarihi.day == simdi.day && satisTarihi.month == simdi.month && satisTarihi.year == simdi.year;
                bool ayniAy = satisTarihi.month == simdi.month && satisTarihi.year == simdi.year;

                if (ayniGun) {
                  gunlukToplam += tutar;
                  masaCiroGunluk[masa] = (masaCiroGunluk[masa] ?? 0) + tutar;
                  garsonCiroGunluk[garsonAdi] = (garsonCiroGunluk[garsonAdi] ?? 0) + tutar;
                }
                if (ayniAy) aylikToplam += tutar;
              }
            }

            tumSatislar.sort((a, b) {
              var tarihA = a["tarih"] ?? a["zaman"];
              var tarihB = b["tarih"] ?? b["zaman"];
              if (tarihA == null && tarihB == null) return 0;
              if (tarihA == null) return 1;
              if (tarihB == null) return -1;
              return (tarihB as Timestamp).compareTo(tarihA as Timestamp);
            });

            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () async => {},
                  color: _anaKahve,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _ciroOzetKarti(toplamCiro, gunlukToplam, aylikToplam),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Container(width: 3, height: 14, decoration: BoxDecoration(color: _anaKahve, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              Text("Son İşlemler", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _koyuKahve)),
                            ],
                          ),
                        ),
                        _satisListesi(tumSatislar),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _analizListesi(masaCiroGunluk, masaCiroAylik, "Masa", Icons.table_restaurant_outlined),
                _analizListesi(garsonCiroGunluk, garsonCiroAylik, "Garson", Icons.person_outline),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _analizListesi(Map<String, double> gunluk, Map<String, double> aylik, String etiket, IconData ikon) {
    var siraliAnahtarlar = aylik.keys.toList()..sort((a, b) => aylik[b]!.compareTo(aylik[a]!));

    if (siraliAnahtarlar.isEmpty) {
      return Center(child: Text("Henüz veri girişi yok.", style: TextStyle(color: Colors.brown.shade300)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: siraliAnahtarlar.length,
      itemBuilder: (context, i) {
        String anahtar = siraliAnahtarlar[i];
        double toplamTutar = aylik[anahtar]!;
        double gunlukTutar = gunluk[anahtar] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _anaKahve.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "${i + 1}",
                    style: TextStyle(color: _anaKahve, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$etiket: $anahtar",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _koyuKahve),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Bugün: ₺${gunlukTutar.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 11, color: Colors.brown.shade400),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₺${toplamTutar.toStringAsFixed(2)}",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.green.shade700),
                  ),
                  Text("toplam", style: TextStyle(fontSize: 10, color: Colors.brown.shade300)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ciroOzetKarti(double toplam, double gunluk, double aylik) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E342E), Color(0xFF6D4C41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E342E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("Bugünkü Kazanç", style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            "₺${gunluk.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _altOzet("Bu Ay", aylik),
                Container(width: 1, height: 32, color: Colors.white24),
                _altOzet("Genel Toplam", toplam),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _altOzet(String baslik, double miktar) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          "₺${miktar.toStringAsFixed(2)}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }

  Widget _satisListesi(List<Map<String, dynamic>> satislar) {
    int gosterilecekAdet = satislar.length > 10 ? 10 : satislar.length;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gosterilecekAdet,
      itemBuilder: (context, i) {
        var data = satislar[i];
        var tarihVerisi = data["tarih"] ?? data["zaman"];
        String formatliZaman = "--:--";
        if (tarihVerisi != null) {
          DateTime tarih = (tarihVerisi as Timestamp).toDate();
          formatliZaman = DateFormat('dd/MM HH:mm').format(tarih);
        }

        dynamic tutarRaw = data["toplam"] ?? data["toplamTutar"] ?? data["toplam_tutar"] ?? 0;
        String garson = data["ad"] ?? data["garsonAdi"] ?? data["garson"] ?? "Bilinmiyor";

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "₺$tutarRaw — Masa ${data["masaNo"] ?? "-"}",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _koyuKahve),
                    ),
                    Text(garson, style: TextStyle(fontSize: 11, color: Colors.brown.shade400)),
                  ],
                ),
              ),
              Text(
                formatliZaman,
                style: TextStyle(color: Colors.brown.shade300, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}