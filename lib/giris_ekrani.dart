import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_panel_ekrani.dart';
import 'garson_ekrani.dart';
import 'mutfak_ekrani.dart';
import 'kasa_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
        String userUid = doc.id; // Firestore doküman ID'sini alıyoruz

        if (rol == "garson") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GarsonEkrani(
                personelAdi: ad,
                userUid: userUid,
              ),
            ),
          );
        } else if (rol == "mutfak") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MutfakEkrani(
                personelAdi: ad,
                userUid: userUid,
              ),
            ),
          );
        } else if (rol == "kasa") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => KasaEkrani(
                personelAdi: ad,
                userUid: userUid,
              ),
            ),
          );
        } else if (rol == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPanelEkrani(
                personelAdi: ad,
                userUid: userUid,
              ),
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
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: KavisKesici(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/girisekranifoto.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'KOLAY GELSİN 😊',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: login,
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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