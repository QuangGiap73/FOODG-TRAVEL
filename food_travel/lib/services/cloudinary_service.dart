import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
    required this.folder,
  });

  final String cloudName;
  final String uploadPreset;
  final String folder;

  String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  Future<String> uploadImage(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }
}