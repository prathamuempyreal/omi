import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/api/omi_models.dart';

class OmiCache {
  OmiCache._();

  static OmiCache? _instance;
  static OmiCache get instance => _instance ??= OmiCache._();

  static const String _conversationsKey = 'omi_cache_conversations';
  static const String _memoriesKey = 'omi_cache_memories';
  static const String _actionItemsKey = 'omi_cache_action_items';
  static const String _settingsKey = 'omi_cache_settings';
  static const String _pendingChangesKey = 'omi_cache_pending_changes';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> cacheConversations(List<OmiConversation> conversations) async {
    final json = conversations.map((c) => c.toJson()).toList();
    await _prefs?.setString(_conversationsKey, jsonEncode(json));
  }

  List<OmiConversation> getCachedConversations() {
    final json = _prefs?.getString(_conversationsKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => OmiConversation.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheMemories(List<OmiMemory> memories) async {
    final json = memories.map((m) => m.toJson()).toList();
    await _prefs?.setString(_memoriesKey, jsonEncode(json));
  }

  List<OmiMemory> getCachedMemories() {
    final json = _prefs?.getString(_memoriesKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => OmiMemory.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheActionItems(List<OmiActionItem> items) async {
    final json = items.map((i) => i.toJson()).toList();
    await _prefs?.setString(_actionItemsKey, jsonEncode(json));
  }

  List<OmiActionItem> getCachedActionItems() {
    final json = _prefs?.getString(_actionItemsKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => OmiActionItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheSettings(OmiSettings settings) async {
    await _prefs?.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  OmiSettings getCachedSettings() {
    final json = _prefs?.getString(_settingsKey);
    if (json == null) return OmiSettings();
    try {
      return OmiSettings.fromJson(jsonDecode(json));
    } catch (_) {
      return OmiSettings();
    }
  }

  Future<void> addPendingChange(Map<String, dynamic> change) async {
    final pending = getPendingChanges();
    pending.add(change);
    await _prefs?.setString(_pendingChangesKey, jsonEncode(pending));
  }

  List<Map<String, dynamic>> getPendingChanges() {
    final json = _prefs?.getString(_pendingChangesKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearPendingChanges() async {
    await _prefs?.remove(_pendingChangesKey);
  }

  Future<void> clearAll() async {
    await _prefs?.remove(_conversationsKey);
    await _prefs?.remove(_memoriesKey);
    await _prefs?.remove(_actionItemsKey);
    await _prefs?.remove(_settingsKey);
    await _prefs?.remove(_pendingChangesKey);
  }
}

final omiCacheProvider = Provider<OmiCache>((ref) => OmiCache.instance);