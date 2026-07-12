import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unfold/features/opportunities/bookmark_repository.dart';
import 'package:unfold/features/opportunities/opportunity_controller.dart';

class FakeBookmarkRepository implements BookmarkRepository {
  final controller = StreamController<Set<String>>();
  String? opportunityId;
  bool? saved;

  @override
  Future<void> setSaved(String userId, String opportunityId, bool saved) async {
    this.opportunityId = opportunityId;
    this.saved = saved;
  }

  @override
  Stream<Set<String>> watch(String userId) => controller.stream;
}

void main() {
  test('local bookmarks remain available without Firebase', () async {
    final container = ProviderContainer(
      overrides: [bookmarkRepositoryProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    await container
        .read(opportunityActivityProvider.notifier)
        .toggleSaved('role-1');
    expect(container.read(opportunityActivityProvider).savedIds, {'role-1'});
  });
}
