import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminMenuEkrani extends StatefulWidget {
  const AdminMenuEkrani({super.key});

  @override
  State<AdminMenuEkrani> createState() => _AdminMenuEkraniState();
}

class _AdminMenuEkraniState extends State<AdminMenuEkrani> {
  String _aramaMetni = "";
  File? _secilenDosya;
  final ImagePicker _picker = ImagePicker();

  Future<void> _resimSec() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _secilenDosya = File(image.path);
      });
    }
  }

  Future<String> _resmiYukleVeUrlAl(File dosya) async {
    String dosyaAdi = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child("menu_resimleri").child("$dosyaAdi.jpg");
    UploadTask yuklemeGorevi = ref.putFile(dosya);
    TaskSnapshot snapshot = await yuklemeGorevi;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Menü Yönetimi"),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Ürün ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (val) {
                setState(() {
                  _aramaMetni = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(child: _menuListesi()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _yeniUrunEkleSheet(context),
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _menuListesi() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("menu").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var urunDokumanlari = snapshot.data!.docs;

        var filtrelenmisUrunler = urunDokumanlari.where((doc) {
          String urunAdi = (doc["ad"] ?? "").toString().toLowerCase();
          return urunAdi.contains(_aramaMetni);
        }).toList();

        Map<String, List<QueryDocumentSnapshot>> gruplanmisUrunler = {};
        for (var doc in filtrelenmisUrunler) {
          String kategori = doc["kategori"] ?? "Diğer";
          if (!gruplanmisUrunler.containsKey(kategori)) {
            gruplanmisUrunler[kategori] = [];
          }
          gruplanmisUrunler[kategori]!.add(doc);
        }

        if (filtrelenmisUrunler.isEmpty) {
          return const Center(child: Text("Ürün bulunamadı."));
        }

        return ListView(
          children: gruplanmisUrunler.keys.map((kategoriAdi) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(kategoriAdi.toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                ),
                ...gruplanmisUrunler[kategoriAdi]!.map((urunDoc) {
                  var data = urunDoc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (data["resimUrl"] != null && data["resimUrl"] != "")
                            ? NetworkImage(data["resimUrl"])
                            : null,
                        child: (data["resimUrl"] == null || data["resimUrl"] == "")
                            ? const Icon(Icons.fastfood)
                            : null,
                      ),
                      title: Text(data["ad"] ?? "İsimsiz"),
                      subtitle: Text("${data["fiyat"]} TL"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _urunDuzenleDialog(context, urunDoc.id, data["ad"] ?? "", data["fiyat"]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _urunSilOnay(context, urunDoc.id, data["resimUrl"]),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const Divider(),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  void _urunSilOnay(BuildContext context, String id, String? resimUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ürünü Sil"),
        content: const Text("Bu ürünü menüden kaldırmak istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("menu").doc(id).delete();
              if (resimUrl != null && resimUrl.isNotEmpty) {
                try { await FirebaseStorage.instance.refFromURL(resimUrl).delete(); } catch (e) {}
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }

  void _urunDuzenleDialog(BuildContext context, String id, String eskiAd, dynamic eskiFiyat) {
    TextEditingController adController = TextEditingController(text: eskiAd);
    TextEditingController fiyatController = TextEditingController(text: eskiFiyat.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ürünü Güncelle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: adController, decoration: const InputDecoration(labelText: "Ürün Adı")),
            TextField(controller: fiyatController, decoration: const InputDecoration(labelText: "Fiyat"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection("menu").doc(id).update({
                "ad": adController.text,
                "fiyat": int.parse(fiyatController.text),
              });
              Navigator.pop(context);
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  void _yeniUrunEkleSheet(BuildContext context) {
    TextEditingController adController = TextEditingController();
    TextEditingController fiyatController = TextEditingController();
    TextEditingController kategoriController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Yeni Ürün Ekle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () async {
                  await _resimSec();
                  setSheetState(() {});
                },
                child: Container(
                  height: 100, width: 100,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                  child: _secilenDosya == null
                      ? const Icon(Icons.add_a_photo, size: 40)
                      : Image.file(_secilenDosya!, fit: BoxFit.cover),
                ),
              ),
              TextField(controller: adController, decoration: const InputDecoration(labelText: "Ürün Adı")),
              TextField(controller: fiyatController, decoration: const InputDecoration(labelText: "Fiyat"), keyboardType: TextInputType.number),
              TextField(controller: kategoriController, decoration: const InputDecoration(labelText: "Kategori")),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                onPressed: () async {
                  if (adController.text.isNotEmpty && _secilenDosya != null) {
                    String indirilenUrl = await _resmiYukleVeUrlAl(_secilenDosya!);
                    await FirebaseFirestore.instance.collection("menu").add({
                      "ad": adController.text,
                      "fiyat": int.parse(fiyatController.text),
                      "kategori": kategoriController.text,
                      "resimUrl": indirilenUrl,
                      "aktif": true,
                    });
                    setState(() { _secilenDosya = null; });
                    Navigator.pop(context);
                  }
                },
                child: const Text("KAYDET", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}