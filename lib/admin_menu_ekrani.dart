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
  String _secilenKategori = "Ana Yemek";
  final List<String> _kategoriler = ["Salata", "Ana Yemek", "Çorbalar", "Tatlı", "İçecek"];

  static const Color _anaKahve = Color(0xFF6D4C41);
  static const Color _koyuKahve = Color(0xFF4E342E);
  static const Color _kremZemin = Color(0xFFFAF7F2);

  Future<void> _resimSec() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _secilenDosya = File(image.path));
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
      backgroundColor: _kremZemin,
      appBar: AppBar(
        title: const Text("Menü Yönetimi", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _anaKahve,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [

          Container(
            color: _anaKahve,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: TextField(
              onChanged: (val) => setState(() => _aramaMetni = val.toLowerCase()),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ürün ara...",
                hintStyle: TextStyle(color: Colors.brown.shade300),
                prefixIcon: Icon(Icons.search, color: Colors.brown.shade400, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: _menuListesi()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _yeniUrunEkleSheet(context),
        backgroundColor: _anaKahve,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ürün Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _menuListesi() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("menu").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _anaKahve));

        var filtrelenmisUrunler = snapshot.data!.docs.where((doc) {
          String urunAdi = (doc["ad"] ?? "").toString().toLowerCase();
          return urunAdi.contains(_aramaMetni);
        }).toList();

        Map<String, List<QueryDocumentSnapshot>> gruplanmis = {};
        for (var doc in filtrelenmisUrunler) {
          String kategori = doc["kategori"] ?? "Diğer";
          if (!gruplanmis.containsKey(kategori)) gruplanmis[kategori] = [];
          gruplanmis[kategori]!.add(doc);
        }

        if (filtrelenmisUrunler.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 50, color: Colors.brown.shade200),
                const SizedBox(height: 10),
                Text("Ürün bulunamadı.", style: TextStyle(color: Colors.brown.shade300)),
              ],
            ),
          );
        }

        return ListView(
          children: gruplanmis.keys.map((kategoriAdi) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.brown.shade50,
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(color: _anaKahve, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        kategoriAdi.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _anaKahve,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${gruplanmis[kategoriAdi]!.length} ürün",
                        style: TextStyle(fontSize: 11, color: Colors.brown.shade400),
                      ),
                    ],
                  ),
                ),
                ...gruplanmis[kategoriAdi]!.map((urunDoc) {
                  var data = urunDoc.data() as Map<String, dynamic>;
                  int stok = (data["stok"] ?? 0) is int ? (data["stok"] ?? 0) : (data["stok"] as num).toInt();
                  bool stokTakibi = data["stokTakibiAktif"] ?? false;
                  bool tukenmisMi = stokTakibi && stok <= 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: (data["resimUrl"] != null && data["resimUrl"] != "")
                            ? Image.network(
                          data["resimUrl"],
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.brown.shade50,
                            child: Icon(Icons.fastfood_outlined, color: Colors.brown.shade300, size: 24),
                          ),
                        )
                            : Container(
                          width: 52,
                          height: 52,
                          color: Colors.brown.shade50,
                          child: Icon(Icons.fastfood_outlined, color: Colors.brown.shade300, size: 24),
                        ),
                      ),
                      title: Text(
                        data["ad"] ?? "İsimsiz",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _koyuKahve),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            "${data["fiyat"]} ₺",
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          if (stokTakibi)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tukenmisMi ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: tukenmisMi ? Colors.red.shade200 : Colors.green.shade200),
                              ),
                              child: Text(
                                tukenmisMi ? "TÜKENDİ" : "Stok: $stok",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: tukenmisMi ? Colors.red.shade600 : Colors.green.shade700,
                                ),
                              ),
                            ),
                          if (!stokTakibi)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("Sınırsız", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 20),
                            onPressed: () => _urunDuzenleDialog(context, urunDoc.id, data["ad"] ?? "", data["fiyat"], stok, stokTakibi),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                            onPressed: () => _urunSilOnay(context, urunDoc.id, data["resimUrl"]),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 6),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade500),
            const SizedBox(width: 8),
            const Text("Ürünü Sil", style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text("Bu ürünü menüden kaldırmak istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("İptal", style: TextStyle(color: Colors.brown.shade400))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("menu").doc(id).delete();
              if (resimUrl != null && resimUrl.isNotEmpty) {
                try { await FirebaseStorage.instance.refFromURL(resimUrl).delete(); } catch (e) {}
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  void _urunDuzenleDialog(BuildContext context, String id, String eskiAd, dynamic eskiFiyat, int eskiStok, bool eskiStokTakibi) {
    TextEditingController adController = TextEditingController(text: eskiAd);
    TextEditingController fiyatController = TextEditingController(text: eskiFiyat.toString());
    TextEditingController stokController = TextEditingController(text: eskiStok.toString());
    bool stokTakibi = eskiStokTakibi;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text("Ürünü Güncelle", style: TextStyle(color: _koyuKahve, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogInput(adController, "Ürün Adı", Icons.fastfood_outlined),
                const SizedBox(height: 10),
                _dialogInput(fiyatController, "Fiyat (₺)", Icons.attach_money, keyboard: TextInputType.number),
                const SizedBox(height: 10),
                _dialogInput(stokController, "Ürün Stoğu", Icons.inventory_2_outlined, keyboard: TextInputType.number),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Stok Takibi", style: TextStyle(fontSize: 13)),
                  value: stokTakibi,
                  activeColor: _anaKahve,
                  onChanged: (v) => setState(() => stokTakibi = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("İptal", style: TextStyle(color: Colors.brown.shade400))),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection("menu").doc(id).update({
                  "ad": adController.text,
                  "fiyat": int.tryParse(fiyatController.text) ?? 0,
                  "stok": int.tryParse(stokController.text) ?? 0,
                  "stokTakibiAktif": stokTakibi,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _anaKahve, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Güncelle"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogInput(TextEditingController c, String label, IconData ikon, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14, color: _koyuKahve),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.brown.shade400, fontSize: 13),
        prefixIcon: Icon(ikon, color: _anaKahve, size: 18),
        filled: true,
        fillColor: const Color(0xFFFAF7F2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.brown.shade100)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.brown.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _anaKahve, width: 1.5)),
      ),
    );
  }

  void _yeniUrunEkleSheet(BuildContext context) {
    TextEditingController adController = TextEditingController();
    TextEditingController fiyatController = TextEditingController();
    TextEditingController stokController = TextEditingController(text: "0");
    bool stokTakibi = false;
    bool kaydediliyor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Text("Yeni Ürün Ekle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _koyuKahve)),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () async { await _resimSec(); setSheetState(() {}); },
                  child: Container(
                    height: 100, width: 100,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.brown.shade100, width: 2),
                    ),
                    child: _secilenDosya == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.brown.shade300),
                        const SizedBox(height: 4),
                        Text("Resim Seç", style: TextStyle(fontSize: 11, color: Colors.brown.shade400)),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_secilenDosya!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _dialogInput(adController, "Ürün Adı", Icons.fastfood_outlined),
                const SizedBox(height: 10),
                _dialogInput(fiyatController, "Fiyat (₺)", Icons.attach_money, keyboard: TextInputType.number),
                const SizedBox(height: 10),
                _dialogInput(stokController, "Ürün Stoğu", Icons.inventory_2_outlined, keyboard: TextInputType.number),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Stok Takibi Yapılsın mı?", style: TextStyle(fontSize: 13)),
                  subtitle: Text("Kapalıysa ürün tükenmez (Su, Çay gibi)", style: TextStyle(fontSize: 11, color: Colors.brown.shade400)),
                  value: stokTakibi,
                  activeColor: _anaKahve,
                  onChanged: (v) => setSheetState(() => stokTakibi = v),
                ),

                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _secilenKategori,
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    labelStyle: TextStyle(color: Colors.brown.shade400, fontSize: 13),
                    prefixIcon: Icon(Icons.category_outlined, color: _anaKahve, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFFAF7F2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.brown.shade100)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.brown.shade100)),
                  ),
                  items: _kategoriler.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (v) => setSheetState(() => _secilenKategori = v!),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _anaKahve,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: kaydediliyor ? null : () async {
                      if (adController.text.isNotEmpty && fiyatController.text.isNotEmpty && _secilenDosya != null) {
                        setSheetState(() => kaydediliyor = true);
                        try {
                          String indirilenUrl = await _resmiYukleVeUrlAl(_secilenDosya!);
                          await FirebaseFirestore.instance.collection("menu").add({
                            "ad": adController.text,
                            "fiyat": int.tryParse(fiyatController.text) ?? 0,
                            "kategori": _secilenKategori,
                            "resimUrl": indirilenUrl,
                            "aktif": true,
                            "stok": int.tryParse(stokController.text) ?? 0,
                            "stokTakibiAktif": stokTakibi,
                          });
                          setState(() => _secilenDosya = null);
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          setSheetState(() => kaydediliyor = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Lütfen tüm alanları doldurun ve resim seçin!"),
                            backgroundColor: Colors.orange.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: kaydediliyor
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text("KAYDET", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}