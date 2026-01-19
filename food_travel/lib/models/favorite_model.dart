import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String dishId;
  final DateTime? createAt;

  const FavoriteModel({
    required this.dishId,
    this.createAt,
  });
  factory FavoriteModel.fromDoc(DocumentSnapshot doc){
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final ts = data['createAt'];
    return FavoriteModel(
      dishId: (data['dishId'] ?? doc.id) as String,
      createAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}