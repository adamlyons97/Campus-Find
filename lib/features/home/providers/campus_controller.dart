import 'package:flutter/foundation.dart';

import '../../../data/models/campus_item.dart';
import '../../../data/models/item_claim.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/campus_store.dart';

enum ItemFilter { all, lost, found, claimed }

extension ItemFilterDetails on ItemFilter {
  String get label {
    switch (this) {
      case ItemFilter.all:
        return 'All';
      case ItemFilter.lost:
        return 'Lost';
      case ItemFilter.found:
        return 'Found';
      case ItemFilter.claimed:
        return 'Claimed';
    }
  }

  ItemStatus? get status {
    switch (this) {
      case ItemFilter.all:
        return null;
      case ItemFilter.lost:
        return ItemStatus.lost;
      case ItemFilter.found:
        return ItemStatus.found;
      case ItemFilter.claimed:
        return ItemStatus.claimed;
    }
  }
}

class CampusController extends ChangeNotifier {
  CampusController(this._store);

  final CampusStore _store;

  bool _isLoading = true;
  String? _errorMessage;
  Profile _profile = Profile.fallback;
  List<CampusItem> _allItems = [];
  List<CampusItem> _visibleItems = [];
  List<ItemClaim> _claims = [];
  String _query = '';
  ItemFilter _filter = ItemFilter.all;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Profile get profile => _profile;
  List<CampusItem> get allItems => List.unmodifiable(_allItems);
  List<CampusItem> get visibleItems => List.unmodifiable(_visibleItems);
  List<ItemClaim> get claims => List.unmodifiable(_claims);
  String get query => _query;
  ItemFilter get filter => _filter;

  int get lostCount =>
      _allItems.where((item) => item.status == ItemStatus.lost).length;

  int get foundCount =>
      _allItems.where((item) => item.status == ItemStatus.found).length;

  int get claimedCount =>
      _allItems.where((item) => item.status == ItemStatus.claimed).length;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _store.init();
      _profile = await _store.getProfile();
      await _refreshData();
    } catch (error) {
      _errorMessage = 'Unable to open CampusFind database: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _refreshData();
    notifyListeners();
  }

  Future<void> setQuery(String value) async {
    _query = value;
    await _refreshData();
    notifyListeners();
  }

  Future<void> setFilter(ItemFilter value) async {
    _filter = value;
    await _refreshData();
    notifyListeners();
  }

  CampusItem? findItem(int id) {
    for (final item in _allItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<ItemClaim> claimsForItem(int itemId) {
    return _claims.where((claim) => claim.itemId == itemId).toList();
  }

  Future<void> createItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required ItemStatus status,
    required String reporterName,
    required String contact,
    String? imageData,
  }) async {
    final now = DateTime.now();
    final item = CampusItem(
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      location: location.trim(),
      status: status,
      reporterName: reporterName.trim(),
      contact: contact.trim(),
      imageData: imageData,
      createdAt: now,
      updatedAt: now,
    );

    await _store.createItem(item);
    await _refreshData();
    notifyListeners();
  }

  Future<void> updateItemStatus(CampusItem item, ItemStatus status) async {
    await _store.updateItem(
      item.copyWith(status: status, updatedAt: DateTime.now()),
    );
    await _refreshData();
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _store.deleteItem(id);
    await _refreshData();
    notifyListeners();
  }

  Future<void> createClaim({
    required CampusItem item,
    required String claimantName,
    required String contact,
    required String message,
  }) async {
    final itemId = item.id;
    if (itemId == null) {
      throw ArgumentError('Cannot create a claim for an unsaved item.');
    }

    await _store.createClaim(
      ItemClaim(
        itemId: itemId,
        claimantName: claimantName.trim(),
        contact: contact.trim(),
        message: message.trim(),
        status: ClaimStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _refreshData();
    notifyListeners();
  }

  Future<void> updateClaimStatus(ItemClaim claim, ClaimStatus status) async {
    await _store.updateClaim(claim.copyWith(status: status));
    await _refreshData();
    notifyListeners();
  }

  Future<void> saveProfile(Profile profile) async {
    await _store.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> _refreshData() async {
    _allItems = await _store.getItems();
    _visibleItems = await _store.getItems(
      query: _query,
      status: _filter.status,
    );
    _claims = await _store.getClaims();
  }
}
