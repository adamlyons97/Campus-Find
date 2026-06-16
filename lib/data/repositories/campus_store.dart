import '../models/campus_item.dart';
import '../models/item_claim.dart';
import '../models/profile.dart';

abstract class CampusStore {
  Future<void> init();

  Future<Profile> getProfile();

  Future<void> saveProfile(Profile profile);

  Future<List<CampusItem>> getItems({String query = '', ItemStatus? status});

  Future<CampusItem> createItem(CampusItem item);

  Future<void> updateItem(CampusItem item);

  Future<void> deleteItem(int id);

  Future<List<ItemClaim>> getClaims();

  Future<ItemClaim> createClaim(ItemClaim claim);

  Future<void> updateClaim(ItemClaim claim);
}
