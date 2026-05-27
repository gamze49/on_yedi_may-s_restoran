import 'package:flutter/material.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'admin_menu_ekrani.dart';
import 'ciro_ekrani.dart';
import 'admin_masa_ekle_sil.dart';
import 'admin_personel_ekrani.dart';
import 'profil_ayarlari_ekrani.dart';

class AdminPanelEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid; // EKLENDİ
  const AdminPanelEkrani({
    super.key,
    required this.personelAdi,
    required this.userUid,
  });

  @override
  Widget build(BuildContext context) {
    const Color zeminRengi = Color(0xFFFAF8F5);
    const Color anaKahve = Color(0xFF8B5A2B);
    const Color koyuKahve = Color(0xFF5D3A1A);

    return Scaffold(
      backgroundColor: zeminRengi,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: anaKahve,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.manage_accounts, color: Colors.white),
                tooltip: "Hesap Ayarları",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilAyarlariEkrani(
                      userUid: userUid, // DÜZELTME: uid geçiriliyor
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.white),
                tooltip: "Çıkış Yap",
                onPressed: () =>
                    AuthServis.isimliCikisYap(context, personelAdi),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "YÖNETİM MERKEZİ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    "assets/images/restoran.jpg",
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          koyuKahve.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 20,
                        decoration: BoxDecoration(
                          color: anaKahve,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "HIZLI ERİŞİM PANELLERİ",
                        style: TextStyle(
                          color: koyuKahve,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
              ),
              delegate: SliverChildListSnapshotDelegate([
                _premiumAdminCard(context, "MENÜ\nYÖNETİMİ",
                    Icons.restaurant_menu_outlined,
                    const AdminMenuEkrani(), anaKahve, koyuKahve),
                _premiumAdminCard(context, "CİRO\nRAPORU",
                    Icons.auto_graph_outlined,
                    const CiroEkrani(), anaKahve, koyuKahve),
                _premiumAdminCard(context, "MASA\nYÖNETİMİ",
                    Icons.grid_view_rounded,
                    const MasaYonetimEkrani(), anaKahve, koyuKahve),
                _premiumAdminCard(context, "PERSONEL\nYÖNETİMİ",
                    Icons.badge_outlined,
                    const PersonelYonetimSayfasi(), anaKahve, koyuKahve),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _premiumAdminCard(BuildContext context, String baslik, IconData ikon,
      Widget? sayfa, Color anaKahve, Color koyuKahve) {
    return GestureDetector(
      onTap: () {
        if (sayfa != null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => sayfa));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: koyuKahve.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: anaKahve.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(ikon, color: anaKahve, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              baslik,
              style: TextStyle(
                  color: koyuKahve,
                  fontSize: 13,
                  fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverChildListSnapshotDelegate extends SliverChildDelegate {
  final List<Widget> children;
  const SliverChildListSnapshotDelegate(this.children);

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= children.length) return null;
    return children[index];
  }

  @override
  int? get childCount => children.length;

  @override
  bool shouldRebuild(covariant SliverChildDelegate oldDelegate) => true;
}