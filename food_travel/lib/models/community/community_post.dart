import 'package:cloud_firestore/cloud_firestore.dart';

class PostMedia {
  const PostMedia({
    required this.url,
    this.type = 'image',
    this.width,
    this.height,
  });

  final String url;
  final String type;
  final int? width;
  final int? height;

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'w': width,
      'h': height,
    };
  }

  factory PostMedia.fromMap(Map<String, dynamic> map) {
    return PostMedia(
      url: (map['url'] ?? '').toString(),
      type: (map['type'] ?? 'image').toString(),
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
    this.status = 'active', // Trang thai bai viet (default active)
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
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
  final String status; // active | deleted
  final int likeCount;
  final int commentCount;
  final Timestamp? createdAt;

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
      status: (data['status'] ?? 'active').toString(),
      likeCount: _toInt(data['likeCount']),
      commentCount: _toInt(data['commentCount']),
      createdAt:
          data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
    );
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
