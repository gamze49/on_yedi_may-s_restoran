import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SifreSifirlamaEkrani extends StatefulWidget {
  const SifreSifirlamaEkrani({super.key});

  @override
  State<SifreSifirlamaEkrani> createState() => _SifreSifirlamaEkraniState();
}

class _SifreSifirlamaEkraniState extends State<SifreSifirlamaEkrani> {
  // Adım: 1 = e-posta, 2 = güvenlik sorusu, 3 = yeni şifre
  int _adim = 1;
  bool _yukleniyor = false;

  final _emailController = TextEditingController();
  final _cevapController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();

  // Bulunan kullanıcı bilgileri
  String _bulunanDocId = "";
  String _guvenlikSorusu = "";

  @override
  void dispose() {
    _emailController.dispose();
    _cevapController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    super.dispose();
  }

  // ADIM 1: E-posta ile kullanıcıyı bul ve güvenlik sorusunu getir
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
        _hataGoster("Bu hesap için güvenlik sorusu tanımlanmamış. Lütfen yöneticinizle iletişime geçin.");
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

  // ADIM 2: Güvenlik sorusu cevabını kontrol et
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

  // ADIM 3: Yeni şifreyi kaydet
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
          const SnackBar(
            content: Text("Şifreniz başarıyla güncellendi!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Giriş ekranına geri dön
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
      SnackBar(content: Text(mesaj), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text("Şifremi Unuttum"),
        backgroundColor: Colors.brown.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adım göstergesi
            _adimGostergesi(),
            const SizedBox(height: 30),

            // Adıma göre içerik
            if (_adim == 1) _adim1Widget(),
            if (_adim == 2) _adim2Widget(),
            if (_adim == 3) _adim3Widget(),
          ],
        ),
      ),
    );
  }

  Widget _adimGostergesi() {
    return Row(
      children: [
        _adimDairesi(1, "E-posta"),
        _adimCizgisi(_adim > 1),
        _adimDairesi(2, "Doğrulama"),
        _adimCizgisi(_adim > 2),
        _adimDairesi(3, "Yeni Şifre"),
      ],
    );
  }

  Widget _adimDairesi(int numara, String etiket) {
    bool aktif = _adim >= numara;
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: aktif ? Colors.brown : Colors.grey.shade300,
          child: Text(
            "$numara",
            style: TextStyle(
              color: aktif ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          etiket,
          style: TextStyle(
            fontSize: 11,
            color: aktif ? Colors.brown : Colors.grey,
            fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _adimCizgisi(bool tamamlandi) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: tamamlandi ? Colors.brown : Colors.grey.shade300,
      ),
    );
  }

  // --- ADIM 1: E-posta girişi ---
  Widget _adim1Widget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "E-posta Adresiniz",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Sisteme kayıtlı e-posta adresinizi girin. Size ait güvenlik sorusu gösterilecektir.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "E-posta",
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.brown),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _yukleniyor ? null : _emailKontrol,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _yukleniyor
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text("Devam Et", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // --- ADIM 2: Güvenlik sorusu ---
  Widget _adim2Widget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Güvenlik Sorusu",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.brown.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _guvenlikSorusu,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _cevapController,
          decoration: InputDecoration(
            labelText: "Cevabınız",
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.brown),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _yukleniyor ? null : _cevapKontrol,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _yukleniyor
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text("Doğrula", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _adim = 1;
            _cevapController.clear();
          }),
          child: const Text("← Geri Dön", style: TextStyle(color: Colors.brown)),
        ),
      ],
    );
  }

  // --- ADIM 3: Yeni şifre belirleme ---
  Widget _adim3Widget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Yeni Şifre Belirle",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "En az 6 karakterden oluşan yeni şifrenizi girin.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _yeniSifreController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Yeni Şifre",
            prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.brown),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _yeniSifreTekrarController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Yeni Şifre (Tekrar)",
            prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.brown),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _yukleniyor ? null : _sifreyiGuncelle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _yukleniyor
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text("Şifremi Güncelle", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}