import '../models/campus_item.dart';
import '../models/item_claim.dart';
import '../models/profile.dart';
import '../repositories/campus_store.dart';

class MemoryCampusStore implements CampusStore {
  MemoryCampusStore.seeded()
    : _profile = Profile.fallback,
      _items = [],
      _claims = [];

  Profile _profile;
  final List<CampusItem> _items;
  final List<ItemClaim> _claims;
  int _nextItemId = 1;
  int _nextClaimId = 100;

  @override
  Future<void> init() async {}

  @override
  Future<Profile> getProfile() async => _profile;

  @override
  Future<void> saveProfile(Profile profile) async {
    _profile = profile;
  }

  @override
  Future<List<CampusItem>> getItems({
    String query = '',
    ItemStatus? status,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();

    return _items.where((item) {
      final matchesStatus = status == null || item.status == status;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.description.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery) ||
          item.location.toLowerCase().contains(normalizedQuery);
      return matchesStatus && matchesQuery;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<CampusItem> createItem(CampusItem item) async {
    final itemWithId = item.copyWith(id: _nextItemId++);
    _items.add(itemWithId);
    return itemWithId;
  }

  @override
  Future<void> updateItem(CampusItem item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      return;
    }
    _items[index] = item;
  }

  @override
  Future<void> deleteItem(int id) async {
    _items.removeWhere((item) => item.id == id);
    _claims.removeWhere((claim) => claim.itemId == id);
  }

  @override
  Future<List<ItemClaim>> getClaims() async {
    return _claims.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ItemClaim> createClaim(ItemClaim claim) async {
    final claimWithId = claim.copyWith(id: _nextClaimId++);
    _claims.add(claimWithId);
    return claimWithId;
  }

  @override
  Future<void> updateClaim(ItemClaim claim) async {
    final index = _claims.indexWhere((existing) => existing.id == claim.id);
    if (index == -1) {
      return;
    }
    _claims[index] = claim;
  }
}
