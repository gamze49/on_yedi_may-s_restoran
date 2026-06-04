import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SifreSifirlamaEkrani extends StatefulWidget {
  const SifreSifirlamaEkrani({super.key});

  @override
  State<SifreSifirlamaEkrani> createState() => _SifreSifirlamaEkraniState();
}

class _SifreSifirlamaEkraniState extends State<SifreSifirlamaEkrani> {
  int _adim = 1;
  bool _yukleniyor = false;

  final _emailController = TextEditingController();
  final _cevapController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();

  String _bulunanDocId = "";
  String _guvenlikSorusu = "";

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);

  @override
  void dispose() {
    _emailController.dispose();
    _cevapController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    super.dispose();
  }

  Future<void> _emailKontrol() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      _hataGoster("Geçerli bir e-posta adresi giriniz.");
      return;
    }
    setState(() => _yukleniyor = true);
    try {
      var sonuc = await FirebaseFirestore.instance
          .collection("kullanici")
          .where("email", isEqualTo: email)
          .get();

      if (sonuc.docs.isEmpty) {
        _hataGoster("Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.");
        return;
      }

      var doc = sonuc.docs.first;
      var veri = doc.data();
      String soru = veri["guvenlikSorusu"] ?? "";

      if (soru.isEmpty) {
        _hataGoster("Bu hesap için güvenlik sorusu tanımlanmamış.");
        return;
      }

      setState(() {
        _bulunanDocId = doc.id;
        _guvenlikSorusu = soru;
        _adim = 2;
      });
    } catch (e) {
      _hataGoster("Bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _cevapKontrol() async {
    String girilenCevap = _cevapController.text.trim().toLowerCase();
    if (girilenCevap.isEmpty) {
      _hataGoster("Lütfen cevabı giriniz.");
      return;
    }
    setState(() => _yukleniyor = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("kullanici")
          .doc(_bulunanDocId)
          .get();
      var veri = doc.data() as Map<String, dynamic>;
      String dogruCevap = (veri["guvenlikCevabi"] ?? "").toString().trim().toLowerCase();
      if (girilenCevap != dogruCevap) {
        _hataGoster("Cevap yanlış! Tekrar deneyin.");
        return;
      }
      setState(() => _adim = 3);
    } catch (e) {
      _hataGoster("Bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _sifreyiGuncelle() async {
    String yeniSifre = _yeniSifreController.text.trim();
    String tekrar = _yeniSifreTekrarController.text.trim();
    if (yeniSifre.length < 6) {
      _hataGoster("Şifre en az 6 karakter olmalıdır.");
      return;
    }
    if (yeniSifre != tekrar) {
      _hataGoster("Şifreler eşleşmiyor!");
      return;
    }
    setState(() => _yukleniyor = true);
    try {
      await FirebaseFirestore.instance
          .collection("kullanici")
          .doc(_bulunanDocId)
          .update({"sifre": yeniSifre});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Şifreniz başarıyla güncellendi!"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _hataGoster("Şifre güncellenirken hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _hataGoster(String mesaj) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text("Şifremi Unuttum"),
        backgroundColor: _anaKahve,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _adimGostergesi(),
            const SizedBox(height: 32),
            if (_adim == 1) _adim1Widget(),
            if (_adim == 2) _adim2Widget(),
            if (_adim == 3) _adim3Widget(),
          ],
        ),
      ),
    );
  }

  Widget _adimGostergesi() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _adimDairesi(1, "E-posta"),
          _adimCizgisi(_adim > 1),
          _adimDairesi(2, "Doğrulama"),
          _adimCizgisi(_adim > 2),
          _adimDairesi(3, "Yeni Şifre"),
        ],
      ),
    );
  }

  Widget _adimDairesi(int numara, String etiket) {
    bool aktif = _adim >= numara;
    bool tamamlandi = _adim > numara;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: aktif ? _anaKahve : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: aktif
                ? [BoxShadow(color: _anaKahve.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Center(
            child: tamamlandi
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
              "$numara",
              style: TextStyle(
                color: aktif ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          etiket,
          style: TextStyle(
            fontSize: 11,
            color: aktif ? _anaKahve : Colors.grey,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _adimCizgisi(bool tamamlandi) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22, left: 6, right: 6),
        decoration: BoxDecoration(
          color: tamamlandi ? _anaKahve : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _adim1Widget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("E-posta Adresiniz", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _koyuKahve)),
        const SizedBox(height: 8),
        Text(
          "Sisteme kayıtlı e-posta adresinizi girin. Güvenlik sorunuz gösterilecek.",
          style: TextStyle(color: Colors.brown.shade400, fontSize: 13),
        ),
        const SizedBox(height: 24),
        _styledInput(_emailController, "E-posta Adresi", Icons.email_outlined, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _anaButen("Devam Et", _yukleniyor ? null : _emailKontrol, _yukleniyor),
      ],
    );
  }

  Widget _adim2Widget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Güvenlik Sorusu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _koyuKahve)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.brown.shade100),
            boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _anaKahve.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.help_outline_rounded, color: _anaKahve, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _guvenlikSorusu,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _koyuKahve),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _styledInput(_cevapController, "Cevabınız", Icons.lock_outline),
        const SizedBox(height: 20),
        _anaButen("Doğrula", _yukleniyor ? null : _cevapKontrol, _yukleniyor),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() { _adim = 1; _cevapController.clear(); }),
          icon: Icon(Icons.arrow_back, size: 16, color: _anaKahve),
          label: Text("Geri Dön", style: TextStyle(color: _anaKahve, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _adim3Widget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Yeni Şifre Belirle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _koyuKahve)),
        const SizedBox(height: 8),
        Text("En az 6 karakterden oluşan yeni şifrenizi girin.", style: TextStyle(color: Colors.brown.shade400, fontSize: 13)),
        const SizedBox(height: 24),
        _styledInput(_yeniSifreController, "Yeni Şifre", Icons.vpn_key_outlined, obscure: true),
        const SizedBox(height: 14),
        _styledInput(_yeniSifreTekrarController, "Yeni Şifre (Tekrar)", Icons.vpn_key_outlined, obscure: true),
        const SizedBox(height: 20),
        _anaButen("Şifremi Güncelle", _yukleniyor ? null : _sifreyiGuncelle, _yukleniyor, color: Colors.green.shade600),
      ],
    );
  }

  Widget _styledInput(TextEditingController c, String label, IconData ikon,
      {bool obscure = false, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14, color: _koyuKahve),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.brown.shade400),
        prefixIcon: Icon(ikon, color: _anaKahve, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.brown.shade100)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.brown.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _anaKahve, width: 1.5)),
      ),
    );
  }

  Widget _anaButen(String etiket, VoidCallback? onTap, bool yukleniyor, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? _anaKahve,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: (color ?? _anaKahve).withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: yukleniyor
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(etiket, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}