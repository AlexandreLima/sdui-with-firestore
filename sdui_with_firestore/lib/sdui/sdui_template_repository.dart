import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SduiTemplateRepository {
  SduiTemplateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _cachePrefix = 'sdui_template_';

  Future<Map<String, dynamic>> loadTemplate(String templateId) async {
    // 1. Try to load from local Firestore cache first (instant)
    try {
      final snapshot = await _firestore
          .collection('sdui_templates')
          .doc(templateId)
          .get(const GetOptions(source: Source.cache));

      if (snapshot.exists && snapshot.data() != null) {
        final data = Map<String, dynamic>.from(snapshot.data()!);
        final template = Map<String, dynamic>.from(data['template'] ?? {});
        await _cacheTemplate(templateId, template);
        return template;
      }
    } catch (_) {
      // Document is not in local Firestore cache yet (e.g. initial sync in progress)
    }

    // 2. Fallback to server query if cache miss
    try {
      final snapshot = await _firestore
          .collection('sdui_templates')
          .doc(templateId)
          .get(const GetOptions(source: Source.server));

      if (snapshot.exists && snapshot.data() != null) {
        final data = Map<String, dynamic>.from(snapshot.data()!);
        final template = Map<String, dynamic>.from(data['template'] ?? {});
        await _cacheTemplate(templateId, template);
        return template;
      }
    } catch (_) {
      // Server fetch failed
    }

    // 3. Fallback to SharedPreferences cache
    final cached = await _loadCachedTemplate(templateId);
    if (cached != null) {
      return cached;
    }

    // 4. Fallback to bundled asset JSON
    return await _loadAssetTemplate(templateId);
  }

  Future<Map<String, dynamic>?> _loadCachedTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$templateId');
    if (raw == null || raw.isEmpty) return null;

    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _cacheTemplate(
    String templateId,
    Map<String, dynamic> template,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$templateId', jsonEncode(template));
  }

  Future<Map<String, dynamic>> _loadAssetTemplate(String templateId) async {
    final raw = await rootBundle.loadString('assets/sdui/$templateId.json');
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }
}
