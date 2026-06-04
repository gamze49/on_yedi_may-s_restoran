import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MasaYonetimEkrani extends StatefulWidget {
  const MasaYonetimEkrani({super.key});

  @override
  State<MasaYonetimEkrani> createState() => _MasaYonetimEkraniState();
}

class _MasaYonetimEkraniState extends State<MasaYonetimEkrani> {
  String aramaKriteri = "";

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);
  static const Color _kremZemin = Color(0xFFFAF7F2);

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
        SnackBar(
          content: const Text("Bu masa şu an aktif! Önce masayı boşaltmalısınız."),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    await FirebaseFirestore.instance.collection("masalar").doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Masa başarıyla silindi."),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
          backgroundColor: _kremZemin,
          appBar: AppBar(
            backgroundColor: _anaKahve,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "Masa Yönetimi",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _istatistikKutu("Boş", bosSayisi, Colors.green.shade300),
                    Container(width: 1, height: 36, color: Colors.white24),
                    _istatistikKutu("Dolu", doluSayisi, Colors.orange.shade300),
                    Container(width: 1, height: 36, color: Colors.white24),
                    _istatistikKutu("Toplam", bosSayisi + doluSayisi, Colors.white70),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  onChanged: (value) => setState(() => aramaKriteri = value),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Masa numarası ara...",
                    hintStyle: TextStyle(color: Colors.brown.shade300),
                    prefixIcon: Icon(Icons.search, color: Colors.brown.shade400, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.brown.shade100),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator(color: _anaKahve))
                    : gosterilecekMasalar.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_restaurant_outlined, size: 50, color: Colors.brown.shade200),
                      const SizedBox(height: 10),
                      Text("Sonuç bulunamadı.", style: TextStyle(color: Colors.brown.shade300)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: gosterilecekMasalar.length,
                  itemBuilder: (context, i) {
                    var masa = gosterilecekMasalar[i];
                    var masaData = masa.data() as Map<String, dynamic>;
                    String mevcutDurum = masaData["durum"] ?? "bos";
                    bool bos = mevcutDurum == "bos";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: bos ? Colors.green.shade100 : Colors.orange.shade100,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                            color: Colors.brown.withOpacity(0.07),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: bos ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.table_restaurant_outlined,
                              color: bos ? Colors.green.shade600 : Colors.orange.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Masa ${masaData['masaNo']}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _koyuKahve,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: bos ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    bos ? "Müsait" : "Dolu",
                                    style: TextStyle(
                                      color: bos ? Colors.green.shade700 : Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
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
              backgroundColor: _anaKahve,
              elevation: 3,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Yeni Masa Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onPressed: () => _yeniMasaDialog(context),
            ),
          ),
        );
      },
    );
  }

  Widget _istatistikKutu(String baslik, int sayi, Color renk) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$sayi",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: renk),
        ),
        Text(baslik, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ],
    );
  }

  void _yeniMasaDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 28, right: 28, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            Text("Yeni Masa Oluştur",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _koyuKahve)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(fontSize: 15, color: _koyuKahve),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.table_restaurant_outlined, color: _anaKahve),
                hintText: "Masa numarası girin",
                hintStyle: TextStyle(color: Colors.brown.shade300),
                filled: true,
                fillColor: const Color(0xFFFAF7F2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.brown.shade100)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.brown.shade100)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _anaKahve, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _anaKahve,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _masaEkle(int.parse(controller.text));
                  Navigator.pop(context);
                }
              },
              child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}