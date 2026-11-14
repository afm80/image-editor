import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import 'editor_controller.dart';
import 'theme.dart';

class ExportOptions {
  int resolution = 1080; // الضلع الأقصر
  int fps = 30;
  int crf = 23;
}

Widget _chips<T>(
  List<T> values,
  T current,
  String Function(T) label,
  void Function(T) onPick,
) {
  return Wrap(
    spacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(label(v)),
          selected: v == current,
          onSelected: (_) => onPick(v),
        ),
    ],
  );
}

Future<void> showExportSheet(BuildContext context, EditorController ctrl) async {
  if (ctrl.clips.isEmpty) return;
  final o = ExportOptions();
  final go = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: C.sheet,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تصدير الفيديو',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('الدقة', style: TextStyle(color: C.muted)),
            const SizedBox(height: 8),
            _chips<int>(
              [480, 720, 1080, 1440, 2160],
              o.resolution,
              (v) => v == 1440 ? '2K' : (v == 2160 ? '4K' : '${v}p'),
              (v) => set(() => o.resolution = v),
            ),
            const SizedBox(height: 16),
            const Text('معدل الإطارات', style: TextStyle(color: C.muted)),
            const SizedBox(height: 8),
            _chips<int>(
              [24, 30, 60],
              o.fps,
              (v) => '$v',
              (v) => set(() => o.fps = v),
            ),
            const SizedBox(height: 16),
            const Text('الجودة', style: TextStyle(color: C.muted)),
            const SizedBox(height: 8),
            _chips<int>(
              [28, 23, 18],
              o.crf,
              (v) => v == 28 ? 'منخفضة' : (v == 23 ? 'موصى بها' : 'عالية'),
              (v) => set(() => o.crf = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تصدير وحفظ في المعرض'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (go == true && context.mounted) {
    await runExport(context, ctrl, o);
  }
}

String _atempo(double s) {
  final parts = <String>[];
  while (s > 2.0) {
    parts.add('atempo=2.0');
    s /= 2.0;
  }
  while (s < 0.5) {
    parts.add('atempo=0.5');
    s /= 0.5;
  }
  parts.add('atempo=${s.toStringAsFixed(4)}');
  return parts.join(',');
}

String buildCommand(
  List<ClipItem> clips,
  int w,
  int h,
  ExportOptions o,
  String out,
) {
  final inputs = StringBuffer();
  final filters = <String>[];
  final concatIn = StringBuffer();
  for (var i = 0; i < clips.length; i++) {
    final c = clips[i];
    inputs.write(
        '-ss ${c.start.toStringAsFixed(3)} -t ${(c.end - c.start).toStringAsFixed(3)} -i "${c.path}" ');
    filters.add('[$i:v]setpts=(PTS-STARTPTS)/${c.speed},'
        'scale=$w:$h:force_original_aspect_ratio=decrease,'
        'pad=$w:$h:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=${o.fps},format=yuv420p[v$i]');
    if (c.hasAudio) {
      filters.add('[$i:a]${_atempo(c.speed)},volume=${c.volume},'
          'aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo[a$i]');
    } else {
      filters.add('anullsrc=r=44100:cl=stereo,'
          'atrim=0:${c.duration.toStringAsFixed(3)},asetpts=PTS-STARTPTS[a$i]');
    }
    concatIn.write('[v$i][a$i]');
  }
  filters.add('${concatIn}concat=n=${clips.length}:v=1:a=1[v][a]');
  return '$inputs-filter_complex "${filters.join(';')}" '
      '-map "[v]" -map "[a]" -c:v libx264 -preset veryfast -crf ${o.crf} '
      '-pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart -y "$out"';
}

Future<void> runExport(
  BuildContext context,
  EditorController ctrl,
  ExportOptions o,
) async {
  await ctrl.pause();
  final first = ctrl.clips.first;
  final aspect = first.width / first.height;
  int w;
  int h;
  if (first.width >= first.height) {
    h = o.resolution;
    w = (h * aspect / 2).round() * 2;
  } else {
    w = o.resolution;
    h = (w / aspect / 2).round() * 2;
  }

  final progress = ValueNotifier<double>(0);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('جارٍ التصدير...'),
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (_, v, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: v),
            const SizedBox(height: 12),
            Text('${(v * 100).round()}%'),
          ],
        ),
      ),
    ),
  );

  final dir = await getTemporaryDirectory();
  final out =
      '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
  final cmd = buildCommand(ctrl.clips, w, h, o, out);
  final totalMs = ctrl.total * 1000;
  final logs = <String>[];
  final done = Completer<bool>();

  await FFmpegKit.executeAsync(
    cmd,
    (session) async {
      final rc = await session.getReturnCode();
      done.complete(ReturnCode.isSuccess(rc));
    },
    (log) => logs.add(log.getMessage()),
    (stats) {
      progress.value = (stats.getTime() / totalMs).clamp(0.0, 1.0).toDouble();
    },
  );
  final ok = await done.future;

  String? error;
  if (ok) {
    try {
      await Gal.requestAccess();
      await Gal.putVideo(out);
    } catch (e) {
      error = 'تم إنشاء الفيديو لكن تعذّر حفظه في المعرض: $e';
    }
  } else {
    final tail = logs.length > 8 ? logs.sublist(logs.length - 8) : logs;
    error = 'فشل التصدير.\n${tail.join('\n')}';
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (error == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحفظ في المعرض')),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تنبيه'),
        content: SingleChildScrollView(
          child: Text(error!, style: const TextStyle(fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
