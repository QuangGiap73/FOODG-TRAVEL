import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/dish_model.dart';
class FavoriteService {
  // tao 1 instance dung chung toan app
  FavoriteService._internal();
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;

  final _db = FirebaseFirestore.instance; // ket noi voi firebase
  // tao duong dan den favorites
  CollectionReference<Map<String, dynamic>> _favRef(String uid){
    return _db.collection('users').doc(uid).collection('favorites');
  }
  // theo doi realtime
  Stream<Set<String>> watchFavoriteIds(String uid){
    return _favRef(uid).snapshots().map((snapshot){
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }
  // chuc nang bam tim
  Future<void> toggleFavorite(String uid, String dishId)  async {
    final ref = _favRef(uid).doc(dishId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'dishId' : dishId,
        'createdAt' : FieldValue.serverTimestamp(),
      });
    }
  }
  Stream<List<DishModel>> watchFavoriteDishes(String uid) async* {
    await for (final snap in _favRef(uid).snapshots()){
      // lấy danh sách các mon yeu thich
      final ids = snap.docs.map((d) => d.id).toList();
      if (ids.isEmpty){
        yield const <DishModel>[];
        continue;
      }
      // vì firestore có giới hạn nên phải chia nhỏ
      final chunks = <List<String>>[];
      for(var i=0; i<ids.length; i +=10){
        chunks.add(ids.sublist(i, min(i+10, ids.length)));
      }
      // qurrey lay du lieu mon an
      final results = await Future.wait(
        chunks.map(
          (chunks) => _db
              .collection('dishes')
              .where(FieldPath.documentId, whereIn: chunks)
              .get(),
        ),
      );
      final dishes = results
          .expand((qs) => qs.docs)
          .map((doc) => DishModel.fromDoc(doc))
          .toList();

      yield dishes;
    }
  }
}
