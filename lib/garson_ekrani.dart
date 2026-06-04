import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'siparis_ekrani.dart';
import 'profil_ayarlari_ekrani.dart';

class GarsonEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid;
  const GarsonEkrani({
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
      appBar: AppBar(
        title: const Text(
          '508 RESTORAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: _anaKahve,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white, size: 24),
            tooltip: "Hesap Ayarları",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilAyarlariEkrani(userUid: userUid),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white, size: 24),
            tooltip: "Çıkış Yap",
            onPressed: () => AuthServis.isimliCikisYap(context, personelAdi),
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _koyuKahve,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Hoş geldin, $personelAdi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Text(
                  'MASALAR',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('masalar')
                  .orderBy('masaNo')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Hata oluştu"));
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _anaKahve),
                  );
                }

                var masalar = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: masalar.length,
                  itemBuilder: (context, index) {
                    var masaVerisi = masalar[index].data() as Map<String, dynamic>;
                    var masaId = masalar[index].id;
                    String durum = masaVerisi['durum'] ?? 'bos';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SiparisEkrani(
                              masaId: masaId,
                              garsonAdi: personelAdi,
                            ),
                          ),
                        );
                      },
                      child: _masaKarti(masaId, durum),
                    );
                  },
                );
              },
            ),
          ),

          // Alt durum göstergesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _durumAnahtari(Colors.brown.shade200, 'Boş'),
                _durumAnahtari(const Color(0xFFFFB300), 'Sipariş Alındı'),
                _durumAnahtari(Colors.blue.shade300, 'Hazırlanıyor'),
                _durumAnahtari(Colors.green.shade400, 'Hazır'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _masaKarti(String masaId, String durum) {
    Color kartRengi = masaRengiGetir(durum);

    return Container(
      decoration: BoxDecoration(
        color: kartRengi,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kartRengi.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_bar_outlined,
            size: 32,
            color: Colors.white.withOpacity(0.95),
          ),
          const SizedBox(height: 6),
          Text(
            "Masa $masaId",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            masaKontrol(durum),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _durumAnahtari(Color renk, String etiket) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: renk,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          etiket,
          style: TextStyle(
            fontSize: 10,
            color: Colors.brown.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

String masaKontrol(String durum) {
  if (durum == 'SiparisAlindi') return "Sipariş alındı";
  if (durum == 'bos') return "Boş";
  if (durum == 'odendi') return "Boş";
  if (durum == 'hazirlaniyor') return "Hazırlanıyor";
  if (durum == 'hazir') return "Hazır";
  return "Dolu";
}

Color masaRengiGetir(String durum) {
  if (durum == 'bos') return const Color(0xFFA1887F);
  if (durum == 'SiparisAlindi') return const Color(0xFFFFB300);
  if (durum == 'odendi') return const Color(0xFFA1887F);
  if (durum == 'hazirlaniyor') return Colors.blue.shade400;
  if (durum == 'hazir') return Colors.green.shade500;
  return Colors.red.shade400;
}