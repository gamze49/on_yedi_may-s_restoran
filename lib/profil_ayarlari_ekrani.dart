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

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);
  static const Color _kremZemin = Color(0xFFFAF7F2);

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
    if (_yeniSifreController.text.isEmpty || _yeniSifreController.text.length < 6) {
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
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _basariMesajiGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kremZemin,
      appBar: AppBar(
        title: const Text("Hesap Ayarları"),
        backgroundColor: _anaKahve,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _anaKahve))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: _anaKahve.withOpacity(0.1),
                        child: Icon(Icons.person_outline, size: 42, color: _anaKahve),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _mevcutAd.toUpperCase(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _koyuKahve,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _anaKahve.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _mevcutRol.toUpperCase(),
                          style: TextStyle(
                            color: _anaKahve,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),


              _bolumBaslik("Kimlik Doğrulama", Icons.shield_outlined),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade400, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Değişiklikler için mevcut şifrenizi girin",
                          style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _inputAlani(
                      controller: _eskiSifreController,
                      label: "Mevcut Şifreniz",
                      ikon: Icons.lock_outline,
                      obscure: true,
                      borderColor: Colors.red.shade200,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),


              _bolumBaslik("E-posta Değiştir", Icons.email_outlined),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.brown.shade100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _inputAlani(
                        controller: _yeniEmailController,
                        label: "Yeni E-posta",
                        ikon: Icons.alternate_email,
                        keyboard: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _epostaGuncelle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _anaKahve,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Güncelle", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.brown.shade100),
              const SizedBox(height: 20),


              _bolumBaslik("Şifre Değiştir", Icons.vpn_key_outlined),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.brown.shade100),
                ),
                child: Column(
                  children: [
                    _inputAlani(
                      controller: _yeniSifreController,
                      label: "Yeni Şifre (en az 6 karakter)",
                      ikon: Icons.vpn_key_outlined,
                      obscure: true,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _sifreGuncelle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _koyuKahve,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.lock_reset, size: 18),
                      label: const Text(
                        "Yalnızca Şifreyi Güncelle",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bolumBaslik(String baslik, IconData ikon) {
    return Row(
      children: [
        Icon(ikon, size: 18, color: _anaKahve),
        const SizedBox(width: 8),
        Text(
          baslik,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _koyuKahve,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _inputAlani({
    required TextEditingController controller,
    required String label,
    required IconData ikon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    Color? borderColor,
  }) {
    final Color border = borderColor ?? Colors.brown.shade100;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14, color: _koyuKahve),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.brown.shade400, fontSize: 13),
        prefixIcon: Icon(ikon, color: _anaKahve, size: 19),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _anaKahve, width: 1.5)),
      ),
    );
  }
}