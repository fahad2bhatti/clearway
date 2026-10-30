import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

final class PendingFeedback {
  const PendingFeedback({
    required this.id,
    required this.text,
    required this.appVersion,
  });

  final String id;
  final String text;
  final String appVersion;

  Map<String, String> toJson() => {
        'id': id,
        'text': text,
        'appVersion': appVersion,
      };

  static PendingFeedback? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final text = raw['text'];
    final appVersion = raw['appVersion'];
    if (id is! String ||
        text is! String ||
        appVersion is! String ||
        id.isEmpty ||
        id.contains('/')) {
      return null;
    }
    return PendingFeedback(id: id, text: text, appVersion: appVersion);
  }
}

/// Small on-device outbox so feedback written offline survives restarts.
abstract final class FeedbackQueue {
  static const storageKey = 'clearway_pending_feedback';
  static const maxItems = 5;

  static Future<void> _lock = Future<void>.value();

  static Future<T> _serialized<T>(Future<T> Function() action) {
    final run = _lock.then((_) => action());
    _lock = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  static Future<List<PendingFeedback>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(PendingFeedback.fromJson)
          .whereType<PendingFeedback>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Returns null when the queue is full.
  static Future<PendingFeedback?> enqueue({
    required String text,
    required String appVersion,
  }) =>
      _serialized<PendingFeedback?>(() async {
        final items = await pending();
        if (items.length >= maxItems) return null;
        final item = PendingFeedback(
          id: _newId(),
          text: text,
          appVersion: appVersion,
        );
        await _write([...items, item]);
        return item;
      });

  static Future<void> remove(String id) => _serialized<void>(() async {
        final items = await pending();
        await _write(items.where((item) => item.id != id).toList());
      });

  static Future<void> _write(List<PendingFeedback> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  static String _newId() {
    final random = Random.secure().nextInt(0x100000000).toRadixString(16);
    return 'fb-${DateTime.now().microsecondsSinceEpoch}-$random';
  }
}
