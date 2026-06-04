import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_panel_ekrani.dart';
import 'garson_ekrani.dart';
import 'mutfak_ekrani.dart';
import 'kasa_ekrani.dart';
import 'sifre_sifirlama_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _sifreGoster = false;

  Future<void> login() async {
    String email = emailController.text.trim();
    String sifre = passwordController.text.trim();

    if (email.isEmpty || sifre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    try {
      var sonuc = await FirebaseFirestore.instance
          .collection("kullanici")
          .where("email", isEqualTo: email)
          .where("sifre", isEqualTo: sifre)
          .get();

      if (sonuc.docs.isNotEmpty) {
        var doc = sonuc.docs.first;
        var veri = doc.data();
        String rol = veri['role'] ?? "";
        String ad = veri['ad'] ?? "Personel";
        String userUid = doc.id;

        if (rol == "garson") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GarsonEkrani(personelAdi: ad, userUid: userUid),
            ),
          );
        } else if (rol == "mutfak") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MutfakEkrani(personelAdi: ad, userUid: userUid),
            ),
          );
        } else if (rol == "kasa") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => KasaEkrani(personelAdi: ad, userUid: userUid),
            ),
          );
        } else if (rol == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPanelEkrani(personelAdi: ad, userUid: userUid),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tanımsız kullanıcı rolü!")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hatalı e-posta veya şifre!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Giriş hatası oluştu: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color anaKahve = Color(0xFF6D4C41);
    const Color koyuKahve = Color(0xFF4E342E);
    const Color kremZemin = Color(0xFFFAF7F2);

    return Scaffold(
      backgroundColor: kremZemin,
      body: SingleChildScrollView(
        child: Column(
          children: [

            ClipPath(
              clipper: KavisKesici(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/girisekranifoto.jpeg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xCC4E342E),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş Geldiniz',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: koyuKahve,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lütfen hesabınıza giriş yapın.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.brown.shade300,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _inputAlani(
                    controller: emailController,
                    label: 'E-posta',
                    ikon: Icons.email_outlined,
                    anaKahve: anaKahve,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: passwordController,
                    obscureText: !_sifreGoster,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      labelStyle: TextStyle(color: Colors.brown.shade400),
                      prefixIcon: Icon(Icons.lock_outline, color: anaKahve, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sifreGoster ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.brown.shade300,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _sifreGoster = !_sifreGoster),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.brown.shade100),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.brown.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: anaKahve, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: anaKahve,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: anaKahve.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SifreSifirlamaEkrani(),
                          ),
                        );
                      },
                      child: Text(
                        'Şifremi Unuttum',
                        style: TextStyle(
                          color: anaKahve,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: anaKahve,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputAlani({
    required TextEditingController controller,
    required String label,
    required IconData ikon,
    required Color anaKahve,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.brown.shade400),
        prefixIcon: Icon(ikon, color: anaKahve, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.brown.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.brown.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: anaKahve, width: 1.5),
        ),
      ),
    );
  }
}

class KavisKesici extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var kontrolNoktasi = Offset(size.width / 2, size.height);
    var bitisNoktasi = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
        kontrolNoktasi.dx, kontrolNoktasi.dy, bitisNoktasi.dx, bitisNoktasi.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}