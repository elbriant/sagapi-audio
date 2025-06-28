import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:sagapi_audio/globals.dart';

class ExtractTask {
  final String path;
  final String types;
  final String filtersByName;
  final String outputDir;
  final String groupMode;

  ExtractTask({
    required this.path,
    required this.types,
    required this.outputDir,
    this.filtersByName = '',
    this.groupMode = '',
  });

  Future<void> job() async {
    if (filtersByName.isNotEmpty) {
      await Process.run("dotnet", [
        (p.join(Directory.current.path, "ArknightsStudioCLI", "ArknightsStudioCLI.dll")),
        path,
        "-t",
        (types),
        "-o",
        (outputDir),
        "-g",
        groupMode.isNotEmpty ? (groupMode) : 'container',
        "--filter-by-name",
        (filtersByName),
      ]);
    } else {
      await Process.run("dotnet", [
        (p.join(Directory.current.path, "ArknightsStudioCLI", "ArknightsStudioCLI.dll")),
        path,
        "-t",
        (types),
        "-o",
        (outputDir),
        "-g",
        groupMode.isNotEmpty ? (groupMode) : 'container',
      ]);
    }
  }
}

Future<void> extractAssetsAndDeleteBundle({
  String? ouputPath,
  required String bundlesPath,
  int? isoId,
}) async {
  final outputDir = ouputPath ?? p.join(Directory.current.path, tmpDir);

  await Directory(outputDir).create();

  final files =
      (await Directory(bundlesPath).list(recursive: true).toList()).whereType<File>().where((
        element,
      ) {
        return element.path.endsWith('.ab') && !element.path.endsWith('hot_update_list.json');
      }).toList();

  List<ExtractTask> tasks = [];

  for (var file in files) {
    final filepath = file.path;

    List<String> types = [];
    List<String> filterByName = [];
    String? groupMode;

    types.addAll(["audio"]);

    tasks.add(
      ExtractTask(
        path: filepath,
        types: types.join(','),
        outputDir: outputDir,
        filtersByName: filterByName.join(','),
        groupMode: groupMode ?? '',
      ),
    );
  }

  var queue = QueueList.from(tasks);
  while (queue.isNotEmpty) {
    var task = queue.removeFirst();
    await task.job();
    await File(task.path).delete();

    print("[AKStudio I${isoId ?? '!'}] ${task.path}");
  }
}
