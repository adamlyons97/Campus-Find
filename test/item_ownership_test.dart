import 'package:flutter_test/flutter_test.dart';

import 'package:campusfind/data/models/campus_item.dart';
import 'package:campusfind/data/models/item_claim.dart';
import 'package:campusfind/data/models/profile.dart';
import 'package:campusfind/data/services/memory_campus_store.dart';
import 'package:campusfind/features/home/providers/campus_controller.dart';

void main() {
  test('only reporter updates status and another user claims', () async {
    final controller = CampusController(MemoryCampusStore.seeded());
    await controller.load();

    await controller.saveProfile(
      const Profile(
        name: 'Owner',
        email: 'owner@campus.edu',
        phone: '+60111111111',
        campus: 'Main Campus',
      ),
    );
    await controller.createItem(
      title: 'Blue Bottle',
      description: 'Blue bottle with a white cap',
      category: 'Bottle',
      location: 'Library',
      status: ItemStatus.lost,
      reporterName: 'Owner',
      contact: 'owner@campus.edu',
    );

    final item = controller.allItems.single;
    expect(item.ownerUid, 'owner@campus.edu');
    expect(controller.isItemOwner(item), isTrue);
    await expectLater(
      controller.createClaim(
        item: item,
        claimantName: 'Owner',
        contact: 'owner@campus.edu',
        message: 'This is mine',
      ),
      throwsStateError,
    );

    await controller.saveProfile(
      const Profile(
        name: 'Claimant',
        email: 'claimant@campus.edu',
        phone: '+60222222222',
        campus: 'Main Campus',
      ),
    );
    expect(controller.canClaimItem(item), isTrue);
    await expectLater(
      controller.updateItemStatus(item, ItemStatus.found),
      throwsStateError,
    );
    await controller.createClaim(
      item: item,
      claimantName: 'Claimant',
      contact: 'claimant@campus.edu',
      message: 'The white cap has my initials.',
    );

    final claim = controller.claimsForItem(item.id!).single;
    expect(claim.claimantUid, 'claimant@campus.edu');
    await expectLater(
      controller.updateClaimStatus(claim, ClaimStatus.approved),
      throwsStateError,
    );

    await controller.saveProfile(
      const Profile(
        name: 'Owner',
        email: 'owner@campus.edu',
        phone: '+60111111111',
        campus: 'Main Campus',
      ),
    );
    await controller.updateItemStatus(item, ItemStatus.claimed);
    await controller.updateClaimStatus(claim, ClaimStatus.approved);

    expect(controller.findItem(item.id!)?.status, ItemStatus.claimed);
    expect(controller.findItem(item.id!)?.resolvedLabel, 'Received');
    expect(
      controller.claimsForItem(item.id!).single.status,
      ClaimStatus.approved,
    );
    await controller.deleteItem(item.id!);
    expect(controller.findItem(item.id!), isNull);

    controller.dispose();
  });

  test('legacy report supports another claimant and email owner', () async {
    final store = MemoryCampusStore.seeded();
    final now = DateTime.now();
    final legacyItem = await store.createItem(
      CampusItem(
        title: 'Found Wallet',
        description: 'Black wallet',
        category: 'Wallet',
        location: 'Cafeteria',
        status: ItemStatus.found,
        reporterName: 'Owner',
        contact: 'owner@campus.edu',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final controller = CampusController(store);
    await controller.load();

    await controller.saveProfile(
      const Profile(
        name: 'Claimant',
        email: 'claimant@campus.edu',
        phone: '+60222222222',
        campus: 'Main Campus',
      ),
    );
    expect(controller.canClaimItem(legacyItem), isTrue);
    await controller.createClaim(
      item: legacyItem,
      claimantName: 'Claimant',
      contact: 'claimant@campus.edu',
      message: 'The wallet contains my student card.',
    );
    expect(controller.claimsForItem(legacyItem.id!).length, 1);

    await controller.saveProfile(
      const Profile(
        name: 'Owner',
        email: 'owner@campus.edu',
        phone: '+60111111111',
        campus: 'Main Campus',
      ),
    );
    expect(controller.isItemOwner(legacyItem), isTrue);
    expect(legacyItem.resolvedLabel, 'Returned');
    expect(controller.claimsForItem(legacyItem.id!).length, 1);
    await controller.deleteItem(legacyItem.id!);
    expect(controller.findItem(legacyItem.id!), isNull);

    controller.dispose();
  });
}
