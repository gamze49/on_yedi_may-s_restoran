import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SiparisEkrani extends StatefulWidget {
  final String masaId;
  final String garsonAdi;
  const SiparisEkrani(
      {super.key, required this.masaId, required this.garsonAdi});

  @override
  State<SiparisEkrani> createState() => _SiparisEkraniState();
}

class _SiparisEkraniState extends State<SiparisEkrani> {
  Map<String, Map<String, dynamic>> secilen_urunler = {};
  double toplam_tutar = 0;
  bool yukleniyor = false;

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);

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
        "masaNo": widget.masaId,
        "garson": widget.garsonAdi,
        "garsonAdi": widget.garsonAdi,
        "ad": widget.garsonAdi,
        "urunler": urunListesi,
        "toplam_tutar": toplam_tutar,
        "toplamTutar": toplam_tutar,
        "zaman": FieldValue.serverTimestamp(),
        "durum": "SiparisAlindi",
      });

      await FirebaseFirestore.instance
          .collection("masalar")
          .doc(widget.masaId)
          .update({"durum": "SiparisAlindi"});

      for (var entry in secilen_urunler.entries) {
        String urunAd = entry.key;
        int satilanAdet = entry.value["adet"];

        var urunSonuc = await FirebaseFirestore.instance
            .collection("menu")
            .where("ad", isEqualTo: urunAd)
            .limit(1)
            .get();

        if (urunSonuc.docs.isNotEmpty) {
          var urunDoc = urunSonuc.docs.first;
          var urunData = urunDoc.data();
          bool stokTakibi = urunData["stokTakibiAktif"] ?? false;

          if (stokTakibi) {
            int mevcutStok = (urunData["stok"] ?? 0) is int
                ? (urunData["stok"] ?? 0)
                : (urunData["stok"] as num).toInt();
            int yeniStok = mevcutStok - satilanAdet;
            if (yeniStok < 0) yeniStok = 0;
            await FirebaseFirestore.instance
                .collection("menu")
                .doc(urunDoc.id)
                .update({"stok": yeniStok});
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Sipariş başarıyla kaydedildi!"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
        backgroundColor: const Color(0xFFFAF7F2),
        appBar: AppBar(
          title: Text(
            "Masa ${widget.masaId}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          backgroundColor: _anaKahve,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _anaKahve));

        var urunler = snapshot.data!.docs;

        if (urunler.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.no_food_outlined, size: 50, color: Colors.brown.shade200),
                const SizedBox(height: 10),
                Text("Bu kategoride ürün bulunamadı.",
                    style: TextStyle(color: Colors.brown.shade300)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: urunler.length,
          itemBuilder: (context, index) {
            var veri = urunler[index].data() as Map<String, dynamic>;
            String ad = veri["ad"] ?? "İsimsiz Ürün";

            int fiyat = 0;
            if (veri["fiyat"] != null) {
              if (veri["fiyat"] is int) fiyat = veri["fiyat"];
              else if (veri["fiyat"] is double) fiyat = (veri["fiyat"] as double).toInt();
              else if (veri["fiyat"] is String) fiyat = int.tryParse(veri["fiyat"]) ?? 0;
            }

            String resimUrl = veri["resimUrl"] ?? "";
            int adet = secilen_urunler[ad]?["adet"] ?? 0;

            bool stokTakibi = veri["stokTakibiAktif"] ?? false;
            int stok = (veri["stok"] ?? 0) is int
                ? (veri["stok"] ?? 0)
                : (veri["stok"] as num).toInt();
            bool tukenmisMi = stokTakibi && stok <= 0;
            bool stokDoluMu = stokTakibi && adet >= stok && stok > 0;

            return _urunKarti(ad, fiyat, resimUrl, adet, tukenmisMi, stokDoluMu);
          },
        );
      },
    );
  }

  Widget _urunKarti(String ad, int fiyat, String resimUrl, int adet,
      bool tukenmisMi, bool stokDoluMu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tukenmisMi ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // Ürün resmi
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: resimUrl.isNotEmpty
                      ? Image.network(
                    resimUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    color: tukenmisMi ? Colors.grey.withOpacity(0.6) : null,
                    colorBlendMode: tukenmisMi ? BlendMode.saturation : null,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.fastfood_outlined, color: Colors.brown.shade200),
                      );
                    },
                  )
                      : Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.fastfood_outlined, color: Colors.brown.shade200),
                  ),
                ),
                if (tukenmisMi)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "TÜKENDİ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tukenmisMi ? Colors.grey : _koyuKahve,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$fiyat ₺",
                    style: TextStyle(
                      color: tukenmisMi ? Colors.grey : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (tukenmisMi)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        "TÜKENDİ",
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _adet(ad, fiyat, adet, tukenmisMi, stokDoluMu),
          ],
        ),
      ),
    );
  }

  Widget _adet(String ad, int fiyat, int adet, bool tukenmisMi, bool stokDoluMu) {
    return Row(
      children: [
        _adetButon(
          ikon: Icons.remove,
          etkin: !tukenmisMi && adet > 0,
          onTap: () => urun_guncelle(ad, fiyat, -1),
        ),
        SizedBox(
          width: 28,
          child: Text(
            "$adet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: tukenmisMi ? Colors.grey : _koyuKahve,
            ),
          ),
        ),
        _adetButon(
          ikon: Icons.add,
          etkin: !tukenmisMi && !stokDoluMu,
          onTap: () => urun_guncelle(ad, fiyat, 1),
        ),
      ],
    );
  }

  Widget _adetButon({required IconData ikon, required bool etkin, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: etkin ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: etkin ? _anaKahve.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: etkin ? _anaKahve.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          ikon,
          size: 16,
          color: etkin ? _anaKahve : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.brown.shade100, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Toplam Tutar",
                style: TextStyle(fontSize: 11, color: Colors.brown.shade400),
              ),
              Text(
                "₺${toplam_tutar.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _koyuKahve,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: (yukleniyor || secilen_urunler.isEmpty) ? null : siparisiKaydet,
            style: ElevatedButton.styleFrom(
              backgroundColor: _anaKahve,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: yukleniyor
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              "Siparişi Onayla",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}