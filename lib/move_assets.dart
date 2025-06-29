import 'dart:io';
import 'dart:isolate';
import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'package:sagapi_audio/globals.dart';

class MoveData {
  final List<String> from;
  final List<String> to;
  final bool moveAsFolder;
  const MoveData({required this.from, required this.to, this.moveAsFolder = false});
}

const List<MoveData> movedatas = [
  MoveData(from: ['dyn', 'audio', 'sound_beta_2'], to: [''], moveAsFolder: true),
];

Future<void> _moveAndDelete(MoveData data) async {
  Directory pathFrom = Directory(p.joinAll([Directory.current.path, tmpDir, ...data.from]));
  if (pathFrom.existsSync()) {
    Directory pathTo = Directory(p.joinAll([Directory.current.path, assetsDir, ...data.to]))
      ..createSync(recursive: true);

    final int numOfIso = max(Platform.numberOfProcessors - 1, 1);
    List<File> files = pathFrom.listSync(recursive: true).whereType<File>().toList();
    List<List<File>> chunks = files.slices((files.length ~/ numOfIso) + 1).toList();
    List<Future<void>> isolatesTasks = List.generate(
      min(numOfIso, chunks.length),
      (i) => Isolate.run(() => processInIsolate(i, data.moveAsFolder, chunks[i], pathFrom, pathTo)),
    );
    // this will supposedly exit when over or max space reached
    await Future.wait(isolatesTasks);
  }
}

Future<void> processInIsolate(
  int isoId,
  bool moveAsFolder,
  List<File> chunk,
  Directory from,
  Directory to,
) async {
  for (File file in chunk) {
    if (moveAsFolder) {
      // to avoid folder creation problems
      await Directory(
        p.join(to.path, p.dirname(p.relative(file.path, from: from.path))),
      ).create(recursive: true);

      if (file.path.endsWith('.wav')) {
        await Process.run("ffmpeg", [
          '-i',
          file.path,
          p.join(to.path, p.relative(file.path, from: from.path)).replaceFirst('.wav', '.mp3'),
        ]);
      } else {
        await file.copy(p.join(to.path, p.relative(file.path, from: from.path)));
      }
    } else {
      if (file.path.endsWith('.wav')) {
        await Process.run("ffmpeg", [
          '-i',
          file.path,
          p.join(to.path, file.path.split(p.separator).last).replaceFirst('.wav', '.mp3'),
        ]);
      } else {
        await file.copy(p.join(to.path, file.path.split(p.separator).last));
      }
    }
    await file.delete();
    print('[#$isoId] converted and moved ${file.path}');
  }
}

Future<void> moveAssetsAndConvert() async {
  for (var data in movedatas) {
    await _moveAndDelete(data);
  }
}
