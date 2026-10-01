import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_config.dart';

/// Live REST Client for Google Cloud Firestore Database (sw-gyanmitra-finall2-426-dcc41)
class FirestoreRestService {
  static const String _baseUrl =
      "https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}/databases/(default)/documents";

  /// 1. Convert Dart Map to Firestore REST Value Encoding
  static Map<String, dynamic> encodeMapToFirestoreFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    data.forEach((key, value) {
      final encoded = _encodeValue(value);
      if (encoded != null) {
        fields[key] = encoded;
      }
    });
    return fields;
  }

  static dynamic _encodeValue(dynamic value) {
    if (value == null) {
      return {'nullValue': null};
    } else if (value is String) {
      return {'stringValue': value};
    } else if (value is int) {
      return {'integerValue': value.toString()};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is num) {
      return {'doubleValue': value.toDouble()};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is List) {
      final listValues = value.map((v) => _encodeValue(v)).where((v) => v != null).toList();
      return {
        'arrayValue': {'values': listValues}
      };
    } else if (value is Map<String, dynamic>) {
      return {
        'mapValue': {'fields': encodeMapToFirestoreFields(value)}
      };
    } else if (value is DateTime) {
      return {'stringValue': value.toIso8601String()};
    }
    return {'stringValue': value.toString()};
  }

  /// 2. Convert Firestore REST Document to plain Dart Map
  static Map<String, dynamic> decodeFirestoreDocument(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>?;
    if (fields == null) return {};
    return decodeFields(fields);
  }

  static Map<String, dynamic> decodeFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((key, val) {
      result[key] = _decodeValue(val);
    });
    return result;
  }

  static dynamic _decodeValue(dynamic val) {
    if (val is! Map<String, dynamic>) return val;
    if (val.containsKey('stringValue')) return val['stringValue'];
    if (val.containsKey('integerValue')) return int.tryParse(val['integerValue'].toString()) ?? 0;
    if (val.containsKey('doubleValue')) return (val['doubleValue'] as num).toDouble();
    if (val.containsKey('booleanValue')) return val['booleanValue'] as bool;
    if (val.containsKey('nullValue')) return null;
    if (val.containsKey('arrayValue')) {
      final arr = val['arrayValue']?['values'] as List<dynamic>?;
      if (arr == null) return [];
      return arr.map((v) => _decodeValue(v)).toList();
    }
    if (val.containsKey('mapValue')) {
      final m = val['mapValue']?['fields'] as Map<String, dynamic>?;
      if (m == null) return {};
      return decodeFields(m);
    }
    return val;
  }

  /// 3. Read All Documents from a Collection
  static Future<List<Map<String, dynamic>>> getCollectionDocuments(String collection) async {
    try {
      final uri = Uri.parse("$_baseUrl/$collection?key=${FirebaseConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List<dynamic>?;
        if (documents == null) return [];
        return documents.map((doc) => decodeFirestoreDocument(doc as Map<String, dynamic>)).toList();
      } else {
        debugPrint('[FirestoreRest] getCollection ($collection) HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Firestore HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreRest] getCollection ($collection) error: $e');
      rethrow;
    }
  }

  /// 4. Read a Single Document
  static Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    try {
      final uri = Uri.parse("$_baseUrl/$collection/$docId?key=${FirebaseConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return decodeFirestoreDocument(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('[FirestoreRest] getDocument ($collection/$docId) HTTP ${response.statusCode}');
        throw Exception('Firestore HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreRest] getDocument ($collection/$docId) error: $e');
      rethrow;
    }
  }

  /// 5. Write / Upsert Document (Live Real-time Sync)
  static Future<bool> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse("$_baseUrl/$collection/$docId?key=${FirebaseConfig.apiKey}");
      final body = jsonEncode({
        'fields': encodeMapToFirestoreFields(data),
      });

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        debugPrint('[FirestoreRest] Document saved: $collection/$docId');
        return true;
      } else {
        debugPrint('[FirestoreRest] setDocument error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[FirestoreRest] setDocument exception: $e');
      return false;
    }
  }

  /// 6. Delete Document
  static Future<bool> deleteDocument(String collection, String docId) async {
    try {
      final uri = Uri.parse("$_baseUrl/$collection/$docId?key=${FirebaseConfig.apiKey}");
      final response = await http.delete(uri).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[FirestoreRest] deleteDocument error: $e');
      return false;
    }
  }
}
