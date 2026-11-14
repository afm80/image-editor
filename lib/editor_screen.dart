import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'editor_controller.dart';
import 'export.dart';
import 'theme.dart';

class EditorScreen extends StatefulWidget {
  final EditorController controller;
  const EditorScreen({super.key, required this.controller});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const double pps = 60; // بكسل لكل ثانية
  final ScrollController _sc = ScrollController();
  EditorController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_sync);
  }

  @override
  void dispose() {
    ctrl.removeListener(_sync);
    _sc.dispose();
    super.dispose();
  }

  void _sync() {
    if (ctrl.playing && _sc.hasClients) {
      final target =
          (ctrl.position * pps).clamp(0.0, _sc.position.maxScrollExtent);
      _sc.jumpTo(target.toDouble());
    }
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة قادمة في مرحلة لاحقة')),
    );
  }

  String _fmt(double s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s.floor() % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<void> _addClip() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    try {
      await ctrl.addClipFromPath(picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر فتح الفيديو: $e')),
        );
      }
    }
  }

  Future<void> _speedSheet() async {
    final i = ctrl.selected;
    if (i == null) return;
    var v = ctrl.clips[i].speed;
    final res = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: C.sheet,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('السرعة: ${v.toStringAsFixed(2)}x',
                  style: const TextStyle(fontSize: 16)),
              Slider(
                min: 0.25,
                max: 4,
                value: v,
                onChanged: (x) => set(() => v = (x * 20).round() / 20),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, v),
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (res != null) await ctrl.setSpeed(res);
  }

  Future<void> _volumeSheet() async {
    final i = ctrl.selected;
    if (i == null) return;
    var v = ctrl.clips[i].volume;
    final res = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: C.sheet,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('مستوى الصوت: ${(v * 100).round()}%',
                  style: const TextStyle(fontSize: 16)),
              Slider(
                min: 0,
                max: 2,
                value: v,
                onChanged: (x) => set(() => v = (x * 20).round() / 20),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, v),
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (res != null) await ctrl.setVolume(res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (context, _) => Column(
            children: [
              _topBar(),
              Expanded(child: _preview()),
              _controls(),
              _timeline(),
              _toolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_forward),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => showExportSheet(context, ctrl),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: C.line),
              ),
              child: const Text('1080p'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => showExportSheet(context, ctrl),
              child: const Text('تصدير'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final v = ctrl.video;
    final ready = v != null && v.value.isInitialized;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: ready
          ? Center(
              child: AspectRatio(
                aspectRatio: v.value.aspectRatio,
                child: VideoPlayer(v),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _controls() {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${_fmt(ctrl.position)} / ${_fmt(ctrl.total)}',
                style: const TextStyle(fontSize: 13, color: C.muted),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: ctrl.canUndo ? ctrl.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: C.bg,
              ),
              onPressed: () => ctrl.playing ? ctrl.pause() : ctrl.play(),
              icon: Icon(ctrl.playing ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              onPressed: ctrl.canRedo ? ctrl.redo : null,
              icon: const Icon(Icons.redo),
            ),
            const Spacer(),
            IconButton(onPressed: _soon, icon: const Icon(Icons.fullscreen)),
          ],
        ),
      ),
    );
  }

  Widget _timeline() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 170,
        decoration: const BoxDecoration(
          color: C.surface,
          border: Border(top: BorderSide(color: C.line)),
        ),
        child: LayoutBuilder(builder: (context, box) {
          final half = box.maxWidth / 2;
          final contentW = ctrl.total * pps;
          return Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollStartNotification && n.dragDetails != null) {
                    ctrl.pause();
                  }
                  if (n is ScrollUpdateNotification && n.dragDetails != null) {
                    ctrl.seekGlobal(n.metrics.pixels / pps);
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _sc,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: half * 2 + contentW,
                    child: Padding(
                      padding: EdgeInsets.only(left: half, top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: contentW,
                            height: 18,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (var i = 0; i <= ctrl.total.ceil(); i++)
                                  Positioned(
                                    left: i * pps,
                                    child: Text(_fmt(i.toDouble()),
                                        style: const TextStyle(
                                            fontSize: 10, color: C.muted)),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < ctrl.clips.length; i++)
                                _clipBlock(i),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _placeholder('+ إضافة صوت', contentW),
                          const SizedBox(height: 6),
                          _placeholder('+ إضافة نص', contentW),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: half - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                right: 8,
                top: 30,
                child: InkWell(
                  onTap: _addClip,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: C.bg),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _placeholder(String text, double w) {
    return GestureDetector(
      onTap: _soon,
      child: Container(
        width: w < 120 ? 120 : w,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11, color: C.muted)),
      ),
    );
  }

  Widget _clipBlock(int i) {
    final c = ctrl.clips[i];
    final sel = ctrl.selected == i;
    final w = c.duration * pps;
    return GestureDetector(
      onTap: () => ctrl.select(sel ? null : i),
      child: Container(
        width: w < 24 ? 24 : w,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [C.berry, C.berry2]),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: sel ? Colors.white : C.bg,
            width: 2,
          ),
        ),
        child: Text(
          '${c.duration.toStringAsFixed(1)}ث'
          '${c.speed != 1.0 ? '  ${c.speed}x' : ''}',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Widget _toolbar() {
    final items = ctrl.selected != null ? _clipTools() : _mainTools();
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: C.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: items,
      ),
    );
  }

  List<Widget> _mainTools() {
    return [
      _Tool(
        Icons.content_cut,
        'تعديل',
        () {
          if (ctrl.clips.isNotEmpty) ctrl.select(ctrl.currentIndex());
        },
      ),
      _Tool(Icons.music_note, 'الصوت', _soon),
      _Tool(Icons.title, 'النص', _soon),
      _Tool(Icons.emoji_emotions_outlined, 'ملصقات', _soon),
      _Tool(Icons.auto_awesome, 'تأثيرات', _soon),
      _Tool(Icons.filter_vintage_outlined, 'فلاتر', _soon),
      _Tool(Icons.tune, 'ضبط', _soon),
      _Tool(Icons.layers_outlined, 'تراكب', _soon),
      _Tool(Icons.closed_caption_outlined, 'ترجمة تلقائية', _soon),
      _Tool(Icons.crop_free, 'الأبعاد', _soon),
      _Tool(Icons.wallpaper, 'خلفية', _soon),
    ];
  }

  List<Widget> _clipTools() {
    return [
      _Tool(Icons.chevron_left, 'رجوع', () => ctrl.select(null)),
      _Tool(Icons.call_split, 'تقسيم', ctrl.splitAtPlayhead),
      _Tool(Icons.speed, 'سرعة', _speedSheet),
      _Tool(Icons.delete_outline, 'حذف', ctrl.deleteSelected),
      _Tool(Icons.volume_up_outlined, 'الصوت', _volumeSheet),
      _Tool(Icons.copy, 'تكرار', ctrl.duplicateSelected),
      _Tool(Icons.animation, 'حركات', _soon),
      _Tool(Icons.vignette_outlined, 'قناع', _soon),
      _Tool(Icons.water_drop_outlined, 'كروما', _soon),
      _Tool(Icons.graphic_eq, 'فصل الصوت', _soon),
      _Tool(Icons.opacity, 'الشفافية', _soon),
      _Tool(Icons.person_outline, 'إزالة الخلفية', _soon),
      _Tool(Icons.crop, 'قص الإطار', _soon),
      _Tool(Icons.rotate_right, 'تدوير', _soon),
      _Tool(Icons.flip, 'قلب', _soon),
      _Tool(Icons.swap_horiz, 'عكس', _soon),
      _Tool(Icons.ac_unit, 'تجميد إطار', _soon),
      _Tool(Icons.find_replace, 'استبدال', _soon),
    ];
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tool(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
