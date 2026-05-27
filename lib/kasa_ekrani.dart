import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'profil_ayarlari_ekrani.dart';

class KasaEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid; // EKLENDİ
  const KasaEkrani({
    super.key,
    required this.personelAdi,
    required this.userUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _header(context),
          Expanded(child: _modernMasalar(context)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: Image.asset(
            "assets/images/restoran.jpg",
            fit: BoxFit.cover,
          ),
        ),
        Container(height: 130, color: Colors.black54),
        const SafeArea(
          child: Center(
            child: Text(
              "KASA EKRANI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          top: 45,
          left: 15,
          child: IconButton(
            icon: const Icon(Icons.manage_accounts,
                color: Colors.white, size: 28),
            tooltip: "Hesap Ayarları",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilAyarlariEkrani(
                  userUid: userUid, // DÜZELTME: userUid geçiriliyor
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 45,
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.power_settings_new,
                color: Colors.white, size: 28),
            tooltip: "Çıkış Yap",
            onPressed: () =>
                AuthServis.isimliCikisYap(context, personelAdi),
          ),
        ),
      ],
    );
  }

  Widget _modernMasalar(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("masalar")
          .where("durum",
          whereIn: ["SiparisAlindi", "hazirlaniyor", "hazir", "dolu"])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("HATA: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var masalar = snapshot.data!.docs;
        if (masalar.isEmpty) {
          return const Center(
            child: Text("Ödeme bekleyen masa yok",
                style: TextStyle(color: Colors.grey)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: masalar.length,
          itemBuilder: (context, i) {
            var masa = masalar[i];
            var data = masa.data() as Map<String, dynamic>;
            return _modernMasaCard(context, masa.id, data["masaNo"]);
          },
        );
      },
    );
  }

  Widget _modernMasaCard(
      BuildContext context, String masaDocId, dynamic masaNo) {
    return GestureDetector(
      onTap: () => _detayDialog(context, masaDocId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_restaurant_rounded,
                  color: Colors.brown.shade400, size: 35),
            ),
            const SizedBox(height: 12),
            Text(
              "MASA $masaDocId",
              style: const TextStyle(
                color: Color(0xFF3E2723),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Ödeme Bekliyor",
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _detayDialog(BuildContext context, String masaDocId) {
    String girilenMiktar = "";
    String secilenOdemeYontemi = "Nakit";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("siparisler")
                    .where("masaNo", isEqualTo: masaDocId)
                    .where("durum", whereNotIn: ["odendi"])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  var siparisler = snapshot.data!.docs;
                  double araToplam = 0;
                  List tumUrunler = [];

                  for (var s in siparisler) {
                    var d = s.data() as Map<String, dynamic>;
                    double tutar = 0;
                    if (d["toplam_tutar"] != null) {
                      tutar = (d["toplam_tutar"] as num).toDouble();
                    } else if (d["toplamTutar"] != null) {
                      tutar = (d["toplamTutar"] as num).toDouble();
                    } else if (d["toplam"] != null) {
                      tutar = (d["toplam"] as num).toDouble();
                    }
                    araToplam += tutar;

                    if (d["urunler"] != null) {
                      tumUrunler.addAll(d["urunler"]);
                    }
                  }

                  double kdv = araToplam * 0.10;
                  double genelToplam = araToplam + kdv;
                  double alinanNakit =
                      double.tryParse(girilenMiktar) ?? 0;
                  double paraUstu = alinanNakit > genelToplam
                      ? alinanNakit - genelToplam
                      : 0;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("MASA $masaDocId ÖDEME",
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const Divider(),
                          if (tumUrunler.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text("SİPARİŞ DETAYI",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.brown)),
                                  const SizedBox(height: 6),
                                  ...tumUrunler.map((u) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            "${u["ad"]} x${u["adet"]}",
                                            style: const TextStyle(
                                                fontSize: 13)),
                                        Text(
                                            "₺${((u["fiyat"] as num) * (u["adet"] as num)).toStringAsFixed(0)}",
                                            style: const TextStyle(
                                                fontSize: 13)),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _ozetKarti(araToplam, kdv, genelToplam),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _odemeTipiButon(
                                "Nakit",
                                Icons.money,
                                secilenOdemeYontemi == "Nakit",
                                    () => setState(
                                        () => secilenOdemeYontemi = "Nakit"),
                              ),
                              const SizedBox(width: 10),
                              _odemeTipiButon(
                                "Kredi Kartı",
                                Icons.credit_card,
                                secilenOdemeYontemi == "Kredi Kartı",
                                    () => setState(() =>
                                secilenOdemeYontemi = "Kredi Kartı"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _miktarGostergesi(girilenMiktar, paraUstu),
                          const SizedBox(height: 20),
                          _tusTakimi((deger) {
                            setState(() {
                              if (deger == "C") {
                                girilenMiktar = "";
                              } else if (deger == "⌫") {
                                if (girilenMiktar.isNotEmpty) {
                                  girilenMiktar = girilenMiktar.substring(
                                      0, girilenMiktar.length - 1);
                                }
                              } else {
                                girilenMiktar += deger;
                              }
                            });
                          }),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              minimumSize:
                              const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15)),
                            ),
                            onPressed: () async {
                              await _odemeTamamla(
                                masaDocId,
                                genelToplam,
                                tumUrunler,
                                siparisler,
                                secilenOdemeYontemi,
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text(
                              "İŞLEMİ ONAYLA",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _ozetKarti(double ara, double kdv, double toplam) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _ozetSatiri("Ara Toplam", "₺${ara.toStringAsFixed(2)}"),
          _ozetSatiri("KDV (%10)", "₺${kdv.toStringAsFixed(2)}"),
          const Divider(),
          _ozetSatiri("Toplam Tutar", "₺${toplam.toStringAsFixed(2)}",
              bold: true),
        ],
      ),
    );
  }

  Widget _ozetSatiri(String baslik, String deger, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(baslik,
              style: TextStyle(
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal)),
          Text(deger,
              style: TextStyle(
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _odemeTipiButon(
      String ad, IconData ikon, bool secili, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: secili ? Colors.brown : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.brown.shade200),
          ),
          child: Column(
            children: [
              Icon(ikon,
                  color: secili ? Colors.white : Colors.brown),
              Text(ad,
                  style: TextStyle(
                      color: secili ? Colors.white : Colors.brown,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miktarGostergesi(String girilen, double paraUstu) {
    return Row(
      children: [
        Expanded(
          child: _bilgiKutusu("Alınan Nakit",
              girilen.isEmpty ? "0.00" : girilen, Colors.blue.shade700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _bilgiKutusu("Para Üstü",
              "₺${paraUstu.toStringAsFixed(2)}", Colors.green.shade700),
        ),
      ],
    );
  }

  Widget _bilgiKutusu(String baslik, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(baslik,
              style: TextStyle(fontSize: 12, color: renk)),
          Text(deger,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: renk)),
        ],
      ),
    );
  }

  Widget _tusTakimi(Function(String) onTapped) {
    var tuslar = [
      "1", "2", "3",
      "4", "5", "6",
      "7", "8", "9",
      "C", "0", "⌫"
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tuslar.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8),
      itemBuilder: (context, i) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            (tuslar[i] == "C" || tuslar[i] == "⌫")
                ? Colors.red.shade50
                : Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onPressed: () => onTapped(tuslar[i]),
          child: Text(tuslar[i],
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Future<void> _odemeTamamla(
      String masaDocId,
      double toplam,
      List tumUrunler,
      List siparisler,
      String yontem,
      ) async {
    String asilGarson = "Bilinmiyor";
    if (siparisler.isNotEmpty) {
      var siparisVerisi =
      siparisler.first.data() as Map<String, dynamic>;
      asilGarson = siparisVerisi['garsonAdi'] ??
          siparisVerisi['garson'] ??
          siparisVerisi['ad'] ??
          "Bilinmiyor";
    }

    // Tüm siparişleri "odendi" yap
    for (var s in siparisler) {
      await FirebaseFirestore.instance
          .collection("siparisler")
          .doc(s.id)
          .update({
        "durum": "odendi",
        "odemeYontemi": yontem,
        "garsonAdi": asilGarson,
        "toplam": toplam,
      });
    }

    // Masayı boşa al
    await FirebaseFirestore.instance
        .collection("masalar")
        .doc(masaDocId)
        .update({"durum": "bos"});

    // Ciro koleksiyonuna kaydet
    await FirebaseFirestore.instance.collection("ciro").add({
      "masaNo": masaDocId,
      "toplam": toplam,
      "toplamTutar": toplam,
      "odemeYontemi": yontem,
      "tarih": FieldValue.serverTimestamp(),
      "zaman": FieldValue.serverTimestamp(),
      "satilanUrunler":
      tumUrunler.map((u) => u["ad"]).toList(),
      "ad": asilGarson,
      "role": "garson",
    });
  }
}