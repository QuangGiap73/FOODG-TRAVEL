import 'package:cloud_firestore/cloud_firestore.dart';

class PostMedia {
  const PostMedia({
    required this.url,
    this.type = 'image',
    this.thumbnailUrl = '',
    this.publicId = '',
    this.duration,
    this.width,
    this.height,
  });

  final String url;
  final String type;
  final String thumbnailUrl;
  final String publicId;
  final double? duration;
  final int? width;
  final int? height;

  bool get isVideo => type.toLowerCase() == 'video';
  String get previewUrl => isVideo && thumbnailUrl.trim().isNotEmpty ? thumbnailUrl : url;

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'thumbnailUrl': thumbnailUrl,
      'publicId': publicId,
      'duration': duration,
      'w': width,
      'h': height,
    };
  }

  factory PostMedia.fromMap(Map<String, dynamic> map) {
    return PostMedia(
      url: (map['url'] ?? '').toString(),
      type: (map['type'] ?? 'image').toString(),
      thumbnailUrl: (map['thumbnailUrl'] ?? '').toString(),
      publicId: (map['publicId'] ?? '').toString(),
      duration: map['duration'] is num ? (map['duration'] as num).toDouble() : null,
      width: map['w'] is num ? (map['w'] as num).toInt() : null,
      height: map['h'] is num ? (map['h'] as num).toInt() : null,
    );
  }
}

class PlaceSnapshot {
  const PlaceSnapshot({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.photoUrl = '',
  });

  final String name;
  final String address;
  final double lat;
  final double lng;
  final String photoUrl;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'photoUrl': photoUrl,
    };
  }

  factory PlaceSnapshot.fromMap(Map<String, dynamic> map) {
    return PlaceSnapshot(
      name: (map['name'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      lat: _toDouble(map['lat']),
      lng: _toDouble(map['lng']),
      photoUrl: (map['photoUrl'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.media,
    this.placeId,
    this.place,
    this.placeSource,
    this.provinceCode34,
    this.provinceName34,
    this.regionCode,
    this.status = 'active', // Trang thai bai viet (default active)
    this.moderationStatus = 'published', // pending | published | hidden | rejected
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final List<PostMedia> media;
  final String? placeId;
  final PlaceSnapshot? place;
  final String? placeSource; // serpapi
  // 3 field này giúp app và admin lọc đúng theo bộ 34 tỉnh/thành mới.
  final String? provinceCode34;
  final String? provinceName34;
  final String? regionCode;
  final String status; // active | deleted
  final String moderationStatus; // pending | published | hidden | rejected
  final int likeCount;
  final int commentCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  // Dùng để kiểm tra bài viết có được hiển thị ra feed công khai hay không.
  bool get isPublished =>
      status == 'active' && moderationStatus.toLowerCase() == 'published';

  factory CommunityPost.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    final mediaRaw = data['media'];
    final mediaList = <PostMedia>[];
    if (mediaRaw is List) {
      for (final item in mediaRaw) {
        if (item is Map) {
          mediaList.add(PostMedia.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final placeRaw = data['placeSnapshot'];
    PlaceSnapshot? place;
    if (placeRaw is Map) {
      place = PlaceSnapshot.fromMap(Map<String, dynamic>.from(placeRaw));
    }

    return CommunityPost(
      id: doc.id,
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? '').toString(),
      authorPhoto: (data['authorPhoto'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      media: mediaList,
      placeId: data['placeId']?.toString(),
      place: place,
      placeSource: data['placeSource']?.toString(),
      provinceCode34: data['provinceCode34']?.toString(),
      provinceName34: data['provinceName34']?.toString(),
      regionCode: data['regionCode']?.toString(),
      status: (data['status'] ?? 'active').toString(),
      moderationStatus: (data['moderationStatus'] ?? 'published').toString(),
      likeCount: _toInt(data['likeCount']),
      commentCount: _toInt(data['commentCount']),
      createdAt:
          data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
      updatedAt:
          data['updatedAt'] is Timestamp ? data['updatedAt'] as Timestamp : null,
    );
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
