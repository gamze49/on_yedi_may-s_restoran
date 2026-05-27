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

  final Color anaKahve = const Color(0xFF8B5A2B);

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

      var kontrol = await _db.collection("kullanici")
          .where("email", isEqualTo: email.trim())
          .get();

      if (kontrol.docs.isNotEmpty) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bu e-posta adresi zaten kullanımda!")),
          );
        }
        debugPrint("Bu e-posta adresi zaten kullanımda!");
        return;
      }


      UserCredential user = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: sifre);

      String resimUrl = "";
      if (resim != null) {
        resimUrl = await _resimYukle(resim, user.user!.uid);
      }

      await _db.collection("kullanici").doc(user.user!.uid).set({
        "ad": ad,
        "role": role,
        "email": email,
        "sifre": sifre,
        "uid": user.user!.uid,
        "resimUrl": resimUrl,
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
      if (yeniResim != null) {
        resimUrl = await _resimYukle(yeniResim, uid);
      }
      await _db.collection("kullanici").doc(uid).update({
        "ad": ad,
        "role": role,
        "email": yeniEmail,
        "sifre": yeniSifre,
        "resimUrl": resimUrl
      });
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
      backgroundColor: const  Color(0xffFAF7F2),
      appBar: AppBar(
        title: const Text("Personel Yönetimi"),
        backgroundColor: const Color(0xff6D4C41),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: anaKahve,
        onPressed: () => _personelEkleDialog(context),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("kullanici").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          Map<String, List<QueryDocumentSnapshot>> kategoriler = {};
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String rol = (data['role'] ?? "DİĞER").toString().toUpperCase();
            if (rol != "ADMIN") {
              if (!kategoriler.containsKey(rol)) kategoriler[rol] = [];
              kategoriler[rol]!.add(doc);
            }
          }

          if (kategoriler.isEmpty) return const Center(child: Text("Henüz personel bulunmuyor."));

          return ListView(
            children: kategoriler.keys.map((kategoriAd) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.grey[300],
                    child: Text(kategoriAd, style: TextStyle(fontWeight: FontWeight.bold, color: anaKahve)),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: anaKahve.withOpacity(0.1),
          backgroundImage: resimUrl.isNotEmpty ? NetworkImage(resimUrl) : null,
          child: resimUrl.isEmpty ? Icon(Icons.person, color: anaKahve) : null,
        ),
        title: Text(ad, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("${veri['role'] ?? ""} - $email"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _personelGuncelleDialog(context, doc.id, ad, veri['role'] ?? "garson", resimUrl, email, sifre),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
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
          title: const Text("Yeni Personel Ekle"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    File? resim = await _resimSec();
                    if (resim != null) setState(() => secilenResim = resim);
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: secilenResim != null ? FileImage(secilenResim!) : null,
                    child: secilenResim == null ? const Icon(Icons.camera_alt, size: 30) : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(onChanged: (v) => ad = v, decoration: const InputDecoration(labelText: "Ad Soyad")),

                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: "Personel Rolü"),
                  items: const [
                    DropdownMenuItem(value: "garson", child: Text("Garson")),
                    DropdownMenuItem(value: "kasa", child: Text("Kasa")),
                    DropdownMenuItem(value: "mutfak", child: Text("Mutfak")),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),

                TextField(onChanged: (v) => email = v, decoration: const InputDecoration(labelText: "E-posta")),
                TextField(onChanged: (v) => sifre = v, decoration: const InputDecoration(labelText: "Şifre"), obscureText: true),

                const SizedBox(height: 10),
                const Divider(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Güvenlik Sorusu (Şifre sıfırlama için)",
                    style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: guvenlikSorusu,
                  decoration: const InputDecoration(
                    labelText: "Güvenlik Sorusu",
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: sorular.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => guvenlikSorusu = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => guvenlikCevabi = v,
                  decoration: const InputDecoration(
                    labelText: "Güvenlik Sorusu Cevabı",
                    hintText: "Küçük harfle yazılması önerilir",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                await _personelEkle(ad, role, email, sifre, secilenResim, guvenlikSorusu, guvenlikCevabi);
                if (mounted) Navigator.pop(context);
              },
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
          title: const Text("Personel Güncelle"),
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
                    backgroundImage: yeniResim != null
                        ? FileImage(yeniResim!)
                        : (eskiResim.isNotEmpty ? NetworkImage(eskiResim) : null) as ImageProvider?,
                    child: (yeniResim == null && eskiResim.isEmpty) ? const Icon(Icons.camera_alt) : null,
                  ),
                ),
                TextField(
                  controller: TextEditingController(text: eskiAd),
                  onChanged: (v) => yeniAd = v,
                  decoration: const InputDecoration(labelText: "Ad"),
                ),
                TextField(
                  controller: TextEditingController(text: eskiEmail),
                  onChanged: (v) => yeniEmail = v,
                  decoration: const InputDecoration(labelText: "E-posta"),
                ),
                TextField(
                  controller: TextEditingController(text: eskiSifre),
                  onChanged: (v) => yeniSifre = v,
                  decoration: const InputDecoration(labelText: "Şifre"),
                ),
                DropdownButtonFormField<String>(
                  value: ["garson", "kasa", "mutfak"].contains(yeniRole) ? yeniRole : "garson",
                  decoration: const InputDecoration(labelText: "Rol"),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                await _personelGuncelle(uid, yeniAd, yeniRole, yeniEmail, yeniSifre, yeniResim, eskiResim);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Güncelle"),
            )
          ],
        );
      }),
    );
  }
}