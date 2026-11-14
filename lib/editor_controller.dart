import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class ClipItem {
  final String path;
  final int width;
  final int height;
  final bool hasAudio;
  final double sourceDuration;
  double start;
  double end;
  double speed;
  double volume;

  ClipItem({
    required this.path,
    required this.width,
    required this.height,
    required this.hasAudio,
    required this.sourceDuration,
    required this.start,
    required this.end,
    this.speed = 1.0,
    this.volume = 1.0,
  });

  /// المدة الفعلية على الخط الزمني بعد تطبيق السرعة.
  double get duration => (end - start) / speed;

  ClipItem copy() => ClipItem(
        path: path,
        width: width,
        height: height,
        hasAudio: hasAudio,
        sourceDuration: sourceDuration,
        start: start,
        end: end,
        speed: speed,
        volume: volume,
      );
}

class EditorController extends ChangeNotifier {
  final List<ClipItem> clips = [];
  int? selected;
  double position = 0;
  bool playing = false;
  VideoPlayerController? video;

  int _videoIndex = -1;
  bool _switching = false;
  double? _pending;
  bool _seeking = false;
  final List<List<ClipItem>> _undo = [];
  final List<List<ClipItem>> _redo = [];

  double get total => clips.fold(0.0, (a, c) => a + c.duration);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  double _offsetOf(int i) {
    double t = 0;
    for (var k = 0; k < i; k++) {
      t += clips[k].duration;
    }
    return t;
  }

  int _indexAt(double t) {
    double acc = 0;
    for (var i = 0; i < clips.length; i++) {
      acc += clips[i].duration;
      if (t < acc) return i;
    }
    return clips.length - 1;
  }

  int currentIndex() => clips.isEmpty ? 0 : _indexAt(position);

  List<ClipItem> _copyAll() => clips.map((c) => c.copy()).toList();

  void _snapshot() {
    _undo.add(_copyAll());
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
  }

  void select(int? i) {
    selected = i;
    notifyListeners();
  }

  // ---------- إضافة مقطع ----------
  Future<void> addClipFromPath(String path) async {
    final probe = VideoPlayerController.file(File(path));
    await probe.initialize();
    final dur = probe.value.duration.inMilliseconds / 1000.0;
    final size = probe.value.size;
    await probe.dispose();

    var hasAudio = true;
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final streams = session.getMediaInformation()?.getStreams() ?? [];
      hasAudio = streams.any((s) => s.getType() == 'audio');
    } catch (_) {}

    if (clips.isNotEmpty) _snapshot();
    clips.add(ClipItem(
      path: path,
      width: size.width.round(),
      height: size.height.round(),
      hasAudio: hasAudio,
      sourceDuration: dur,
      start: 0,
      end: dur,
    ));
    notifyListeners();
    await seekGlobal(clips.length == 1 ? 0 : position);
  }

  // ---------- التنقل والتشغيل ----------
  Future<void> seekGlobal(double t) async {
    _pending = t;
    if (_seeking) return;
    _seeking = true;
    try {
      while (_pending != null) {
        final x = _pending!;
        _pending = null;
        await _seek(x);
      }
    } finally {
      _seeking = false;
    }
  }

  Future<void> _seek(double t) async {
    if (clips.isEmpty) return;
    t = t.clamp(0.0, total).toDouble();
    final i = _indexAt(t);
    position = t;
    await _ensure(i);
    final c = clips[i];
    final local = (t - _offsetOf(i)).clamp(0.0, c.duration).toDouble();
    final src = c.start + local * c.speed;
    await video?.seekTo(Duration(milliseconds: (src * 1000).round()));
    notifyListeners();
  }

  Future<void> _resetVideo() async {
    final old = video;
    video = null;
    _videoIndex = -1;
    old?.removeListener(_onTick);
    notifyListeners();
    if (old != null) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await old.dispose();
    }
  }

  Future<void> _ensure(int i) async {
    if (_videoIndex == i && video != null) return;
    await _resetVideo();
    final c = clips[i];
    final v = VideoPlayerController.file(File(c.path));
    await v.initialize();
    await v.setVolume(c.volume.clamp(0.0, 1.0).toDouble());
    await v.setPlaybackSpeed(c.speed);
    v.addListener(_onTick);
    video = v;
    _videoIndex = i;
    notifyListeners();
  }

  void _onTick() {
    final v = video;
    if (v == null || !playing || _switching) return;
    final i = _videoIndex;
    if (i < 0 || i >= clips.length) return;
    final c = clips[i];
    final src = v.value.position.inMilliseconds / 1000.0;
    if (src >= c.end - 0.04) {
      _advance(i);
      return;
    }
    position = _offsetOf(i) +
        ((src - c.start) / c.speed).clamp(0.0, c.duration).toDouble();
    notifyListeners();
  }

  Future<void> _advance(int i) async {
    _switching = true;
    try {
      if (i + 1 < clips.length) {
        await _ensure(i + 1);
        await video?.seekTo(
            Duration(milliseconds: (clips[i + 1].start * 1000).round()));
        position = _offsetOf(i + 1);
        await video?.play();
      } else {
        await video?.pause();
        playing = false;
        position = total;
      }
    } finally {
      _switching = false;
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (clips.isEmpty) return;
    if (position >= total - 0.05) await seekGlobal(0);
    if (video == null) await seekGlobal(position);
    playing = true;
    await video?.play();
    notifyListeners();
  }

  Future<void> pause() async {
    playing = false;
    await video?.pause();
    notifyListeners();
  }

  // ---------- التعديل ----------
  Future<void> _afterEdit() async {
    playing = false;
    await _resetVideo();
    position = position.clamp(0.0, total).toDouble();
    await seekGlobal(position);
    notifyListeners();
  }

  Future<void> splitAtPlayhead() async {
    if (clips.isEmpty) return;
    final i = _indexAt(position);
    final c = clips[i];
    final local = position - _offsetOf(i);
    if (local < 0.1 || c.duration - local < 0.1) return;
    final srcSplit = c.start + local * c.speed;
    _snapshot();
    final second = c.copy()..start = srcSplit;
    c.end = srcSplit;
    clips.insert(i + 1, second);
    selected = null;
    await _afterEdit();
  }

  Future<void> deleteSelected() async {
    final i = selected;
    if (i == null || i >= clips.length) return;
    _snapshot();
    clips.removeAt(i);
    selected = null;
    await _afterEdit();
  }

  Future<void> duplicateSelected() async {
    final i = selected;
    if (i == null || i >= clips.length) return;
    _snapshot();
    clips.insert(i + 1, clips[i].copy());
    await _afterEdit();
  }

  Future<void> setSpeed(double s) async {
    final i = selected;
    if (i == null || i >= clips.length) return;
    _snapshot();
    clips[i].speed = s;
    await _afterEdit();
  }

  Future<void> setVolume(double v) async {
    final i = selected;
    if (i == null || i >= clips.length) return;
    _snapshot();
    clips[i].volume = v;
    await _afterEdit();
  }

  Future<void> undo() async {
    if (_undo.isEmpty) return;
    _redo.add(_copyAll());
    final prev = _undo.removeLast();
    clips
      ..clear()
      ..addAll(prev);
    selected = null;
    await _afterEdit();
  }

  Future<void> redo() async {
    if (_redo.isEmpty) return;
    _undo.add(_copyAll());
    final next = _redo.removeLast();
    clips
      ..clear()
      ..addAll(next);
    selected = null;
    await _afterEdit();
  }

  @override
  void dispose() {
    video?.removeListener(_onTick);
    video?.dispose();
    super.dispose();
  }
}
