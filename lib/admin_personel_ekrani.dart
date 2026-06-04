import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PersonelYonetimSayfasi extends StatefulWidget {
  const PersonelYonetimSayfasi({super.key});

  @override
  State<PersonelYonetimSayfasi> createState() => _PersonelYonetimSayfasiState();
}

class _PersonelYonetimSayfasiState extends State<PersonelYonetimSayfasi> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);
  static const Color _kremZemin = Color(0xFFFAF7F2);

  Future<File?> _resimSec() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    return image != null ? File(image.path) : null;
  }

  Future<String> _resimYukle(File file, String uid) async {
    try {
      Reference ref = _storage.ref().child("personel_resimleri/$uid.jpg");
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return "";
    }
  }

  Future<void> _personelEkle(String ad, String role, String email, String sifre, File? resim, String guvenlikSorusu, String guvenlikCevabi) async {
    try {
      var kontrol = await _db.collection("kullanici").where("email", isEqualTo: email.trim()).get();
      if (kontrol.docs.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu e-posta adresi zaten kullanımda!")));
        return;
      }

      UserCredential user = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: sifre);
      String resimUrl = "";
      if (resim != null) resimUrl = await _resimYukle(resim, user.user!.uid);

      await _db.collection("kullanici").doc(user.user!.uid).set({
        "ad": ad, "role": role, "email": email, "sifre": sifre,
        "uid": user.user!.uid, "resimUrl": resimUrl,
        "guvenlikSorusu": guvenlikSorusu,
        "guvenlikCevabi": guvenlikCevabi.trim().toLowerCase(),
        "olusturmaTarihi": FieldValue.serverTimestamp()
      });

      await _auth.signInWithEmailAndPassword(email: "admin@gmail.com", password: "admin_sifren");
    } catch (e) {
      debugPrint("Ekleme Hatası: $e");
    }
  }

  Future<void> _personelGuncelle(String uid, String ad, String role, String yeniEmail, String yeniSifre, File? yeniResim, String eskiResim) async {
    try {
      String resimUrl = eskiResim;
      if (yeniResim != null) resimUrl = await _resimYukle(yeniResim, uid);
      await _db.collection("kullanici").doc(uid).update({"ad": ad, "role": role, "email": yeniEmail, "sifre": yeniSifre, "resimUrl": resimUrl});
    } catch (e) {
      debugPrint("Güncelleme Hatası: $e");
    }
  }

  Future<void> _personelSil(String uid) async {
    try {
      await _db.collection("kullanici").doc(uid).delete();
    } catch (e) {
      debugPrint("Silme Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kremZemin,
      appBar: AppBar(
        title: const Text("Personel Yönetimi", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _anaKahve,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _anaKahve,
        onPressed: () => _personelEkleDialog(context),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text("Personel Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("kullanici").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _anaKahve));

          Map<String, List<QueryDocumentSnapshot>> kategoriler = {};
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String rol = (data['role'] ?? "DİĞER").toString().toUpperCase();
            if (rol != "ADMIN") {
              if (!kategoriler.containsKey(rol)) kategoriler[rol] = [];
              kategoriler[rol]!.add(doc);
            }
          }

          if (kategoriler.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.brown.shade200),
                  const SizedBox(height: 12),
                  Text("Henüz personel bulunmuyor.", style: TextStyle(color: Colors.brown.shade300, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            children: kategoriler.keys.map((kategoriAd) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.brown.shade50,
                    child: Row(
                      children: [
                        Container(width: 3, height: 14, decoration: BoxDecoration(color: _anaKahve, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text(
                          kategoriAd,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _anaKahve, letterSpacing: 1.0),
                        ),
                        const SizedBox(width: 8),
                        Text("${kategoriler[kategoriAd]!.length} kişi", style: TextStyle(fontSize: 11, color: Colors.brown.shade400)),
                      ],
                    ),
                  ),
                  ...kategoriler[kategoriAd]!.map((doc) => _personelSatiri(doc)).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _personelSatiri(QueryDocumentSnapshot doc) {
    var veri = doc.data() as Map<String, dynamic>;
    String ad = veri['ad'] ?? "İsimsiz";
    String resimUrl = (veri.containsKey('resimUrl')) ? veri['resimUrl'] : "";
    String email = veri['email'] ?? "";
    String sifre = veri['sifre'] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _anaKahve.withOpacity(0.1),
          backgroundImage: resimUrl.isNotEmpty ? NetworkImage(resimUrl) : null,
          child: resimUrl.isEmpty ? Icon(Icons.person_outline, color: _anaKahve, size: 22) : null,
        ),
        title: Text(ad, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _koyuKahve)),
        subtitle: Text(
          "${veri['role']?.toString().toUpperCase() ?? ""} • $email",
          style: TextStyle(fontSize: 11, color: Colors.brown.shade400),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 20),
              onPressed: () => _personelGuncelleDialog(context, doc.id, ad, veri['role'] ?? "garson", resimUrl, email, sifre),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
              onPressed: () => _personelSil(doc.id),
            ),
          ],
        ),
      ),
    );
  }

  void _personelEkleDialog(BuildContext context) {
    String ad = "", role = "garson", email = "", sifre = "";
    String guvenlikSorusu = "İlk evcil hayvanınızın adı neydi?";
    String guvenlikCevabi = "";
    File? secilenResim;

    final List<String> sorular = [
      "İlk evcil hayvanınızın adı neydi?",
      "Annenizin kızlık soyadı nedir?",
      "İlk okul öğretmeninizin adı neydi?",
      "Doğduğunuz şehir neresidir?",
      "En sevdiğiniz çocukluk arkadaşınızın adı neydi?",
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.person_add_outlined, color: _anaKahve),
              const SizedBox(width: 8),
              Text("Yeni Personel Ekle", style: TextStyle(color: _koyuKahve, fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    File? resim = await _resimSec();
                    if (resim != null) setState(() => secilenResim = resim);
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: _anaKahve.withOpacity(0.1),
                    backgroundImage: secilenResim != null ? FileImage(secilenResim!) : null,
                    child: secilenResim == null
                        ? Icon(Icons.add_a_photo_outlined, size: 28, color: _anaKahve)
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                _dialogInput2((v) => ad = v, "Ad Soyad", Icons.person_outline),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: _dropdownDeco("Personel Rolü", Icons.badge_outlined),
                  items: const [
                    DropdownMenuItem(value: "garson", child: Text("Garson")),
                    DropdownMenuItem(value: "kasa", child: Text("Kasa")),
                    DropdownMenuItem(value: "mutfak", child: Text("Mutfak")),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),
                const SizedBox(height: 8),
                _dialogInput2((v) => email = v, "E-posta", Icons.email_outlined, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 8),
                _dialogInput2((v) => sifre = v, "Şifre", Icons.lock_outline, obscure: true),
                const SizedBox(height: 12),
                Divider(color: Colors.brown.shade100),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Güvenlik Sorusu", style: TextStyle(fontSize: 12, color: _anaKahve, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: guvenlikSorusu,
                  isExpanded: true,
                  decoration: _dropdownDeco("Güvenlik Sorusu", Icons.help_outline),
                  items: sorular.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => guvenlikSorusu = v!),
                ),
                const SizedBox(height: 8),
                _dialogInput2((v) => guvenlikCevabi = v, "Güvenlik Cevabı", Icons.key_outlined),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("İptal", style: TextStyle(color: Colors.brown.shade400))),
            ElevatedButton(
              onPressed: () async {
                await _personelEkle(ad, role, email, sifre, secilenResim, guvenlikSorusu, guvenlikCevabi);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _anaKahve, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Kaydet"),
            )
          ],
        );
      }),
    );
  }

  void _personelGuncelleDialog(BuildContext context, String uid, String eskiAd, String eskiRole, String eskiResim, String eskiEmail, String eskiSifre) {
    String yeniAd = eskiAd;
    String yeniRole = eskiRole.toLowerCase();
    String yeniEmail = eskiEmail;
    String yeniSifre = eskiSifre;
    File? yeniResim;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Personel Güncelle", style: TextStyle(color: _koyuKahve, fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    File? resim = await _resimSec();
                    if (resim != null) setState(() => yeniResim = resim);
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: _anaKahve.withOpacity(0.1),
                    backgroundImage: yeniResim != null
                        ? FileImage(yeniResim!)
                        : (eskiResim.isNotEmpty ? NetworkImage(eskiResim) : null) as ImageProvider?,
                    child: (yeniResim == null && eskiResim.isEmpty) ? Icon(Icons.camera_alt_outlined, color: _anaKahve) : null,
                  ),
                ),
                const SizedBox(height: 12),
                _dialogInput2Controller(TextEditingController(text: eskiAd), (v) => yeniAd = v, "Ad", Icons.person_outline),
                const SizedBox(height: 8),
                _dialogInput2Controller(TextEditingController(text: eskiEmail), (v) => yeniEmail = v, "E-posta", Icons.email_outlined),
                const SizedBox(height: 8),
                _dialogInput2Controller(TextEditingController(text: eskiSifre), (v) => yeniSifre = v, "Şifre", Icons.lock_outline),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: ["garson", "kasa", "mutfak"].contains(yeniRole) ? yeniRole : "garson",
                  decoration: _dropdownDeco("Rol", Icons.badge_outlined),
                  items: const [
                    DropdownMenuItem(value: "garson", child: Text("Garson")),
                    DropdownMenuItem(value: "kasa", child: Text("Kasa")),
                    DropdownMenuItem(value: "mutfak", child: Text("Mutfak")),
                  ],
                  onChanged: (v) => setState(() => yeniRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("İptal", style: TextStyle(color: Colors.brown.shade400))),
            ElevatedButton(
              onPressed: () async {
                await _personelGuncelle(uid, yeniAd, yeniRole, yeniEmail, yeniSifre, yeniResim, eskiResim);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _anaKahve, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Güncelle"),
            )
          ],
        );
      }),
    );
  }

  Widget _dialogInput2(Function(String) onChange, String label, IconData ikon,
      {bool obscure = false, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      onChanged: onChange,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 13, color: _koyuKahve),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.brown.shade400, fontSize: 12),
        prefixIcon: Icon(ikon, color: _anaKahve, size: 17),
        filled: true,
        fillColor: const Color(0xFFFAF7F2),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.brown.shade100)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.brown.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _anaKahve, width: 1.5)),
      ),
    );
  }

  Widget _dialogInput2Controller(TextEditingController controller, Function(String) onChange, String label, IconData ikon) {
    return TextField(
      controller: controller,
      onChanged: onChange,
      style: TextStyle(fontSize: 13, color: _koyuKahve),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.brown.shade400, fontSize: 12),
        prefixIcon: Icon(ikon, color: _anaKahve, size: 17),
        filled: true,
        fillColor: const Color(0xFFFAF7F2),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.brown.shade100)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.brown.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _anaKahve, width: 1.5)),
      ),
    );
  }

  InputDecoration _dropdownDeco(String label, IconData ikon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.brown.shade400, fontSize: 12),
      prefixIcon: Icon(ikon, color: _anaKahve, size: 17),
      filled: true,
      fillColor: const Color(0xFFFAF7F2),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.brown.shade100)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.brown.shade100)),
    );
  }
}