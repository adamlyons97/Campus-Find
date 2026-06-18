import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/campus_item.dart';
import '../models/item_claim.dart';
import '../models/profile.dart';
import '../repositories/campus_store.dart';

class FirebaseCampusStore implements CampusStore {
  FirebaseCampusStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection('claims');

  DocumentReference<Map<String, dynamic>> get _profile => _firestore
      .collection('profiles')
      .doc(FirebaseAuth.instance.currentUser?.uid ?? 'default');

  @override
  Future<void> init() async {}

  @override
  Future<Profile> getProfile() async {
    final snapshot = await _profile.get();
    final data = snapshot.data();
    if (data == null) {
      await saveProfile(Profile.fallback);
      return Profile.fallback;
    }
    return Profile.fromMap(data);
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    await _profile.set(profile.toMap()..remove('id'));
  }

  @override
  Future<List<CampusItem>> getItems({
    String query = '',
    ItemStatus? status,
  }) async {
    Query<Map<String, dynamic>> firestoreQuery = _items.orderBy(
      'created_at',
      descending: true,
    );

    if (status != null) {
      firestoreQuery = firestoreQuery.where(
        'status',
        isEqualTo: status.databaseValue,
      );
    }

    final snapshot = await firestoreQuery.get();
    final normalizedQuery = query.trim().toLowerCase();

    final items = snapshot.docs.map((document) {
      final data = Map<String, Object?>.from(document.data());
      data['id'] = int.tryParse(document.id) ?? data['id'];
      return CampusItem.fromMap(data);
    }).toList();

    if (normalizedQuery.isEmpty) {
      return items;
    }

    return items.where((item) {
      return item.title.toLowerCase().contains(normalizedQuery) ||
          item.description.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery) ||
          item.location.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<CampusItem> createItem(CampusItem item) async {
    final id = item.id ?? DateTime.now().microsecondsSinceEpoch;
    final itemWithId = item.copyWith(id: id);
    await _items.doc(id.toString()).set(itemWithId.toMap());
    return itemWithId;
  }

  @override
  Future<void> updateItem(CampusItem item) async {
    final id = item.id;
    if (id == null) {
      throw ArgumentError('Cannot update an item without an id.');
    }
    await _items.doc(id.toString()).set(item.toMap());
  }

  @override
  Future<void> deleteItem(int id) async {
    final batch = _firestore.batch();
    batch.delete(_items.doc(id.toString()));

    final claimRows = await _claims.where('item_id', isEqualTo: id).get();
    for (final claim in claimRows.docs) {
      batch.delete(claim.reference);
    }

    await batch.commit();
  }

  @override
  Future<List<ItemClaim>> getClaims() async {
    final snapshot = await _claims
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs.map((document) {
      final data = Map<String, Object?>.from(document.data());
      data['id'] = int.tryParse(document.id) ?? data['id'];
      return ItemClaim.fromMap(data);
    }).toList();
  }

  @override
  Future<ItemClaim> createClaim(ItemClaim claim) async {
    final id = claim.id ?? DateTime.now().microsecondsSinceEpoch;
    final claimWithId = claim.copyWith(id: id);
    await _claims.doc(id.toString()).set(claimWithId.toMap());
    return claimWithId;
  }

  @override
  Future<void> updateClaim(ItemClaim claim) async {
    final id = claim.id;
    if (id == null) {
      throw ArgumentError('Cannot update a claim without an id.');
    }
    await _claims.doc(id.toString()).set(claim.toMap());
  }
}
