import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'list_screen.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  // Backup local configuration in case backend initialization is in progress
  List<dynamic> stores = [
    {"name": "YOGA SUPER MART", "imageUrl": "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500"},
    {"name": "YOGA SAREES", "imageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=500"},
    {"name": "YOGA SILKS", "imageUrl": "https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=500"}
  ];

  @override
  void initState() {
    super.initState();
    _loadStoresData();
  }

  void _loadStoresData() async {
    var cloudStores = await ApiService.getStores();
    if (cloudStores.isNotEmpty) {
      setState(() { stores = cloudStores; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoga Group of Stores', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: stores.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, 
            childAspectRatio: 1.6, 
            mainAxisSpacing: 16
          ),
          itemBuilder: (context, index) {
            final targetStore = stores[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ListScreen(storeName: targetStore['name']))
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        targetStore['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.store, size: 50)),
                      ),
                    ),
                    Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),
                    Center(
                      child: Text(
                        targetStore['name'],
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}