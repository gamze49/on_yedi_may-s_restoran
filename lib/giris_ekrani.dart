import 'dart:ffi' hide Size;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    try {

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("kullanici")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Firestore'da kullanıcı bulunamadı")),
        );
        return;
      }

      String rol = userDoc.get("role");
      if (rol == "garson") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GarsonEkrani()),
        );
      } else if (rol == "mutfak") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MutfakEkrani()),
        );
      } else if (rol == "kasa") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KasaEkrani()),
        );
      } else if (rol == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const YoneticiEkrani()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Giriş Hatası: ${e.message}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(//istediğim şekli çizebiliyourm bununla
              clipper: KavisKesici(),
              child: Container(
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/girisekranifoto.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'KOLAY GELSİN 😊',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        login();
                      },
                      child: Text(
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




class YoneticiEkrani extends StatelessWidget {
  const YoneticiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yönetici Paneli")),
      body: const Center(child: Text("Yönetici Ekranı")),
    );
  }
}

class KavisKesici extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var kontrolNoktasi = Offset(size.width / 2, size.height);
    var bitisNoktasi = Offset(size.width, size.height -50);
    path.quadraticBezierTo(//bulunduğum noktadan bitiş noktasıne eğilerek gittt!
    kontrolNoktasi.dx, kontrolNoktasi.dy,
    bitisNoktasi.dx, bitisNoktasi.dy
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;//bu clipper değişmeyecek tekrar çizmedemek
}
