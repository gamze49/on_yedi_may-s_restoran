import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HaftalikTuketimEkrani extends StatefulWidget {
  const HaftalikTuketimEkrani({super.key});

  @override
  State<HaftalikTuketimEkrani> createState() => _HaftalikTuketimEkraniState();
}

class _HaftalikTuketimEkraniState extends State<HaftalikTuketimEkrani> {
  static const Color _anaKahve  = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);
  static const Color _kremZemin = Color(0xFFFAF7F2);

  int _gunAraligi = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kremZemin,
      appBar: AppBar(
        title: const Text(
          "Tüketim Raporu",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: _anaKahve,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _aralikSecici(),
          Expanded(child: _raporIcerigi()),
        ],
      ),
    );
  }

  Widget _aralikSecici() {
    return Container(
      color: _anaKahve,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _aralikButon("Bugün", 1),
          const SizedBox(width: 10),
          _aralikButon("7 Gün", 7),
          const SizedBox(width: 10),
          _aralikButon("30 Gün", 30),
        ],
      ),
    );
  }

  Widget _aralikButon(String etiket, int gun) {
    bool secili = _gunAraligi == gun;
    return GestureDetector(
      onTap: () => setState(() => _gunAraligi = gun),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: secili ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          etiket,
          style: TextStyle(
            color: secili ? _anaKahve : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }


  Widget _raporIcerigi() {

    final DateTime sinir = DateTime.now().subtract(Duration(days: _gunAraligi));
    final Timestamp sinirTimestamp = Timestamp.fromDate(sinir);


    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("siparisler")
          .where("durum", isEqualTo: "odendi")
          .where("zaman", isGreaterThanOrEqualTo: sinirTimestamp)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _anaKahve));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _bosEkran();
        }


        Map<String, int> tuketim = {};

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          var urunler = data["urunler"];

          if (urunler is List) {
            for (var urun in urunler) {
              if (urun is Map) {
                String ad  = (urun["ad"] ?? "Bilinmiyor").toString();
                int   adet = (urun["adet"] as num?)?.toInt() ?? 1;
                tuketim[ad] = (tuketim[ad] ?? 0) + adet;
              }
            }
          }
        }

        if (tuketim.isEmpty) return _bosEkran();


        var sirali = tuketim.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        int toplamSatis = sirali.fold(0, (sum, e) => sum + e.value);
        int enCokSatis  = sirali.first.value;

        return Column(
          children: [
            _ozetKart(sirali.length, toplamSatis),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: sirali.length,
                itemBuilder: (context, i) => _urunSatiri(
                  sira:        i + 1,
                  ad:          sirali[i].key,
                  adet:        sirali[i].value,
                  enCok:       enCokSatis,
                  toplamSatis: toplamSatis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ozetKart(int urunSayisi, int toplamSatis) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E342E), Color(0xFF6D4C41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E342E).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ozetKutu("Toplam Satış", "$toplamSatis adet",
              Icons.shopping_bag_outlined),
          Container(width: 1, height: 40, color: Colors.white24),
          _ozetKutu("Farklı Ürün", "$urunSayisi çeşit",
              Icons.restaurant_menu_outlined),
          Container(width: 1, height: 40, color: Colors.white24),
          _ozetKutu(
            "Süre",
            _gunAraligi == 1 ? "Bugün" : "$_gunAraligi gün",
            Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _ozetKutu(String baslik, String deger, IconData ikon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, color: Colors.white60, size: 18),
        const SizedBox(height: 4),
        Text(deger,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        Text(baslik,
            style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }


  Widget _urunSatiri({
    required int sira,
    required String ad,
    required int adet,
    required int enCok,
    required int toplamSatis,
  }) {
    double yuzde      = enCok > 0 ? adet / enCok : 0;
    double yuzdeGenel = toplamSatis > 0 ? adet / toplamSatis * 100 : 0;

    Color barRenk;
    if (sira == 1)      barRenk = Colors.amber.shade600;
    else if (sira == 2) barRenk = Colors.blueGrey.shade400;
    else if (sira == 3) barRenk = Colors.brown.shade400;
    else                barRenk = _anaKahve.withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.brown.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [

              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: sira <= 3
                      ? barRenk.withOpacity(0.15)
                      : Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: sira == 1
                      ? Icon(Icons.emoji_events,
                      size: 16, color: Colors.amber.shade600)
                      : Text(
                    "$sira",
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: barRenk),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(ad,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _koyuKahve)),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: barRenk.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$adet adet",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: barRenk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              double barGenisligi =
                  constraints.maxWidth * yuzde.clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: barGenisligi,
                    decoration: BoxDecoration(
                      color: barRenk,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 4),
          Text(
            "Toplam satışın %${yuzdeGenel.toStringAsFixed(1)}'i",
            style: TextStyle(fontSize: 10, color: Colors.brown.shade400),
          ),
        ],
      ),
    );
  }


  Widget _bosEkran() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: Colors.brown.shade200),
          const SizedBox(height: 12),
          Text(
            "Bu dönemde satış verisi bulunamadı.",
            style: TextStyle(color: Colors.brown.shade300, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            "Farklı bir zaman aralığı seçebilirsiniz.",
            style: TextStyle(color: Colors.brown.shade200, fontSize: 12),
          ),
        ],
      ),
    );
  }
}