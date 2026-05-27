import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'profil_ayarlari_ekrani.dart';

class MutfakEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid; // EKLENDİ
  const MutfakEkrani({
    super.key,
    required this.personelAdi,
    required this.userUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _siparisler(context),
            ),
          ),
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
        Container(
          height: 130,
          color: Colors.black54,
        ),
        const SafeArea(
          child: Center(
            child: Text(
              "MUTFAK EKRANI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Hesap Ayarları butonu (sol)
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
                  userUid: userUid, // DÜZELTME: artık doğru uid geçiliyor
                ),
              ),
            ),
          ),
        ),

        // Çıkış butonu (sağ)
        Positioned(
          top: 45,
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.power_settings_new,
                color: Colors.white, size: 28),
            tooltip: "Çıkış Yap",
            onPressed: () => AuthServis.isimliCikisYap(context, personelAdi),
          ),
        ),
      ],
    );
  }

  Widget _siparisler(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("siparisler")
          .where("durum", whereIn: ["SiparisAlindi", "hazirlaniyor"])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var siparisler = snapshot.data!.docs;

        if (siparisler.isEmpty) {
          return const Center(child: Text("Sipariş yok"));
        }

        double w = MediaQuery.of(context).size.width;
        int yanYanaKutu = 2;
        if (w > 700) yanYanaKutu = 3;
        if (w > 1000) yanYanaKutu = 4;

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: yanYanaKutu,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: siparisler.length,
          itemBuilder: (context, i) {
            var siparis = siparisler[i];
            var data = siparis.data() as Map<String, dynamic>;
            return _siparisCard(
              siparis.id,
              data["masaNo"] ?? "",
              data["durum"] ?? "",
              data["urunler"] ?? [],
            );
          },
        );
      },
    );
  }

  Widget _siparisCard(
      String id,
      String masaNo,
      String durum,
      List urunler,
      ) {
    Color renk = durum == "hazirlaniyor" ? Colors.blue : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Masa $masaNo",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: renk,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  durum,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: urunler.map<Widget>((u) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          u["ad"] ?? "",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "x${u["adet"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("siparisler")
                        .doc(id)
                        .update({"durum": "hazirlaniyor"});
                    await FirebaseFirestore.instance
                        .collection("masalar")
                        .doc(masaNo)
                        .update({"durum": "hazirlaniyor"});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text("Hazırla", style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("siparisler")
                        .doc(id)
                        .update({"durum": "hazir"});
                    await FirebaseFirestore.instance
                        .collection("masalar")
                        .doc(masaNo)
                        .update({"durum": "hazir"});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text("Hazır", style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}