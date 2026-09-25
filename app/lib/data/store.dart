import 'dart:convert';
import 'dart:io';

import '../domain/user_data.dart';

/// Persists [UserData]. Local only — there is no server.
abstract class UserDataStore {
  Future<UserData> load();
  Future<void> save(UserData data);

  /// Deletes all stored user data and attachments.
  Future<void> wipe();
}

class InMemoryStore implements UserDataStore {
  InMemoryStore([UserData? initial]) : _json = initial?.toJson();
  Map<String, dynamic>? _json;

  @override
  Future<UserData> load() async =>
      _json == null ? UserData() : UserData.fromJson(_roundTrip(_json!));

  @override
  Future<void> save(UserData data) async => _json = _roundTrip(data.toJson());

  @override
  Future<void> wipe() async => _json = null;

  Map<String, dynamic> _roundTrip(Map<String, dynamic> j) =>
      jsonDecode(jsonEncode(j)) as Map<String, dynamic>;
}

/// JSON file in the app's private documents directory. Writes go to a temp
/// file first and are renamed into place so a crash can't leave half a file.
class FileStore implements UserDataStore {
  FileStore(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}/jobloss_data.json');
  File get _backup => File('${directory.path}/jobloss_data.bak.json');
  Directory get attachmentsDir => Directory('${directory.path}/attachments');

  @override
  Future<UserData> load() async {
    for (final f in [_file, _backup]) {
      if (!await f.exists()) continue;
      try {
        return UserData.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      } on NewerDataVersionException {
        rethrow;
      } on Object {
        // Corrupt or unreadable: try the backup, then start fresh.
        continue;
      }
    }
    return UserData();
  }

  @override
  Future<void> save(UserData data) async {
    await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    if (await _file.exists()) await _file.copy(_backup.path);
    await tmp.rename(_file.path);
  }

  @override
  Future<void> wipe() async {
    for (final f in [_file, _backup, File('${_file.path}.tmp')]) {
      if (await f.exists()) await f.delete();
    }
    if (await attachmentsDir.exists()) {
      await attachmentsDir.delete(recursive: true);
    }
  }
}
