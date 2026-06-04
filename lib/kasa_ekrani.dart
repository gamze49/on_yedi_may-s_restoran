import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'profil_ayarlari_ekrani.dart';

class KasaEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid;
  const KasaEkrani({
    super.key,
    required this.personelAdi,
    required this.userUid,
  });

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);
  static const Color _kremZemin = Color(0xFFFAF7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kremZemin,
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
          child: Image.asset("assets/images/restoran.jpg", fit: BoxFit.cover),
        ),
        Container(
          height: 130,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xAA4E342E), Color(0xCC6D4C41)],
            ),
          ),
        ),
        SafeArea(
          child: SizedBox(
            height: 70,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "KASA EKRANI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Ödeme Bekleyen Masalar",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 45,
          left: 15,
          child: IconButton(
            icon: const Icon(Icons.manage_accounts_outlined,
                color: Colors.white, size: 26),
            tooltip: "Hesap Ayarları",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfilAyarlariEkrani(userUid: userUid),
              ),
            ),
          ),
        ),
        Positioned(
          top: 45,
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.power_settings_new,
                color: Colors.white, size: 26),
            tooltip: "Çıkış Yap",
            onPressed: () => AuthServis.isimliCikisYap(context, personelAdi),
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
          return const Center(
              child: CircularProgressIndicator(color: _anaKahve));
        }

        var masalar = snapshot.data!.docs;
        if (masalar.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 60, color: Colors.brown.shade200),
                const SizedBox(height: 12),
                Text("Ödeme bekleyen masa yok",
                    style:
                    TextStyle(color: Colors.brown.shade300, fontSize: 16)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
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
          border: Border.all(
              color: const Color(0xFFFFB300).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_restaurant_rounded,
                  color: Color(0xFFFFB300), size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              "MASA $masaDocId",
              style: TextStyle(
                color: _koyuKahve,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Ödeme Bekliyor",
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                        child:
                        CircularProgressIndicator(color: _anaKahve));
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


                  final bool nakitModu = secilenOdemeYontemi == "Nakit";
                  double alinanNakit =
                  nakitModu ? (double.tryParse(girilenMiktar) ?? 0) : 0;
                  double paraUstu = nakitModu && alinanNakit > genelToplam
                      ? alinanNakit - genelToplam
                      : 0;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _anaKahve.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_outlined,
                                    color: _anaKahve, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "MASA $masaDocId ÖDEME",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _koyuKahve,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),


                          if (tumUrunler.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.brown.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SİPARİŞ DETAYI",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: _anaKahve,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...tumUrunler.map((u) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        Text(
                                            "${u["ad"]} x${u["adet"]}",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors
                                                    .brown.shade700)),
                                        Text(
                                          "₺${((u["fiyat"] as num) * (u["adet"] as num)).toStringAsFixed(0)}",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w600,
                                              color: _koyuKahve),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],


                          _ozetKarti(araToplam, kdv, genelToplam),
                          const SizedBox(height: 16),


                          Row(
                            children: [
                              _odemeTipiButon(
                                "Nakit",
                                Icons.payments_outlined,
                                secilenOdemeYontemi == "Nakit",
                                    () => setState(() {
                                  secilenOdemeYontemi = "Nakit";

                                  girilenMiktar = "";
                                }),
                              ),
                              const SizedBox(width: 10),
                              _odemeTipiButon(
                                "Kredi Kartı",
                                Icons.credit_card_outlined,
                                secilenOdemeYontemi == "Kredi Kartı",
                                    () => setState(() {
                                  secilenOdemeYontemi = "Kredi Kartı";

                                  girilenMiktar = "";
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),


                          if (nakitModu) ...[
                            _miktarGostergesi(girilenMiktar, paraUstu),
                            const SizedBox(height: 16),
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

                                  if (deger == "." &&
                                      girilenMiktar.contains(".")) return;
                                  girilenMiktar += deger;
                                }
                              });
                            }),
                            const SizedBox(height: 16),
                          ],


                          if (!nakitModu) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.blue.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.credit_card,
                                      color: Colors.blue.shade600, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Kredi kartı ile ödeme: ₺${genelToplam.toStringAsFixed(2)} tahsil edilecek.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],


                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              elevation: 2,
                            ),
                            onPressed: () async {

                              if (nakitModu && girilenMiktar.isNotEmpty) {
                                double alinan =
                                    double.tryParse(girilenMiktar) ?? 0;
                                if (alinan < genelToplam) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          "Alınan nakit tutardan az! Lütfen kontrol edin."),
                                      backgroundColor: Colors.red.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10)),
                                    ),
                                  );
                                  return;
                                }
                              }
                              await _odemeTamamla(
                                masaDocId,
                                genelToplam,
                                tumUrunler,
                                siparisler,
                                secilenOdemeYontemi,
                                nakitModu ? alinanNakit : null,
                                nakitModu ? paraUstu : null,
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check_circle_outline,
                                size: 20),
                            label: const Text(
                              "İŞLEMİ ONAYLA",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Column(
        children: [
          _ozetSatiri("Ara Toplam", "₺${ara.toStringAsFixed(2)}"),
          _ozetSatiri("KDV (%10)", "₺${kdv.toStringAsFixed(2)}"),
          Divider(color: Colors.brown.shade100, height: 20),
          _ozetSatiri("Toplam Tutar", "₺${toplam.toStringAsFixed(2)}",
              bold: true, buyuk: true),
        ],
      ),
    );
  }

  Widget _ozetSatiri(String baslik, String deger,
      {bool bold = false, bool buyuk = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(baslik,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                color: bold ? _koyuKahve : Colors.brown.shade500,
                fontSize: buyuk ? 15 : 13,
              )),
          Text(deger,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold ? _koyuKahve : Colors.brown.shade700,
                fontSize: buyuk ? 16 : 13,
              )),
        ],
      ),
    );
  }


  Widget _odemeTipiButon(
      String ad, IconData ikon, bool secili, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: secili ? _anaKahve : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: secili ? _anaKahve : Colors.brown.shade100,
              width: secili ? 0 : 1,
            ),
            boxShadow: secili
                ? [
              BoxShadow(
                  color: _anaKahve.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ]
                : [],
          ),
          child: Column(
            children: [
              Icon(ikon,
                  color: secili ? Colors.white : Colors.brown.shade400),
              const SizedBox(height: 4),
              Text(ad,
                  style: TextStyle(
                    color: secili ? Colors.white : Colors.brown.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
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
                girilen.isEmpty ? "0" : girilen, const Color(0xFF1565C0))),
        const SizedBox(width: 10),
        Expanded(
            child: _bilgiKutusu("Para Üstü",
                "₺${paraUstu.toStringAsFixed(2)}", Colors.green.shade700)),
      ],
    );
  }

  Widget _bilgiKutusu(String baslik, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(baslik,
              style: TextStyle(
                  fontSize: 11,
                  color: renk,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(deger,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: renk)),
        ],
      ),
    );
  }


  Widget _tusTakimi(Function(String) onTapped) {
    var tuslar = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "⌫"];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tuslar.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8),
      itemBuilder: (context, i) {
        bool isSpecial = tuslar[i] == "C" || tuslar[i] == "⌫";
        return Material(
          color: isSpecial ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onTapped(tuslar[i]),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSpecial
                      ? Colors.red.shade200
                      : Colors.brown.shade100,
                ),
              ),
              child: Center(
                child: Text(
                  tuslar[i],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isSpecial
                        ? Colors.red.shade600
                        : _koyuKahve,
                  ),
                ),
              ),
            ),
          ),
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
      double? alinanNakit,
      double? paraUstu,
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

    for (var s in siparisler) {
      await FirebaseFirestore.instance
          .collection("siparisler")
          .doc(s.id)
          .update({
        "durum": "odendi",
        "odemeYontemi": yontem,
        "garsonAdi": asilGarson,
        "toplam": toplam,

        if (yontem == "Nakit" && alinanNakit != null) ...{
          "alinanNakit": alinanNakit,
          "paraUstu": paraUstu ?? 0,
        },
      });
    }

    await FirebaseFirestore.instance
        .collection("masalar")
        .doc(masaDocId)
        .update({"durum": "bos"});

    await FirebaseFirestore.instance.collection("ciro").add({
      "masaNo": masaDocId,
      "toplam": toplam,
      "toplamTutar": toplam,
      "odemeYontemi": yontem,
      "tarih": FieldValue.serverTimestamp(),
      "zaman": FieldValue.serverTimestamp(),

      "satilanUrunler": tumUrunler.expand((u) {
        int adet = (u["adet"] as num?)?.toInt() ?? 1;
        return List.filled(adet, u["ad"].toString());
      }).toList(),
      "ad": asilGarson,
      "role": "garson",
      if (yontem == "Nakit" && alinanNakit != null) ...{
        "alinanNakit": alinanNakit,
        "paraUstu": paraUstu ?? 0,
      },
    });
  }
}