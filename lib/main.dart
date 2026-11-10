import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  runApp(const MyApp());
}

/// Root widget of the Image Editor app.
class MyApp extends StatelessWidget {
  /// Creates a new [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Home page: the user picks a photo and opens the editor.
class HomePage extends StatefulWidget {
  /// Creates a new [HomePage] widget.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      final File file = File(image.path);
      if (!mounted) return;
      await precacheImage(FileImage(file), context);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _buildEditor(file)),
      );
    } catch (e) {
      _showMessage('تعذر فتح الصورة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(Uint8List bytes) async {
    try {
      final bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImageBytes(
        bytes,
        name: 'image_editor_${DateTime.now().millisecondsSinceEpoch}',
      );
      _showMessage('تم حفظ الصورة في المعرض');
    } catch (e) {
      _showMessage('تعذر حفظ الصورة');
    }
  }

  Widget _buildEditor(File file) {
    final GlobalKey<ProImageEditorState> editorKey =
        GlobalKey<ProImageEditorState>();

    return ProImageEditor.file(
      file,
      key: editorKey,
      configs: const ProImageEditorConfigs(),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          await _save(bytes);
        },
        onCloseEditor: (EditorMode editorMode) {
          editorKey.currentState?.isPopScopeDisabled = true;
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined, size: 88),
                  const SizedBox(height: 16),
                  const Text(
                    'Image Editor',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر صورة وابدأ التعديل',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  if (_busy)
                    const CircularProgressIndicator()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('اختيار صورة من المعرض'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('التقاط صورة بالكاميرا'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
