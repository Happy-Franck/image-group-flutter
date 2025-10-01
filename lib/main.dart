import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Datasetup App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<File> _images = [];
  late Directory datasetupDir;

  @override
  void initState() {
    super.initState();
    _initDatasetupFolder();
  }

  // Crée ou récupère le dossier datasetup
  Future<void> _initDatasetupFolder() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    datasetupDir = Directory('${appDocDir.path}/datasetup');

    if (!(await datasetupDir.exists())) {
      await datasetupDir.create(recursive: true);
    }

    _loadImages();
  }

  // Charger les images déjà présentes dans datasetup
  void _loadImages() {
    final List<FileSystemEntity> files = datasetupDir.listSync();
    setState(() {
      _images = files.map((file) => File(file.path)).toList();
    });
  }

  // Ouvrir la galerie et ajouter des images
  Future<void> _pickAndSaveImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (XFile file in pickedFiles) {
        final newFile =
            await File(file.path).copy('${datasetupDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      }
      _loadImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Datasetup"),
      ),
      body: _images.isEmpty
          ? const Center(child: Text("Aucune image pour le moment"))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 colonnes
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Image.file(
                  _images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndSaveImages,
        child: const Icon(Icons.add),
      ),
    );
  }
}
