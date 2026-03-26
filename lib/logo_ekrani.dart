import 'dart:async';
import 'package:flutter/material.dart';
import 'giris_ekrani.dart';

class LogoEkrani extends StatefulWidget {
  const LogoEkrani({super.key});

  @override
  State<LogoEkrani> createState() => _LogoEkraniState();
}

class _LogoEkraniState extends State<LogoEkrani> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GirisEkrani()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6E5),
     body: Column(
       children: [
         Expanded(child: Row(
           children: [
             Expanded(child: Image.asset(
               'assets/images/restoranuygulamasi.png',
             // fit: BoxFit.fill,
             ))
           ],
         ))
       ],
     ),
    );
  }
}
