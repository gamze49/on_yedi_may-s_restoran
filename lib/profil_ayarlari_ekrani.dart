import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_servis.dart';

class ProfilAyarlariEkrani extends StatefulWidget {
  final String userUid;

  const ProfilAyarlariEkrani({super.key, required this.userUid});

  @override
  State<ProfilAyarlariEkrani> createState() => _ProfilAyarlariEkraniState();
}

class _ProfilAyarlariEkraniState extends State<ProfilAyarlariEkrani> {
  final _formKey = GlobalKey<FormState>();

  final _eskiSifreController = TextEditingController();
  final _yeniEmailController = TextEditingController();
  final _yeniSifreController = TextEditingController();

  bool _yukleniyor = false;
  String _mevcutAd = "";
  String _mevcutRol = "";
  String _mevcutEmail = "";

  @override
  void initState() {
    super.initState();
    _profilVerileriniGetir();
  }

  @override
  void dispose() {
    _eskiSifreController.dispose();
    _yeniEmailController.dispose();
    _yeniSifreController.dispose();
    super.dispose();
  }

  Future<void> _profilVerileriniGetir() async {
    setState(() => _yukleniyor = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("kullanici")
          .doc(widget.userUid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _mevcutEmail = doc['email'] ?? "";
          _yeniEmailController.text = _mevcutEmail;
          _mevcutAd = doc['ad'] ?? "";
          _mevcutRol = doc['role'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Profil verisi çekilirken hata: $e");
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _epostaGuncelle() async {
    if (_eskiSifreController.text.isEmpty) {
      _hataMesajiGoster("Lütfen önce 'Mevcut Şifreniz' alanını doldurun.");
      return;
    }
    if (!_yeniEmailController.text.contains("@")) {
      _hataMesajiGoster("Geçerli bir e-posta adresi giriniz.");
      return;
    }
    if (_yeniEmailController.text.trim() == _mevcutEmail) {
      _hataMesajiGoster("Yeni e-posta adresi eskisinden farklı olmalıdır.");
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      await AuthServis.sadeceEpostaGuncelle(
        userUid: widget.userUid,
        mevcutSifre: _eskiSifreController.text.trim(),
        yeniEmail: _yeniEmailController.text.trim(),
      );
      _basariMesajiGoster("E-posta adresiniz başarıyla güncellendi!");
      _profilVerileriniGetir();
      _eskiSifreController.clear();
    } catch (e) {
      _hataMesajiGoster(e.toString().replaceAll("Exception:", "").trim());
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _sifreGuncelle() async {
    if (_eskiSifreController.text.isEmpty) {
      _hataMesajiGoster("Lütfen önce 'Mevcut Şifreniz' alanını doldurun.");
      return;
    }
    if (_yeniSifreController.text.isEmpty ||
        _yeniSifreController.text.length < 6) {
      _hataMesajiGoster("Yeni şifre en az 6 karakter olmalıdır.");
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      await AuthServis.sadeceSifreGuncelle(
        userUid: widget.userUid,
        mevcutSifre: _eskiSifreController.text.trim(),
        yeniSifre: _yeniSifreController.text.trim(),
      );
      _basariMesajiGoster("Şifreniz başarıyla güncellendi!");
      _yeniSifreController.clear();
      _eskiSifreController.clear();
    } catch (e) {
      _hataMesajiGoster(e.toString().replaceAll("Exception:", "").trim());
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  void _hataMesajiGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: Colors.red),
    );
  }

  void _basariMesajiGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hesap Ayarları"),
        backgroundColor: Colors.brown.shade300,
        foregroundColor: Colors.white,
      ),
      body: _yukleniyor
          ? const Center(
          child: CircularProgressIndicator(color: Colors.brown))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.brown.shade100,
                  child: Icon(Icons.person,
                      size: 40, color: Colors.brown.shade700),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _mevcutAd.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  "Rol: ${_mevcutRol.toUpperCase()}",
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              // 1. Kimlik Onayı
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("1. Kimlik Onayı (Zorunlu)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _eskiSifreController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Mevcut (eski) şifrenizi giriniz",
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Colors.red),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 2. E-posta güncelleme
              const Text("E-posta Adresini Değiştir",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yeniEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _epostaGuncelle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade400,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Güncelle",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const Divider(height: 40, thickness: 1.2),

              // 3. Şifre güncelleme
              const Text("Yeni Şifre Belirle",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _yeniSifreController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Yeni şifre (en az 6 karakter)",
                  prefixIcon:
                  const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _sifreGuncelle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "Yalnızca Şifreyi Güncelle",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}