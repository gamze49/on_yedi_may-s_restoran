import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KasaEkrani extends StatelessWidget {
  const KasaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          _header(),

          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _masalar(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _header() {
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

        Container(
          height: 130,
          color: Colors.black54,
        ),

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
      ],
    );
  }


  Widget _masalar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("masalar")
          .where("durum", isEqualTo: "hazir")
          .orderBy("masaNo")
          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.hasError) {
          return Center(
            child: Text("HATA: ${snapshot.error}"),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var masalar = snapshot.data!.docs;

        if (masalar.isEmpty) {
          return const Center(
            child: Text("Ödeme bekleyen masa yok"),
          );
        }

        double w = MediaQuery.of(context).size.width;

        int yan = 2;
        if (w > 100) yan = 3;
        if (w > 500) yan = 4;

        return GridView.builder(
          padding: const EdgeInsets.all(10),

          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: yan,
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),

          itemCount: masalar.length,

          itemBuilder: (context, i) {

            var masa = masalar[i];
            var data = masa.data() as Map<String, dynamic>;

            return _masaCard(
              context,
              masa.id,
              data["masaNo"],
            );
          },
        );
      },
    );
  }

  Widget _masaCard(
      BuildContext context,
      String id,
      int masaNo,
      ) {

    return GestureDetector(

      onTap: () {
        _detayDialog(context, masaNo);
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.brown.shade300,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Center(
          child: Text(
            "MASA $masaNo",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }


  void _detayDialog(
      BuildContext context,
      int masaNo,
      ) {

    showDialog(
      context: context,

      builder: (context) {

        return Dialog(

          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("siparisler")
                .where("masaNo", isEqualTo: masaNo.toString().padLeft(2,'0'))
                .where("durum", isEqualTo: "hazir")
                .snapshots(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Sipariş bulunamadı"),
                );
              }

              var siparis = snapshot.data!.docs.first;

              var data =
              siparis.data()
              as Map<String, dynamic>;

              List urunler =
              data["urunler"];

              double toplam =
              (data["toplam"] ?? 0).toDouble();

              return Padding(
                padding:
                const EdgeInsets.all(12),

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    Text(
                      "MASA $masaNo",
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    Column(
                      children:
                      urunler.map<Widget>((u) {

                        return Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                          children: [

                            Text(u["ad"]),

                            Text(
                                "x${u["adet"]}"),
                          ],
                        );

                      }).toList(),
                    ),

                    const SizedBox(
                        height: 10),

                    Text(
                      "Toplam: $toplam TL",
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    ElevatedButton(

                      onPressed: () async {
                        await FirebaseFirestore
                            .instance
                            .collection(
                            "siparisler")
                            .doc(
                            siparis.id)
                            .update({
                          "durum":
                          "odendi"
                        });


                        await FirebaseFirestore
                            .instance
                            .collection(
                            "masalar")
                            .doc(masaNo
                            .toString()
                            .padLeft(2, '0'))
                            .update({
                          "durum": "bos"
                        });

                        await FirebaseFirestore
                            .instance
                            .collection(
                            "ciro")
                            .add({
                          "masaNo":
                          masaNo,
                          "toplam":
                          toplam,
                          "zaman":
                          FieldValue
                              .serverTimestamp(),
                        });

                        Navigator.pop(
                            context);
                      },

                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        Colors.red,
                      ),

                      child: const Text(
                          "ÖDEME AL"),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}