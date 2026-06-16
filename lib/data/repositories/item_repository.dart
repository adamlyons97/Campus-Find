import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../services/firebase_service.dart';

/// Reads and writes the `items` collection and uploads photo evidence to
/// Firebase Storage (Features 2 & 5; real-time sync from Section 9).
class ItemRepository {
  ItemRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection(FirestorePaths.items);

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(FirestorePaths.itemCategories);

  /// Live feed of active, non-deleted items, newest first.
  /// [type] optionally filters to 'lost' or 'found'.
  Stream<List<ItemModel>> watchItems({String? type}) {
    Query<Map<String, dynamic>> q = _items
        .where('isSoftDeleted', isEqualTo: false)
        .where('status', isEqualTo: ItemStatus.active);
    if (type != null) q = q.where('type', isEqualTo: type);
    q = q.orderBy('reportedAt', descending: true);

    return q.snapshots().map(
          (snap) => snap.docs.map(ItemModel.fromDoc).toList(),
        );
  }

  Stream<List<ItemModel>> watchMyItems(String uid) => _items
      .where('reporterId', isEqualTo: uid)
      .where('isSoftDeleted', isEqualTo: false)
      .orderBy('reportedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ItemModel.fromDoc).toList());

  Stream<ItemModel?> watchItem(String id) => _items.doc(id).snapshots().map(
        (doc) => doc.exists ? ItemModel.fromDoc(doc) : null,
      );

  /// Live feed of every non-deleted item regardless of status (active,
  /// claimed or resolved). Sorted client-side by date so the query only needs
  /// the automatic single-field index on `isSoftDeleted`. Powers the Browse
  /// screen's ALL / LOST / FOUND / RETURNED filters.
  Stream<List<ItemModel>> watchAllItems() {
    return _items
        .where('isSoftDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ItemModel.fromDoc).toList();
      list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return list;
    });
  }

  /// One-shot fetch of all active items of a given type — used as the
  /// candidate set for the Gemini matcher.
  Future<List<ItemModel>> fetchActiveByType(String type) async {
    final snap = await _items
        .where('isSoftDeleted', isEqualTo: false)
        .where('status', isEqualTo: ItemStatus.active)
        .where('type', isEqualTo: type)
        .get();
    return snap.docs.map(ItemModel.fromDoc).toList();
  }

  Future<ItemModel?> getById(String id) async {
    final doc = await _items.doc(id).get();
    return doc.exists ? ItemModel.fromDoc(doc) : null;
  }

  /// Uploads image bytes and returns the download URL. Uses [putData] so the
  /// same code path works on web and mobile (no `dart:io` File needed).
  Future<String> uploadImage(Uint8List bytes, String reporterId) async {
    final ref = _storage
        .ref()
        .child('item_images/$reporterId/${_uuid.v4()}.jpg');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  /// Creates a new item document and returns its generated id.
  Future<String> createItem(ItemModel item) async {
    final ref = await _items.add(item.toMap());
    return ref.id;
  }

  Future<void> updateStatus(String itemId, String status) =>
      _items.doc(itemId).update({'status': status});

  /// Soft delete preserves data integrity (Section 9.2.B `isSoftDeleted`).
  Future<void> softDelete(String itemId) =>
      _items.doc(itemId).update({'isSoftDeleted': true});

  /// Loads categories, falling back to defaults on an empty collection.
  Future<List<CategoryModel>> fetchCategories() async {
    final snap = await _categories.orderBy('name').get();
    if (snap.docs.isEmpty) return CategoryModel.defaults;
    return snap.docs.map(CategoryModel.fromDoc).toList();
  }
}

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);
