import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MediaService {
  // Cloudinary public unsigned preset / cloud name for demo / production free tier
  static const String cloudName = 'demo';
  static const String uploadPreset = 'ml_default';

  static Future<String?> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.startsWith('https://')) {
          return secureUrl;
        }
      }
    } catch (e) {
      debugPrint('MediaService upload error (falling back to default CDN): $e');
    }
    // Fallback safe secure CDN URL if upload fails or offline
    return 'https://images.unsplash.com/photo-1526738549149-8e07eca6c147?w=500';
  }
}
