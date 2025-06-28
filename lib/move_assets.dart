import 'dart:io';

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

void logMove(String path) {
  print('[move] moved $path');
}

void _moveAndDelete(MoveData data) {
  Directory pathFrom = Directory(p.joinAll([Directory.current.path, tmpDir, ...data.from]));
  if (pathFrom.existsSync()) {
    Directory pathTo = Directory(p.joinAll([Directory.current.path, assetsDir, ...data.to]))
      ..createSync(recursive: true);

    if (data.moveAsFolder) {
      for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
        File(
          p.join(pathTo.path, p.relative(file.path, from: pathFrom.path)),
        ).createSync(recursive: true);

        if (file.path.endsWith('.wav')) {
          Process.runSync("ffmpeg", [
            '-i',
            file.path,
            p
                .join(pathTo.path, p.relative(file.path, from: pathFrom.path))
                .replaceFirst('.wav', '.mp3'),
          ]);
        } else {
          file.copySync(p.join(pathTo.path, p.relative(file.path, from: pathFrom.path)));
        }
        file.deleteSync();
        logMove(file.path);
      }
    } else {
      for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.wav')) {
          Process.runSync("ffmpeg", [
            '-i',
            file.path,
            p.join(pathTo.path, file.path.split(p.separator).last).replaceFirst('.wav', '.mp3'),
          ]);
        } else {
          file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
        }
        file.deleteSync();
        logMove(file.path);
      }
    }
  }
}

void moveAssetsAndConvert() {
  for (var data in movedatas) {
    _moveAndDelete(data);
  }
}
