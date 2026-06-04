import 'package:flutter/material.dart';
import 'package:restoranuygulamasi/services/auth_servis.dart';
import 'admin_menu_ekrani.dart';
import 'ciro_ekrani.dart';
import 'admin_masa_ekle_sil.dart';
import 'admin_personel_ekrani.dart';
import 'profil_ayarlari_ekrani.dart';
import 'haftalik_tuketim_ekrani.dart';

class AdminPanelEkrani extends StatelessWidget {
  final String personelAdi;
  final String userUid;
  const AdminPanelEkrani({
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210.0,
            floating: false,
            pinned: true,
            backgroundColor: _anaKahve,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white),
                tooltip: "Hesap Ayarları",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilAyarlariEkrani(userUid: userUid),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.white),
                tooltip: "Çıkış Yap",
                onPressed: () => AuthServis.isimliCikisYap(context, personelAdi),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "YÖNETİM MERKEZİ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset("assets/images/restoran.jpg", fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          _koyuKahve.withOpacity(0.8),
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _anaKahve,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "HIZLI ERİŞİM",
                    style: TextStyle(
                      color: _koyuKahve,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListSnapshotDelegate([
                _adminKarti(
                  context,
                  baslik: "MENÜ\nYÖNETİMİ",
                  ikon: Icons.restaurant_menu_outlined,
                  sayfa: const AdminMenuEkrani(),
                  renk: const Color(0xFF5D4037),
                  acikRenk: const Color(0xFFF3E5F5),
                ),
                _adminKarti(
                  context,
                  baslik: "CİRO\nRAPORU",
                  ikon: Icons.auto_graph_outlined,
                  sayfa: const CiroEkrani(),
                  renk: const Color(0xFF2E7D32),
                  acikRenk: const Color(0xFFE8F5E9),
                ),
                _adminKarti(
                  context,
                  baslik: "MASA\nYÖNETİMİ",
                  ikon: Icons.grid_view_rounded,
                  sayfa: const MasaYonetimEkrani(),
                  renk: const Color(0xFF1565C0),
                  acikRenk: const Color(0xFFE3F2FD),
                ),
                _adminKarti(
                  context,
                  baslik: "PERSONEL\nYÖNETİMİ",
                  ikon: Icons.badge_outlined,
                  sayfa: const PersonelYonetimSayfasi(),
                  renk: const Color(0xFFE65100),
                  acikRenk: const Color(0xFFFFF3E0),
                ),
                _adminKarti(
                  context,
                  baslik: "HAFTALİK\nTÜKETİM",
                  ikon: Icons.bar_chart_outlined,
                  sayfa: const HaftalikTuketimEkrani(),
                  renk: const Color(0xFF00695C),
                  acikRenk: const Color(0xFFE0F2F1),
                ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _adminKarti(
      BuildContext context, {
        required String baslik,
        required IconData ikon,
        required Widget sayfa,
        required Color renk,
        required Color acikRenk,
      }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: renk.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: acikRenk,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, color: renk, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              baslik,
              style: TextStyle(
                color: _koyuKahve,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  "Aç",
                  style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: renk),
              ],
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