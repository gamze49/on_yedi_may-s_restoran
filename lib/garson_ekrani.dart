import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restoranuygulamasi/services/menu_servis_database.dart';
import 'services/database_service.dart';
import 'siparis_ekrani.dart';
import 'services/menu_servis_database.dart';

class GarsonEkrani extends StatelessWidget {
  const GarsonEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text(
          '508 RESTORAN MASALAR',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade200,
       /* actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await DatabaseService().ilkKurulumMasalariOlustur();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("40 Masa Başarıyla Kuruldu!")),
              );
            },
          )
        ],*/
        /*actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await MenuService().menuOlustur();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Menü oluştu!")),
              );
            },
          )
        ],*/
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('masalar').orderBy('masaNo').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Hata oluştu"));

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var masalar = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(//ızgaranın kaç sürun oalcağını belirler
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: masalar.length,
            itemBuilder: (context, index) {
              var masaVerisi = masalar[index].data() as Map<String, dynamic>;
              var masaId = masalar[index].id;
             // bool doluMu = masaVerisi['durum'] == "dolu";


              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SiparisEkrani(masaId: masaId),
                    ),
                  );
                },
                child: Card(
                  color: masaRengiGetir(masaVerisi['durum']),
                  // masaVerisi['durum']=="dolu"? Colors.red[300] : Colors.green[300],
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_bar, size: 40, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        "Masa $masaId" ,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        //doluMu ? "DOLU" : "BOŞ",
                        masaKontrol(masaVerisi['durum']),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
String masaKontrol(String durum)
{
  if(durum=='SiparisAlindi')
   { return "Sipariş alındı";}
  else if(durum=='bos')
  {  return "Bos";}
  else if(durum=='ödendi')
    {return "Bos";}
  else if(durum=='hazirlaniyor')
   { return "Hazırlanıyor";}
  else if (durum=='hazir');
      {return "Dolu";}

}
Color masaRengiGetir(String durum)
{
  if(durum=='bos')
    return Colors.brown.shade200!;
  else if(durum=='SiparisAlindi')
    return Colors.yellow[700]!;
  else if(durum=='ödendi')
    return Colors.brown.shade200!;
  else if(durum=='hazirlaniyor')
    return Colors.orange[300]!;
  else (durum=='hazir');
     return Colors.red[300]!;
}