import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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

enum SortOption { nameAsc, nameDesc, countAsc, countDesc }
enum ViewOption { list, grid }

// Page d'accueil : liste des dossiers dans "Datasetup"
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Directory datasetupDir;
  List<Directory> folders = [];
  SortOption _sortOption = SortOption.nameAsc;
  ViewOption _viewOption = ViewOption.list;

  @override
  void initState() {
    super.initState();
    _initDatasetupFolder();
  }

  Future<void> _initDatasetupFolder() async {
    if (!await _requestPermission()) return;

    datasetupDir = Directory('/storage/emulated/0/Datasetup');
    if (!await datasetupDir.exists()) {
      await datasetupDir.create(recursive: true);
    }
    _loadFolders();
  }

  Future<bool> _requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission stockage refusée")),
      );
      return false;
    }
  }

  void _loadFolders() {
    final List<FileSystemEntity> entities = datasetupDir.listSync();
    folders = entities.whereType<Directory>().toList();
    _sortFolders();
  }

  int _countImages(Directory folder) {
    final List<FileSystemEntity> files = folder.listSync();
    return files.whereType<File>().length;
  }

  void _sortFolders() {
    setState(() {
      switch (_sortOption) {
        case SortOption.nameAsc:
          folders.sort((a, b) =>
              a.path.split('/').last.toLowerCase().compareTo(b.path.split('/').last.toLowerCase()));
          break;
        case SortOption.nameDesc:
          folders.sort((a, b) =>
              b.path.split('/').last.toLowerCase().compareTo(a.path.split('/').last.toLowerCase()));
          break;
        case SortOption.countAsc:
          folders.sort((a, b) => _countImages(a).compareTo(_countImages(b)));
          break;
        case SortOption.countDesc:
          folders.sort((a, b) => _countImages(b).compareTo(_countImages(a)));
          break;
      }
    });
  }

  Future<void> _createFolder() async {
    String folderName = '';
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Créer un dossier"),
            content: TextField(
              onChanged: (value) {
                folderName = value;
              },
              decoration: const InputDecoration(hintText: "Nom du dossier"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () {
                  if (folderName.isNotEmpty) {
                    Navigator.pop(context, folderName);
                  }
                },
                child: const Text("Créer"),
              ),
            ],
          );
        });

    if (folderName.isNotEmpty) {
      final newDir = Directory('${datasetupDir.path}/$folderName');
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
        _loadFolders();
      }
    }
  }

  void _changeSort(SortOption option) {
    _sortOption = option;
    _sortFolders();
  }

  void _toggleView() {
    setState(() {
      _viewOption = _viewOption == ViewOption.list ? ViewOption.grid : ViewOption.list;
    });
  }

  Widget _buildFolderCard(Directory folder) {
    final imageCount = _countImages(folder);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const Icon(Icons.folder, size: 40, color: Colors.deepPurple),
        title: Text(folder.path.split('/').last,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text("$imageCount image${imageCount > 1 ? 's' : ''}"),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderPage(folder: folder),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Datasetup"),
        actions: [
          IconButton(
            icon: Icon(_viewOption == ViewOption.list ? Icons.grid_view : Icons.view_list),
            onPressed: _toggleView,
          ),
          PopupMenuButton<SortOption>(
            onSelected: _changeSort,
            itemBuilder: (context) => [
              const PopupMenuItem(value: SortOption.nameAsc, child: Text("Nom A→Z")),
              const PopupMenuItem(value: SortOption.nameDesc, child: Text("Nom Z→A")),
              const PopupMenuItem(value: SortOption.countAsc, child: Text("Nombre images ↑")),
              const PopupMenuItem(value: SortOption.countDesc, child: Text("Nombre images ↓")),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: folders.isEmpty
          ? const Center(child: Text("Aucun dossier pour le moment"))
          : _viewOption == ViewOption.list
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: folders.length,
                  itemBuilder: (context, index) => _buildFolderCard(folders[index]),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final imageCount = _countImages(folder);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderPage(folder: folder),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder, size: 40, color: Colors.deepPurple),
                              const SizedBox(height: 8),
                              Text(folder.path.split('/').last,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text("$imageCount image${imageCount > 1 ? 's' : ''}"),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFolder,
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }
}

// Page pour gérer un dossier spécifique : ajouter/déplacer/supprimer images
class FolderPage extends StatefulWidget {
  final Directory folder;
  const FolderPage({super.key, required this.folder});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<File> images = [];
  final Set<File> selectedImages = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void _loadImages() {
    final List<FileSystemEntity> files = widget.folder.listSync();
    setState(() {
      images = files.whereType<File>().toList();
      selectedImages.clear();
    });
  }

  Future<void> _pickAndMoveImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (XFile file in pickedFiles) {
        final newFile = File(
            '${widget.folder.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
        await File(file.path).copy(newFile.path);
        await File(file.path).delete();
      }
      _loadImages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Images ajoutées avec succès !")),
      );
    }
  }

  void _deleteSelectedImages() async {
    for (File file in selectedImages) {
      if (await file.exists()) {
        await file.delete();
      }
    }
    _loadImages();
  }

  void _openImageViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _onImageLongPress(File file) {
    setState(() {
      if (selectedImages.contains(file)) {
        selectedImages.remove(file);
      } else {
        selectedImages.add(file);
      }
    });
  }

  bool _isSelected(File file) => selectedImages.contains(file);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.path.split('/').last),
        actions: selectedImages.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedImages,
                )
              ]
            : null,
      ),
      body: images.isEmpty
          ? const Center(child: Text("Aucune image dans ce dossier"))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final file = images[index];
                final selected = _isSelected(file);
                return GestureDetector(
                  onLongPress: () => _onImageLongPress(file),
                  onTap: () {
                    if (selectedImages.isNotEmpty) {
                      _onImageLongPress(file);
                    } else {
                      _openImageViewer(index);
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(file, fit: BoxFit.cover),
                      if (selected)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndMoveImages,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Page de visualisation des images avec zoom et balayage
class ImageViewer extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  const ImageViewer({super.key, required this.images, required this.initialIndex});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int currentIndex;
  final transformationControllers = <int, TransformationController>{};

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    for (var controller in transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _getController(int index) {
    if (!transformationControllers.containsKey(index)) {
      transformationControllers[index] = TransformationController();
    }
    return transformationControllers[index]!;
  }

  void _handleDoubleTap(int index) {
    final controller = _getController(index);
    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
    } else {
      controller.value = Matrix4.identity()..scale(3.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onDoubleTap: () => _handleDoubleTap(index),
            child: Center(
              child: InteractiveViewer(
                transformationController: _getController(index),
                panEnabled: true,
                minScale: 1.0,
                maxScale: 5.0,
                child: Image.file(widget.images[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}
