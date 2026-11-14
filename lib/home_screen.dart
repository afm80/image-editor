import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'editor_controller.dart';
import 'editor_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  Future<void> _newProject() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    final ctrl = EditorController();
    try {
      await ctrl.addClipFromPath(picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر فتح الفيديو: $e')),
        );
      }
      ctrl.dispose();
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(controller: ctrl)),
    );
    ctrl.dispose();
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة قادمة في مرحلة لاحقة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        const Text('محرر الفيديو',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          onPressed: _soon,
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _busy ? null : _newProject,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [C.berry2, C.accent],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 36),
                          SizedBox(height: 8),
                          Text('مشروع جديد',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('المشاريع',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Expanded(
                    child: Center(
                      child: Text('ستظهر مشاريعك المحفوظة هنا قريباً',
                          style: TextStyle(color: C.muted)),
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x99000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
