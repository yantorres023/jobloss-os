import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_controller.dart';
import '../domain/export.dart';

/// Writes the export files to a temporary folder and opens the system share
/// sheet. The user chooses where it goes; the app sends nothing by itself.
Future<void> shareExport(AppController app) async {
  final dataset = app.dataset;
  final tmp = await getTemporaryDirectory();
  final dir = Directory('${tmp.path}/jobloss_export');
  if (await dir.exists()) await dir.delete(recursive: true);
  await dir.create(recursive: true);

  final stamp = app.today.toIso();
  final files = <XFile>[];
  if (dataset != null) {
    final txt = File('${dir.path}/jobloss-record-$stamp.txt');
    await txt.writeAsString(
      buildTextExport(dataset: dataset, data: app.data, roadmap: app.roadmap, today: app.today),
    );
    final json = File('${dir.path}/jobloss-backup-$stamp.json');
    await json.writeAsString(buildJsonExport(app.data, dataset));
    files
      ..add(XFile(txt.path, mimeType: 'text/plain'))
      ..add(XFile(json.path, mimeType: 'application/json'));
  }
  for (final a in app.data.attachments) {
    final f = app.attachmentFile(a.id);
    if (f != null && await f.exists()) files.add(XFile(f.path));
  }
  await SharePlus.instance.share(
    ShareParams(files: files, subject: 'My unemployment records ($stamp)'),
  );
}

/// Removes leftover export files so copies don't linger on the device.
Future<void> clearExportCache() async {
  final tmp = await getTemporaryDirectory();
  final dir = Directory('${tmp.path}/jobloss_export');
  if (await dir.exists()) await dir.delete(recursive: true);
}
