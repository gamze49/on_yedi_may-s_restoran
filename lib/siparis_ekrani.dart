import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SiparisEkrani extends StatefulWidget {
  final String masaId;
  final String garsonAdi;
  const SiparisEkrani({super.key, required this.masaId, required this.garsonAdi});

  @override
  State<SiparisEkrani> createState() => _SiparisEkraniState();
}

class _SiparisEkraniState extends State<SiparisEkrani> {
  Map<String, Map<String, dynamic>> secilen_urunler = {};
  double toplam_tutar = 0;
  bool yukleniyor = false;

  Future<void> siparisiKaydet() async {
    if (secilen_urunler.isEmpty) return;

    setState(() => yukleniyor = true);

    try {
      List urunListesi = [];
      secilen_urunler.forEach((key, value) {
        urunListesi.add({
          "ad": value["ad"],
          "fiyat": value["fiyat"],
          "adet": value["adet"],
        });
      });

      await FirebaseFirestore.instance.collection("siparisler").add({
        "masaNo": widget.masaId,           // string, "01","15" gibi — kasa ile tutarlı
        "garson": widget.garsonAdi,
        "garsonAdi": widget.garsonAdi,     // kasa ekranının aradığı alan
        "ad": widget.garsonAdi,            // ciro ekranının aradığı alan
        "urunler": urunListesi,
        "toplam_tutar": toplam_tutar,      // kasa ekranının aradığı alan
        "toplamTutar": toplam_tutar,       // yedek
        "zaman": FieldValue.serverTimestamp(),
        "durum": "SiparisAlindi",
      });

      await FirebaseFirestore.instance
          .collection("masalar")
          .doc(widget.masaId)
          .update({"durum": "SiparisAlindi"});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sipariş başarıyla kaydedildi!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sipariş kaydedilirken hata oluştu: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  void urun_guncelle(String ad, int fiyat, int degisim) {
    setState(() {
      if (!secilen_urunler.containsKey(ad)) {
        if (degisim > 0) {
          secilen_urunler[ad] = {"ad": ad, "fiyat": fiyat, "adet": degisim};
        }
      } else {
        int yeni_adet = secilen_urunler[ad]!["adet"] + degisim;
        if (yeni_adet <= 0) {
          secilen_urunler.remove(ad);
        } else {
          secilen_urunler[ad]!["adet"] = yeni_adet;
        }
      }

      toplam_tutar = 0;
      secilen_urunler.forEach((key, value) {
        toplam_tutar += value["fiyat"] * value["adet"];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Masa ${widget.masaId} Sipariş"),
          backgroundColor: Colors.brown.shade200,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Çorbalar"),
              Tab(text: "Ana Yemek"),
              Tab(text: "Salata"),
              Tab(text: "Tatlı"),
              Tab(text: "İçecek"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _urunListesi("Çorbalar"),
            _urunListesi("Ana Yemek"),
            _urunListesi("Salata"),
            _urunListesi("Tatlı"),
            _urunListesi("İçecek"),
          ],
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

  Widget _urunListesi(String kategori) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("menu")
          .where("kategori", isEqualTo: kategori)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Hata oluştu."));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var urunler = snapshot.data!.docs;

        if (urunler.isEmpty) {
          return const Center(child: Text("Bu kategoride ürün bulunamadı."));
        }

        return ListView.builder(
          itemCount: urunler.length,
          itemBuilder: (context, index) {
            var veri = urunler[index].data() as Map<String, dynamic>;
            String ad = veri["ad"] ?? "İsimsiz Ürün";

            int fiyat = 0;
            if (veri["fiyat"] != null) {
              if (veri["fiyat"] is int) {
                fiyat = veri["fiyat"];
              } else if (veri["fiyat"] is double) {
                fiyat = (veri["fiyat"] as double).toInt();
              } else if (veri["fiyat"] is String) {
                fiyat = int.tryParse(veri["fiyat"]) ?? 0;
              }
            }

            String resimUrl = veri["resimUrl"] ?? "";
            int adet = secilen_urunler[ad]?["adet"] ?? 0;

            return _urunKarti(ad, fiyat, resimUrl, adet);
          },
        );
      },
    );
  }

  Widget _urunKarti(String ad, int fiyat, String resimUrl, int adet) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: resimUrl.isNotEmpty
                  ? Image.network(
                resimUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  );
                },
              )
                  : Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade300,
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("$fiyat TL",
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _adet(ad, fiyat, adet),
          ],
        ),
      ),
    );
  }

  Widget _adet(String ad, int fiyat, int adet) {
    return Row(
      children: [
        IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => urun_guncelle(ad, fiyat, -1)),
        Text("$adet"),
        IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => urun_guncelle(ad, fiyat, 1)),
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$toplam_tutar TL",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          ElevatedButton(
            onPressed: yukleniyor ? null : siparisiKaydet,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text("Siparişi Onayla",
                style: TextStyle(color: Colors.brown)),
          ),
        ],
      ),
    );
  }
}