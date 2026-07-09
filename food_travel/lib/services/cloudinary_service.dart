import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.url,
    required this.resourceType,
    this.publicId = '',
    this.thumbnailUrl = '',
    this.duration,
    this.width,
    this.height,
  });

  final String url;
  final String resourceType;
  final String publicId;
  final String thumbnailUrl;
  final double? duration;
  final int? width;
  final int? height;
}

class CloudinaryService {
  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
    required this.folder,
  });

  final String cloudName;
  final String uploadPreset;
  final String folder;

  String _uploadUrl(String resourceType) =>
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

  Future<String> uploadImage(File file) async {
    final result = await uploadMedia(file, resourceType: 'image');
    return result.url;
  }

  Future<CloudinaryUploadResult> uploadVideo(File file) {
    return uploadMedia(file, resourceType: 'video');
  }

  Future<CloudinaryUploadResult> uploadMedia(
    File file, {
    String resourceType = 'image',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_uploadUrl(resourceType)),
    );
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final publicId = (json['public_id'] ?? '').toString();
    final secureUrl = (json['secure_url'] ?? '').toString();
    final detectedType = (json['resource_type'] ?? resourceType).toString();
    final thumbnailUrl = detectedType == 'video' && publicId.isNotEmpty
        ? 'https://res.cloudinary.com/$cloudName/video/upload/so_0/$publicId.jpg'
        : secureUrl;

    return CloudinaryUploadResult(
      url: secureUrl,
      resourceType: detectedType,
      publicId: publicId,
      thumbnailUrl: thumbnailUrl,
      duration: json['duration'] is num
          ? (json['duration'] as num).toDouble()
          : null,
      width: json['width'] is num ? (json['width'] as num).toInt() : null,
      height: json['height'] is num ? (json['height'] as num).toInt() : null,
    );
  }
}
