import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SiparisEkrani extends StatefulWidget {
  final String masaId;
  const SiparisEkrani({super.key, required this.masaId});

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

      await FirebaseFirestore.instance.collection("siparisler").doc(widget.masaId).set({
        "masaNo": widget.masaId,
        "urunler": urunListesi,
        "toplam": toplam_tutar,
        "durum": "SiparisAlindi",
        "zaman": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("masalar")
          .doc(widget.masaId)
          .update({"durum": "SiparisAlindi"});

      if (mounted) Navigator.pop(context);

    } catch (e) {
      print(e);
    }

    if (mounted) setState(() => yukleniyor = false);
  }

  void urun_guncelle(String ad, int fiyat, int degisim) {
    setState(() {

      if (!secilen_urunler.containsKey(ad)) {
        if (degisim > 0) {
          secilen_urunler[ad] = {
            "ad": ad,
            "fiyat": fiyat,
            "adet": 1
          };
        }
      } else {
        int yeni = secilen_urunler[ad]!["adet"] + degisim;

        if (yeni <= 0) {
          secilen_urunler.remove(ad);
        } else {
          secilen_urunler[ad]!["adet"] = yeni;
        }
      }

      toplam_tutar = 0;
      secilen_urunler.forEach((k, v) {
        toplam_tutar += v["fiyat"] * v["adet"];
      });

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [

          _header(),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.brown.shade900,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _menu(),
            ),
          ),

        ],
      ),

      bottomNavigationBar: _bottomBar(),
    );
  }



  Widget _header() {
    return Stack(
      children: [

        SizedBox(
          height: 160,
          width: double.infinity,
          child: Image.asset(
            "assets/images/restoran.jpg",
            fit: BoxFit.cover,
          ),
        ),

        Container(
          height: 160,
          color: Colors.black.withOpacity(0.4),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [

                IconButton(
                  icon: const Icon(Icons.arrow_back,color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(width: 10),

                Text(
                  "MASA ${widget.masaId}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),
        ),

      ],
    );
  }

  Widget _menu() {

    return StreamBuilder<QuerySnapshot>(

      stream: FirebaseFirestore.instance
          .collection("menu")
          .where("aktif", isEqualTo: true)
          .snapshots(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, List<DocumentSnapshot>> grup = {};

        for (var doc in snapshot.data!.docs) {

          String kategori = doc["kategori"];

          grup.putIfAbsent(kategori, () => []);

          grup[kategori]!.add(doc);
        }

        var kategoriler = grup.keys.toList();

        return ListView.builder(

          itemCount: kategoriler.length,

          itemBuilder: (context, i) {

            String kat = kategoriler[i];

            List<DocumentSnapshot> urunler = grup[kat]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kat,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                ...urunler.map((doc) {

                  var urun = doc.data() as Map<String, dynamic>;

                  String ad = urun["ad"];

                  int fiyat = (urun["fiyat"] as num).toInt();

                  int adet = secilen_urunler[ad]?["adet"] ?? 0;

                  return _urunCard(ad,fiyat,urun["resimUrl"],adet);

                }),

              ],
            );
          },
        );
      },
    );
  }

  Widget _urunCard(String ad,int fiyat,String url,int adet) {

    return Card(

      margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6),

      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),

      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    ad,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "$fiyat TL",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),
            ),

            _adet(ad,fiyat,adet),

          ],
        ),
      ),
    );
  }

  Widget _adet(String ad,int fiyat,int adet) {

    return Row(
      children: [

        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => urun_guncelle(ad,fiyat,-1),
        ),

        Text("$adet"),

        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => urun_guncelle(ad,fiyat,1),
        ),

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

        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          )
        ],
      ),

      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [

          Text(
            "$toplam_tutar TL",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          ElevatedButton(

            onPressed: yukleniyor
                ? null
                : siparisiKaydet,

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15),
            ),

            child: const Text("ONAYLA"),

          )

        ],
      ),
    );
  }

}