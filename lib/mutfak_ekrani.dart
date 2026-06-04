import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'profil_ayarlari_ekrani.dart';

class MutfakEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid;
  const MutfakEkrani({
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
          Expanded(
            child: _siparisler(context),
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
                    "MUTFAK EKRANI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Aktif Siparişler",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
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
            icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white, size: 26),
            tooltip: "Hesap Ayarları",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilAyarlariEkrani(userUid: userUid),
              ),
            ),
          ),
        ),
        Positioned(
          top: 45,
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 26),
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
          return const Center(
            child: CircularProgressIndicator(color: _anaKahve),
          );
        }

        var siparisler = snapshot.data!.docs;

        if (siparisler.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.brown.shade200),
                const SizedBox(height: 12),
                Text(
                  "Bekleyen sipariş yok",
                  style: TextStyle(color: Colors.brown.shade300, fontSize: 16),
                ),
              ],
            ),
          );
        }

        double w = MediaQuery.of(context).size.width;
        int yanYanaKutu = 2;
        if (w > 700) yanYanaKutu = 3;
        if (w > 1000) yanYanaKutu = 4;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
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

  Widget _siparisCard(String id, String masaNo, String durum, List urunler) {
    final bool hazirlaniyor = durum == "hazirlaniyor";
    final Color durumRengi = hazirlaniyor ? Colors.blue.shade600 : const Color(0xFFFFB300);
    final Color durumArkaRengi = hazirlaniyor ? Colors.blue.shade50 : Colors.orange.shade50;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: durumRengi.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: durumArkaRengi,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_restaurant_outlined, size: 16, color: _koyuKahve),
                    const SizedBox(width: 5),
                    Text(
                      "Masa $masaNo",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _koyuKahve,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: durumRengi,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    durum == "hazirlaniyor" ? "Hazırlanıyor" : "Yeni Sipariş",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                child: Column(
                  children: urunler.map<Widget>((u) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.brown.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    u["ad"] ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.brown.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "x${u["adet"]}",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: _anaKahve,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
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
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.local_fire_department, size: 14),
                    label: const Text("Hazırla", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
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
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text("Hazır", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}