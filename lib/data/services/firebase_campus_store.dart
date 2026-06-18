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

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _currentEmail =>
      FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase() ?? '';

  bool _isOwnerData(Map<String, dynamic>? data, String uid) {
    if (data == null) {
      return false;
    }
    final ownerUid = data['owner_uid'] as String? ?? '';
    if (ownerUid.isNotEmpty) {
      return ownerUid == uid;
    }
    final contact = (data['contact'] as String? ?? '').trim().toLowerCase();
    return _currentEmail.isNotEmpty && contact == _currentEmail;
  }

  String _requireUid() {
    final uid = _currentUid;
    if (uid.isEmpty) {
      throw StateError('You must be signed in to perform this action.');
    }
    return uid;
  }

  @override
  Future<void> init() async {}

  @override
  Future<Profile> getProfile() async {
    if (_currentUid.isEmpty) {
      return Profile.fallback;
    }
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
    _requireUid();
    await _profile.set(profile.toMap()..remove('id'));
  }

  @override
  Future<List<CampusItem>> getItems({
    String query = '',
    ItemStatus? status,
  }) async {
    if (_currentUid.isEmpty) {
      return const [];
    }
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

    final items = <CampusItem>[];
    for (final document in snapshot.docs) {
      final data = Map<String, Object?>.from(document.data());
      data['id'] = int.tryParse(document.id) ?? data['id'];
      if ((data['owner_uid'] as String? ?? '').isEmpty &&
          _isOwnerData(document.data(), _currentUid)) {
        data['owner_uid'] = _currentUid;
        try {
          await document.reference.update({'owner_uid': _currentUid});
        } catch (_) {
          // The UI can still recognize legacy ownership by email until the
          // updated Firestore rules are published.
        }
      }
      items.add(CampusItem.fromMap(data));
    }

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
    final uid = _requireUid();
    final id = item.id ?? DateTime.now().microsecondsSinceEpoch;
    final itemWithId = item.copyWith(id: id, ownerUid: uid);
    await _items.doc(id.toString()).set(itemWithId.toMap());
    return itemWithId;
  }

  @override
  Future<void> updateItem(CampusItem item) async {
    final uid = _requireUid();
    final id = item.id;
    if (id == null) {
      throw ArgumentError('Cannot update an item without an id.');
    }
    final existing = await _items.doc(id.toString()).get();
    if (!_isOwnerData(existing.data(), uid)) {
      throw StateError('Only the reporter can update this item.');
    }
    await _items.doc(id.toString()).set(item.copyWith(ownerUid: uid).toMap());
  }

  @override
  Future<void> deleteItem(int id) async {
    final uid = _requireUid();
    final existing = await _items.doc(id.toString()).get();
    if (!_isOwnerData(existing.data(), uid)) {
      throw StateError('Only the reporter can delete this item.');
    }
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
    if (_currentUid.isEmpty) {
      return const [];
    }
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
    final uid = _requireUid();
    final item = await _items.doc(claim.itemId.toString()).get();
    final ownerUid = item.data()?['owner_uid'] as String? ?? '';
    if (ownerUid == uid || _isOwnerData(item.data(), uid)) {
      throw StateError('The reporter cannot claim their own item.');
    }
    final id = claim.id ?? DateTime.now().microsecondsSinceEpoch;
    final claimWithId = claim.copyWith(id: id, claimantUid: uid);
    await _claims.doc(id.toString()).set(claimWithId.toMap());
    return claimWithId;
  }

  @override
  Future<void> updateClaim(ItemClaim claim) async {
    final uid = _requireUid();
    final id = claim.id;
    if (id == null) {
      throw ArgumentError('Cannot update a claim without an id.');
    }
    final item = await _items.doc(claim.itemId.toString()).get();
    if (!_isOwnerData(item.data(), uid)) {
      throw StateError('Only the reporter can review this claim.');
    }
    await _claims.doc(id.toString()).set(claim.toMap());
  }
}
