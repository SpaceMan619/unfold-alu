import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/unfold_theme.dart';
import '../../core/widgets/glass_surface.dart';
import '../applications/application.dart';
import '../applications/application_form_sheet.dart';
import '../applications/application_review_controller.dart';
import '../auth/session_controller.dart';
import '../cv/cv_analysis_controller.dart';
import '../opportunities/opportunity.dart';
import '../opportunities/opportunity_controller.dart';
import '../profile/profile_photo_controller.dart';
import '../startups/startup_controller.dart';

part 'views/discover_view.dart';
part 'views/saved_view.dart';
part 'views/applications_view.dart';
part 'views/profile_view.dart';
part 'views/founder_dashboard.dart';
part 'sheets/create_opportunity_sheet.dart';
part 'sheets/opportunity_sheet.dart';
part 'widgets/home_widgets.dart';

enum UserMode { student, founder }

String _todayLabel() {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final now = DateTime.now();
  return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.demoMode = false});
  final bool demoMode;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  UserMode mode = UserMode.student;
  int studentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator.adaptive(
              color: Colors.white,
              onRefresh: _refresh,
              child: mode == UserMode.student
                  ? _studentContent()
                  : _FounderDashboard(
                      onSwitch: _switchMode,
                      onCreate: _showCreateOpportunity,
                      onReview: _showApplicationReview,
                      onEdit: _showEditOpportunity,
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: mode == UserMode.student
          ? _studentNavigation()
          : null,
    );
  }

  Widget _studentContent() {
    final activity = ref.watch(opportunityActivityProvider);
    if (studentTab == 1) {
      return _SavedView(
        items: activity.opportunities
            .where((item) => activity.savedIds.contains(item.id))
            .toList(),
        onOpen: _showOpportunity,
        onUnsave: ref.read(opportunityActivityProvider.notifier).toggleSaved,
      );
    }
    if (studentTab == 2) {
      return _ApplicationsView(
        items: activity.opportunities
            .where((item) => activity.appliedIds.contains(item.id))
            .toList(),
        applications: activity.applications,
      );
    }
    if (studentTab == 3) {
      return _ProfileView(onSwitch: _switchMode);
    }
    return _DiscoverView(
      opportunities: activity.opportunities,
      saved: activity.savedIds,
      onSave: ref.read(opportunityActivityProvider.notifier).toggleSaved,
      onOpen: _showOpportunity,
      onProfile: () => setState(() => studentTab = 3),
      name: widget.demoMode ? 'Rajveer' : ref.watch(sessionProvider).name,
      photoBytes: widget.demoMode
          ? null
          : ref.watch(profilePhotoBytesProvider).value,
      hasCvEvidence: widget.demoMode
          ? false
          : ref.watch(cvAnalysisProvider).hasEvidence,
    );
  }

  Widget _studentNavigation() {
    const items = [
      (Icons.explore_rounded, 'Discover'),
      (Icons.bookmark_rounded, 'Saved'),
      (Icons.work_history_rounded, 'Applications'),
      (Icons.person_rounded, 'Profile'),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: GlassSurface(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            return SizedBox(
              height: 44,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    left: studentTab * itemWidth + 3,
                    top: 0,
                    width: itemWidth - 6,
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: UnfoldColors.mint,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (index) {
                      final selected = studentTab == index;
                      return Expanded(
                        child: Semantics(
                          label: items[index].$2,
                          selected: selected,
                          child: InkWell(
                            key: ValueKey('nav-$index'),
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => setState(() => studentTab = index),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  items[index].$1,
                                  key: ValueKey('$index-$selected'),
                                  color: selected
                                      ? UnfoldColors.ink
                                      : UnfoldColors.muted,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _switchMode() {
    setState(
      () =>
          mode = mode == UserMode.student ? UserMode.founder : UserMode.student,
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(opportunityActivityProvider);
    ref.invalidate(applicationReviewProvider);
    ref.invalidate(startupProvider);
    ref.invalidate(profilePhotoBytesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 650));
  }

  void _showOpportunity(Opportunity opportunity) {
    final activity = ref.read(opportunityActivityProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OpportunitySheet(
        opportunity: opportunity,
        applied: activity.appliedIds.contains(opportunity.id),
        onApply: () => _showApplicationForm(opportunity),
      ),
    );
  }

  Future<void> _showApplicationForm(Opportunity opportunity) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .94,
        minChildSize: .2,
        maxChildSize: .96,
        snap: true,
        snapSizes: const [.2, .94],
        builder: (context, scrollController) => ApplicationFormSheet(
          scrollController: scrollController,
          opportunity: opportunity,
          onSubmit:
              ({
                required motivation,
                required availability,
                required portfolioUrl,
              }) => ref
                  .read(opportunityActivityProvider.notifier)
                  .submitApplication(
                    opportunity: opportunity,
                    motivation: motivation,
                    availability: availability,
                    portfolioUrl: portfolioUrl,
                  ),
        ),
      ),
    );
    if (submitted != true || !mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application submitted — track it in Applications.'),
      ),
    );
  }

  void _showCreateOpportunity() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateOpportunitySheet(
        onCreate: (opportunity) async {
          try {
            await ref
                .read(opportunityActivityProvider.notifier)
                .addOpportunity(opportunity);
            if (!mounted) return;
            Navigator.pop(this.context);
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Opportunity published.')),
            );
          } catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              this.context,
            ).showSnackBar(SnackBar(content: Text(error.toString())));
          }
        },
      ),
    );
  }

  void _showEditOpportunity(Opportunity opportunity) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateOpportunitySheet(
        initial: opportunity,
        onCreate: (updated) async {
          await ref
              .read(opportunityActivityProvider.notifier)
              .updateOpportunity(updated);
          if (mounted) Navigator.pop(this.context);
        },
      ),
    );
  }

  void _showApplicationReview() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ApplicationReviewSheet(),
    );
  }
}
