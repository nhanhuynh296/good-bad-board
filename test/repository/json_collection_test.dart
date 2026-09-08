import 'dart:convert';
import 'dart:io';

import 'package:good_bad_board/repository/json_collection.dart';
import 'package:test/test.dart';

/// A minimal record — [JsonCollection] doesn't care what `V` is, so the
/// repository-specific models don't need to be involved to exercise it.
class _Item {
  const _Item(this.id, this.value);
  final String id;
  final String value;

  Map<String, dynamic> toJson() => {'id': id, 'value': value};
  static _Item fromJson(Map<String, dynamic> json) =>
      _Item(json['id'] as String, json['value'] as String);
}

void main() {
  late Directory tempDir;

  JsonCollection<_Item> collection() => JsonCollection<_Item>(
    rootDir: tempDir.path,
    fileName: 'items.json',
    collectionKey: 'items',
    fromJson: _Item.fromJson,
    toJson: (item) => item.toJson(),
    idOf: (item) => item.id,
  );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('json_collection_test');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('initialize with no existing file starts with an empty cache', () async {
    final c = collection();
    await c.load();
    expect(c.all(), isEmpty);
  });

  test(
    'a read is synchronous — byId and all return values, not futures',
    () async {
      final c = collection();
      await c.load();

      // No `await` on either call below: if these methods returned a
      // Future, the assignments would fail to type-check.
      final Iterable<_Item> all = c.all();
      final _Item? byId = c.byId('missing');
      expect(all, isA<Iterable<_Item>>());
      expect(byId, isNull);
    },
  );

  test('upsert persists an item, readable via byId and all', () async {
    final c = collection();
    await c.load();

    await c.upsert(const _Item('1', 'a'));

    expect(c.byId('1')?.value, 'a');
    expect(c.all(), hasLength(1));
  });

  test('remove deletes an item', () async {
    final c = collection();
    await c.load();
    await c.upsert(const _Item('1', 'a'));

    await c.remove('1');

    expect(c.byId('1'), isNull);
    expect(c.all(), isEmpty);
  });

  test('persisted items survive a fresh load() from disk', () async {
    final c = collection();
    await c.load();
    await c.upsert(const _Item('1', 'a'));

    final reloaded = collection();
    await reloaded.load();

    expect(reloaded.byId('1')?.value, 'a');
  });

  test('notifies listeners after a successful write, not before', () async {
    final c = collection();
    await c.load();
    var notifiedBefore = false;
    c.addListener(() => notifiedBefore = true);

    final write = c.upsert(const _Item('1', 'a'));
    // The write is asynchronous (goes through a temp-file + rename), so the
    // listener must not have fired synchronously on the call itself.
    expect(notifiedBefore, isFalse);

    await write;
    expect(notifiedBefore, isTrue);
  });

  test('writes to a temp file and renames over the target — a torn write '
      'never lands as the target file', () async {
    final c = collection();
    await c.load();
    await c.upsert(const _Item('1', 'a'));

    final entries = Directory(
      tempDir.path,
    ).listSync().map((e) => e.uri.pathSegments.last);
    expect(entries, isNot(contains('items.json.tmp')));
    expect(entries, contains('items.json'));
  });

  test('a write that fails leaves the previous file untouched', () async {
    final c = collection();
    await c.load();
    await c.upsert(const _Item('1', 'a'));
    final before = File('${tempDir.path}/items.json').readAsBytesSync();

    // Make the directory read-only so creating the temp file fails —
    // the rename step never runs, so the target file must be untouched.
    await Process.run('chmod', ['555', tempDir.path]);
    addTearDown(() => Process.run('chmod', ['755', tempDir.path]));

    await expectLater(c.upsert(const _Item('2', 'b')), throwsA(anything));

    expect(
      File('${tempDir.path}/items.json').readAsBytesSync(),
      equals(before),
    );
  });

  test(
    'two upserts issued together produce one final file with both changes',
    () async {
      final c = collection();
      await c.load();

      final first = c.upsert(const _Item('1', 'a'));
      final second = c.upsert(const _Item('2', 'b'));
      await Future.wait([first, second]);

      final onDisk =
          jsonDecode(
                File('${tempDir.path}/items.json').readAsStringSync(),
              )['items']
              as List;
      expect(onDisk, hasLength(2));
      expect(c.all().map((i) => i.id), containsAll(['1', '2']));
    },
  );
}
