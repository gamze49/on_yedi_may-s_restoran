import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MasaYonetimEkrani extends StatefulWidget {
  const MasaYonetimEkrani({super.key});

  @override
  State<MasaYonetimEkrani> createState() => _MasaYonetimEkraniState();
}

class _MasaYonetimEkraniState extends State<MasaYonetimEkrani> {
  String aramaKriteri = "";

  void _masaEkle(int yeniMasaNo) async {
    String masaId = yeniMasaNo.toString().padLeft(2, '0');
    await FirebaseFirestore.instance.collection("masalar").doc(masaId).set({
      "masaNo": yeniMasaNo,
      "durum": "bos",
      "aktif": true,
      "kisiSayisi": 0,
      "sonGuncelleme": FieldValue.serverTimestamp(),
    });
  }

  void _masaSil(BuildContext context, String docId, String durum) async {
    if (durum != "bos") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu masa şu an aktif! Silmek için önce masayı boşaltmalısınız."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await FirebaseFirestore.instance.collection("masalar").doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masa başarıyla silindi."), backgroundColor: Colors.green),
      );
    }
  }

  Widget appBarIstatistik(String baslik, int adet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$adet",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          baslik,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("masalar").orderBy("masaNo").snapshots(),
      builder: (context, snapshot) {
        int bosSayisi = 0;
        int doluSayisi = 0;
        List<QueryDocumentSnapshot> gosterilecekMasalar = [];

        if (snapshot.hasData) {
          var tumMasalar = snapshot.data!.docs;
          bosSayisi = tumMasalar.where((m) => (m.data() as Map)["durum"] == "bos").length;
          doluSayisi = tumMasalar.length - bosSayisi;

          gosterilecekMasalar = tumMasalar.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data["masaNo"].toString().contains(aramaKriteri);
          }).toList();
        }

        return Scaffold(
          backgroundColor: const Color(0xffFAF7F2),
          appBar: AppBar(
            backgroundColor: const Color(0xff6D4C41),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Masa Yönetimi",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),

            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    appBarIstatistik("Boş Masalar", bosSayisi),
                    const VerticalDivider(color: Colors.white24, thickness: 1, indent: 10, endIndent: 10),
                    appBarIstatistik("Dolu Masalar", doluSayisi),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(18),
                child: TextField(
                  onChanged: (value) => setState(() => aramaKriteri = value),
                  decoration: InputDecoration(
                    hintText: "Masa numarası ara...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : gosterilecekMasalar.isEmpty
                    ? const Center(child: Text("Sonuç bulunamadı."))
                    : ListView.builder(
                  itemCount: gosterilecekMasalar.length,
                  itemBuilder: (context, i) {
                    var masa = gosterilecekMasalar[i];
                    var masaData = masa.data() as Map<String, dynamic>;
                    String mevcutDurum = masaData["durum"] ?? "bos";

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Colors.black12)
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: mevcutDurum == "bos" ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              Icons.table_restaurant,
                              color: mevcutDurum == "bos" ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Masa ${masaData['masaNo']}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  mevcutDurum == "bos" ? "Müsait" : "Dolu",
                                  style: TextStyle(
                                    color: mevcutDurum == "bos" ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            onPressed: () => _masaSil(context, masa.id, mevcutDurum),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.brown,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Yeni Masa Ekle", style: TextStyle(color: Colors.white)),
              onPressed: () => _yeniMasaDialog(context),
            ),
          ),
        );
      },
    );
  }

  void _yeniMasaDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 30,
          right: 30,
          top: 30,
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Yeni Masa Oluştur", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.table_restaurant),
                hintText: "Masa numarası girin",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _masaEkle(int.parse(controller.text));
                  Navigator.pop(context);
                }
              },
              child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}