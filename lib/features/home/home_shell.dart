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

class _DiscoverView extends StatefulWidget {
  const _DiscoverView({
    required this.opportunities,
    required this.saved,
    required this.onSave,
    required this.onOpen,
    required this.onProfile,
    required this.name,
    required this.photoBytes,
    required this.hasCvEvidence,
  });

  final List<Opportunity> opportunities;
  final Set<String> saved;
  final ValueChanged<String> onSave;
  final ValueChanged<Opportunity> onOpen;
  final VoidCallback onProfile;
  final String name;
  final Uint8List? photoBytes;
  final bool hasCvEvidence;

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView> {
  static const slogans = [
    'Your next chapter\nis ready to unfold.',
    'Build what matters.\nStart where you are.',
    'Meet the work\nthat moves you forward.',
    'Turn your skills\ninto real momentum.',
    'Find your people.\nShape your path.',
  ];
  String query = '';
  String category = 'All';
  String compensation = 'All';
  int sloganIndex = 0;
  bool sloganVisible = true;
  Timer? sloganTimer;

  @override
  void initState() {
    super.initState();
    sloganTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      setState(() => sloganVisible = false);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        sloganIndex = (sloganIndex + 1) % slogans.length;
        sloganVisible = true;
      });
    });
  }

  @override
  void dispose() {
    sloganTimer?.cancel();
    super.dispose();
  }

  List<Opportunity> get filteredOpportunities {
    return widget.opportunities.where((item) {
      final haystack = [
        item.role,
        item.startup,
        item.summary,
        ...item.skills,
      ].join(' ').toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      final matchesCategory =
          category == 'All' || _categoryFor(item) == category;
      final matchesCompensation =
          compensation == 'All' ||
          (compensation == 'Paid' && item.isPaid) ||
          (compensation == 'Unpaid' && !item.isPaid);
      return matchesQuery && matchesCategory && matchesCompensation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final nameParts = widget.name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    final firstName = nameParts.isEmpty ? 'there' : nameParts.first;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 128),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _todayLabel(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$greeting, $firstName',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onProfile,
              child: CircleAvatar(
                radius: 23,
                backgroundColor: UnfoldColors.amber,
                backgroundImage: widget.photoBytes == null
                    ? null
                    : MemoryImage(widget.photoBytes!),
                child: widget.photoBytes == null
                    ? Text(
                        widget.name
                            .split(' ')
                            .where((p) => p.isNotEmpty)
                            .take(2)
                            .map((p) => p[0].toUpperCase())
                            .join(),
                        style: TextStyle(
                          color: UnfoldColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        SizedBox(
          height: 140,
          child: AnimatedOpacity(
            opacity: sloganVisible ? 1 : 0,
            duration: const Duration(milliseconds: 320),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                slogans[sloganIndex],
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            GlassSurface(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: TextField(
                onChanged: (value) =>
                    setState(() => query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: UnfoldColors.muted),
                  hintText: 'Search roles, skills, or startups',
                  hintStyle: TextStyle(color: UnfoldColors.muted),
                  suffixIcon: SizedBox(width: 42),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Filter opportunities',
                onPressed: _showFilters,
                icon: Icon(
                  Icons.tune_rounded,
                  color: compensation == 'All'
                      ? UnfoldColors.mint
                      : UnfoldColors.amber,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                      'All',
                      'Technology',
                      'Climate',
                      'Community',
                      'Volunteering',
                      'Business',
                    ]
                    .map(
                      (label) => _DiscoveryChip(
                        label: label,
                        selected: category == label,
                        onTap: () => setState(() => category = label),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionHeader(title: 'Explore opportunities', action: 'See all'),
        const SizedBox(height: 14),
        if (!widget.hasCvEvidence) ...[
          const _ProfileMatchBanner(),
          const SizedBox(height: 14),
        ],
        if (filteredOpportunities.isEmpty)
          const _EmptyState(
            icon: Icons.search_off_rounded,
            message: 'No opportunities match those filters yet.',
          ),
        ...filteredOpportunities.map(
          (opportunity) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OpportunityCard(
              opportunity: opportunity,
              saved: widget.saved.contains(opportunity.id),
              onSave: () => widget.onSave(opportunity.id),
              onTap: () => widget.onOpen(opportunity),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFilters() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: UnfoldColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Compensation'),
              subtitle: Text('Show paid, unpaid, or every opportunity.'),
            ),
            for (final option in ['All', 'Paid', 'Unpaid'])
              ListTile(
                title: Text(option),
                trailing: compensation == option
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => compensation = selected);
  }
}

class _ProfileMatchBanner extends StatelessWidget {
  const _ProfileMatchBanner();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.all(15),
      color: UnfoldColors.cyan.withValues(alpha: 0.08),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: UnfoldColors.cyan),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock your matches',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Text(
                  'Add your skills or CV to see what fits — and why.',
                  style: TextStyle(color: UnfoldColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: UnfoldColors.cyan),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.saved,
    required this.onSave,
    required this.onTap,
  });

  final Opportunity opportunity;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: onTap,
      color: opportunity.color.withValues(alpha: 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: opportunity.color,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: opportunity.color.withValues(alpha: .55),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _categoryFor(opportunity).toUpperCase(),
                style: TextStyle(
                  color: opportunity.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: 9),
              _CompensationPill(opportunity: opportunity),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StartupLogo(opportunity: opportunity),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  opportunity.startup,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: opportunity.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Verified',
                  style: TextStyle(
                    color: opportunity.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            opportunity.role,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            opportunity.summary,
            style: const TextStyle(color: UnfoldColors.muted),
          ),
          if (opportunity.skills.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: opportunity.skills.take(3).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .055),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      color: UnfoldColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: UnfoldColors.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  opportunity.location,
                  style: const TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('save-${opportunity.id}'),
                onPressed: onSave,
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: saved ? UnfoldColors.amber : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoveryChip extends StatelessWidget {
  const _DiscoveryChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? UnfoldColors.mint
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? UnfoldColors.mint : Colors.white12,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? UnfoldColors.ink : UnfoldColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

String _categoryFor(Opportunity opportunity) {
  if (opportunity.isVolunteering) return 'Volunteering';
  final text =
      '${opportunity.role} ${opportunity.summary} ${opportunity.skills.join(' ')}'
          .toLowerCase();
  if (RegExp(r'climate|solar|plastic|agri|farmer|energy').hasMatch(text)) {
    return 'Climate';
  }
  if (RegExp(r'community|content|outreach|accessibility').hasMatch(text)) {
    return 'Community';
  }
  if (RegExp(r'flutter|python|iot|api|data|software|figma').hasMatch(text)) {
    return 'Technology';
  }
  return 'Business';
}

class _SavedView extends StatelessWidget {
  const _SavedView({
    required this.items,
    required this.onOpen,
    required this.onUnsave,
  });
  final List<Opportunity> items;
  final ValueChanged<Opportunity> onOpen;
  final ValueChanged<String> onUnsave;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Saved',
      subtitle: 'Keep the possibilities worth returning to.',
      child: items.isEmpty
          ? const _EmptyState(
              icon: Icons.bookmark_border_rounded,
              message: 'Save an opportunity and it will wait for you here.',
            )
          : Column(
              children: items
                  .map(
                    (item) => _SavedOpportunityTile(
                      key: ValueKey('saved-${item.id}'),
                      opportunity: item,
                      onOpen: () => onOpen(item),
                      onUnsave: () => onUnsave(item.id),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SavedOpportunityTile extends StatefulWidget {
  const _SavedOpportunityTile({
    required this.opportunity,
    required this.onOpen,
    required this.onUnsave,
    super.key,
  });

  final Opportunity opportunity;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;

  @override
  State<_SavedOpportunityTile> createState() => _SavedOpportunityTileState();
}

class _SavedOpportunityTileState extends State<_SavedOpportunityTile> {
  bool visible = true;

  Future<void> remove() async {
    if (!visible) return;
    setState(() => visible = false);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    widget.onUnsave();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      child: visible
          ? AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Dismissible(
                key: ValueKey(widget.opportunity.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => widget.onUnsave(),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(right: 24),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.bookmark_remove_rounded),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OpportunityCard(
                    opportunity: widget.opportunity,
                    saved: true,
                    onSave: remove,
                    onTap: widget.onOpen,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ApplicationsView extends StatelessWidget {
  const _ApplicationsView({required this.items, required this.applications});
  final List<Opportunity> items;
  final List<OpportunityApplication> applications;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Applications',
      subtitle: 'Every step, clearly in view.',
      child: items.isEmpty
          ? const _EmptyState(
              icon: Icons.work_outline_rounded,
              message: 'Your application journey will appear here.',
            )
          : Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassSurface(
                        onTap: () {
                          final application = applications
                              .where((value) => value.opportunityId == item.id)
                              .firstOrNull;
                          if (application != null) {
                            _showApplicationDetails(context, item, application);
                          }
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                color: UnfoldColors.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.role,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    item.startup,
                                    style: const TextStyle(
                                      color: UnfoldColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _ApplicationStatusPill(
                              status:
                                  applications
                                      .where(
                                        (value) =>
                                            value.opportunityId == item.id,
                                      )
                                      .firstOrNull
                                      ?.status ??
                                  ApplicationStatus.submitted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

void _showApplicationDetails(
  BuildContext context,
  Opportunity opportunity,
  OpportunityApplication application,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: UnfoldColors.surface,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    opportunity.role,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _ApplicationStatusPill(status: application.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              opportunity.startup,
              style: const TextStyle(color: UnfoldColors.muted),
            ),
            const SizedBox(height: 22),
            _ApplicationTimeline(status: application.status),
            const SizedBox(height: 18),
            Text(
              application.status == ApplicationStatus.accepted
                  ? '${opportunity.startup} will contact you through ${application.studentEmail.isEmpty ? 'your ALU email' : application.studentEmail} with next steps.'
                  : 'Updates will appear here. The organisation will use your ALU email if they need more information.',
              style: const TextStyle(color: UnfoldColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ApplicationTimeline extends StatelessWidget {
  const _ApplicationTimeline({required this.status});
  final ApplicationStatus status;
  @override
  Widget build(BuildContext context) {
    final current = switch (status) {
      ApplicationStatus.submitted => 0,
      ApplicationStatus.reviewing => 1,
      ApplicationStatus.shortlisted => 2,
      ApplicationStatus.accepted => 3,
      ApplicationStatus.rejected => 2,
    };
    const labels = ['Submitted', 'Reviewing', 'Shortlisted', 'Accepted'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              children: [
                Icon(
                  i <= current
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: i <= current ? UnfoldColors.mint : UnfoldColors.muted,
                  size: 22,
                ),
                const SizedBox(height: 5),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: i <= current ? Colors.white : UnfoldColors.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.onSwitch});
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final cv = ref.watch(cvAnalysisProvider);
    final photoBytes = ref.watch(profilePhotoBytesProvider).value;
    final publicProfile =
        ref.watch(publicProfileProvider).value ?? const PublicProfile();
    final initials = session.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 128),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: UnfoldColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: UnfoldColors.amber,
                  backgroundImage: photoBytes == null
                      ? null
                      : MemoryImage(photoBytes),
                  child: photoBytes == null
                      ? Text(
                          initials.isEmpty ? 'U' : initials,
                          style: const TextStyle(
                            color: UnfoldColors.ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final changed = await ref
                        .read(profilePhotoUploaderProvider)
                        .chooseAndUpload();
                    if (changed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile photo updated.')),
                      );
                    }
                  } on FormatException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Photo upload is unavailable right now.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(photoBytes == null ? 'Add photo' : 'Change photo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.name.isEmpty ? 'Unfold member' : session.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: UnfoldColors.cyan,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                session.email,
                style: const TextStyle(color: UnfoldColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 15),
              Text(
                publicProfile.bio.isEmpty
                    ? 'Add a short bio so founders understand what you care about.'
                    : publicProfile.bio,
                style: TextStyle(fontSize: 15, height: 1.45),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _ProfileMeta(
                    icon: Icons.location_on_outlined,
                    label: publicProfile.location,
                  ),
                  _ProfileMeta(
                    icon: Icons.school_outlined,
                    label: 'ALU · Class of ${publicProfile.classYear}',
                  ),
                  if (publicProfile.website.isNotEmpty)
                    _ProfileMeta(
                      icon: Icons.link_rounded,
                      label: publicProfile.website.replaceFirst(
                        RegExp(r'^https?://'),
                        '',
                      ),
                      onTap: () => _openExternalLink(publicProfile.website),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  _ProfileStat(value: '3', label: 'Projects'),
                  SizedBox(width: 24),
                  _ProfileStat(value: '2', label: 'Applications'),
                ],
              ),
              const SizedBox(height: 26),
              _SectionHeader(
                title: 'Profile details',
                action: 'Edit',
                onAction: () => _showSkillsEditor(context, ref, publicProfile),
              ),
              const SizedBox(height: 8),
              const Text(
                'Skills & interests',
                style: TextStyle(
                  color: UnfoldColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (publicProfile.skills.isNotEmpty ||
                  publicProfile.interests.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...publicProfile.skills.map(_SkillChip.new),
                    ...publicProfile.interests.map(
                      (interest) => _SkillChip(interest),
                    ),
                  ],
                )
              else if (cv.hasEvidence)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cv.skills.map(_SkillChip.new).toList(),
                )
              else
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SkillChip('Mobile products'),
                    _SkillChip('Community impact'),
                    _SkillChip('Open to internships'),
                  ],
                ),
              const SizedBox(height: 22),
              _CvIntelligenceCard(cv: cv),
              const SizedBox(height: 14),
              GlassSurface(
                child: const Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: UnfoldColors.mint),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'External profile preview',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'This is what verified founders see when reviewing you.',
                            style: TextStyle(
                              color: UnfoldColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onSwitch,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Switch to founder studio'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Unfold v0.8.0',
                  style: TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 11,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showSkillsEditor(
  BuildContext context,
  WidgetRef ref,
  PublicProfile profile,
) async {
  final skills = TextEditingController(text: profile.skills.join(', '));
  final interests = TextEditingController(text: profile.interests.join(', '));
  final bio = TextEditingController(text: profile.bio);
  final location = TextEditingController(text: profile.location);
  final website = TextEditingController(text: profile.website);
  var classYear = profile.classYear;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Container(
        padding: EdgeInsets.fromLTRB(
          22,
          18,
          22,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: UnfoldColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Skills & interests',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Separate each item with a comma.',
                style: TextStyle(color: UnfoldColors.muted),
              ),
              const SizedBox(height: 18),
              _OpportunityField(
                controller: bio,
                label: 'Bio',
                maxLines: 3,
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: location,
                label: 'Location',
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: classYear,
                decoration: const InputDecoration(
                  labelText: 'Class year',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var year = 2024; year <= 2032; year++)
                    DropdownMenuItem(
                      value: year,
                      child: Text('Class of $year'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => classYear = value);
                },
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: website,
                label: 'Website, GitHub, or portfolio',
                keyboardType: TextInputType.url,
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: skills,
                label: 'Skills',
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: interests,
                label: 'Interests',
                validator: (_) => null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    List<String> parse(String value) => value
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .take(8)
                        .toList();
                    await ref
                        .read(publicProfileEditorProvider)
                        .save(
                          skills: parse(skills.text),
                          interests: parse(interests.text),
                          bio: bio.text,
                          location: location.text,
                          classYear: classYear,
                          website: website.text,
                        );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  skills.dispose();
  interests.dispose();
  bio.dispose();
  location.dispose();
  website.dispose();
}

class _ProfileMeta extends StatelessWidget {
  const _ProfileMeta({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: UnfoldColors.muted),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: UnfoldColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

Future<void> _openExternalLink(String value) async {
  final normalized = value.startsWith('http') ? value : 'https://$value';
  final uri = Uri.tryParse(normalized);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(color: UnfoldColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _CvIntelligenceCard extends ConsumerWidget {
  const _CvIntelligenceCard({required this.cv});

  final CvAnalysisState cv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassSurface(
      color: UnfoldColors.cyan.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.document_scanner_rounded,
                color: UnfoldColors.cyan,
              ),
              const SizedBox(width: 10),
              const Text(
                'CV intelligence',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      (cv.hasEvidence ? UnfoldColors.mint : UnfoldColors.amber)
                          .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  cv.hasEvidence ? 'AI INTEGRATED' : 'AI READY',
                  style: TextStyle(
                    color: cv.hasEvidence
                        ? UnfoldColors.mint
                        : UnfoldColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cv.stage == CvAnalysisStage.selected ||
                    cv.stage == CvAnalysisStage.analyzing
                ? cv.fileName ?? 'CV selected'
                : cv.stage == CvAnalysisStage.ready
                ? cv.summary
                : 'Upload your CV to build an editable skills profile and unlock explainable matches.',
            style: const TextStyle(color: UnfoldColors.muted),
          ),
          const SizedBox(height: 16),
          if (cv.stage == CvAnalysisStage.selected)
            Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: UnfoldColors.mint,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'PDF ready for private analysis',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(cvAnalysisProvider.notifier).removeCv(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(cvAnalysisProvider.notifier).analyze(),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Analyze CV with AI'),
                  ),
                ),
              ],
            )
          else if (cv.stage == CvAnalysisStage.analyzing)
            const Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Reading your CV…'),
              ],
            )
          else if (cv.stage == CvAnalysisStage.ready)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cv.skills
                      .map(
                        (skill) => InputChip(
                          label: Text(skill),
                          onDeleted: () => ref
                              .read(cvAnalysisProvider.notifier)
                              .removeSkill(skill),
                          deleteIcon: const Icon(Icons.close_rounded, size: 15),
                        ),
                      )
                      .toList(),
                ),
                if (cv.suggestedRoles.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Suggested: ${cv.suggestedRoles.join(' · ')}',
                    style: const TextStyle(color: UnfoldColors.cyan),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(cvAnalysisProvider.notifier).selectCv(),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload updated CV'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove CV intelligence',
                      onPressed: () =>
                          ref.read(cvAnalysisProvider.notifier).removeCv(),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            )
          else if (cv.stage == CvAnalysisStage.failed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cv.error ?? 'Analysis failed.',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      ref.read(cvAnalysisProvider.notifier).selectCv(),
                  child: const Text('Choose another PDF'),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(cvAnalysisProvider.notifier).selectCv(),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Choose PDF CV'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FounderDashboard extends ConsumerWidget {
  const _FounderDashboard({
    required this.onSwitch,
    required this.onCreate,
    required this.onReview,
    required this.onEdit,
  });
  final VoidCallback onSwitch;
  final VoidCallback onCreate;
  final VoidCallback onReview;
  final ValueChanged<Opportunity> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(applicationReviewProvider);
    final session = ref.watch(applicationSessionProvider);
    final opportunities = ref
        .watch(opportunityActivityProvider)
        .opportunities
        .where((item) => item.ownerId == session.uid || session.uid.isEmpty)
        .toList();
    final shortlisted = applications
        .where(
          (item) => item.application.status == ApplicationStatus.shortlisted,
        )
        .length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Founder studio',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: onSwitch,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Build your team.\nGrow the mission.',
          style: TextStyle(
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 150,
            child: Image.asset(
              'assets/images/alu-community.jpg',
              fit: BoxFit.cover,
              cacheWidth: 1000,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: '${opportunities.length}',
                label: 'Live roles',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                value: '${applications.length}',
                label: 'Applicants',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (opportunities.isEmpty)
          const GlassSurface(
            child: Text(
              'Your published opportunities will appear here.',
              style: TextStyle(color: UnfoldColors.muted),
            ),
          )
        else
          for (final opportunity in opportunities.take(3)) ...[
            GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: UnfoldColors.cyan,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        opportunity.startup,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          final controller = ref.read(
                            opportunityActivityProvider.notifier,
                          );
                          if (action == 'edit') {
                            onEdit(opportunity);
                          }
                          if (action == 'close') {
                            await controller.closeOpportunity(opportunity.id);
                          }
                          if (action == 'delete') {
                            await controller.deleteOpportunity(opportunity.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'close', child: Text('Close')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    opportunity.role,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${applications.length} applicants · $shortlisted shortlisted',
                    style: const TextStyle(color: UnfoldColors.muted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const ValueKey('review-applicants'),
                      onPressed: onReview,
                      icon: const Icon(Icons.people_alt_rounded),
                      label: const Text('Review applicants'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create opportunity'),
          style: FilledButton.styleFrom(
            backgroundColor: UnfoldColors.mint,
            foregroundColor: UnfoldColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class StartupVerificationCard extends ConsumerWidget {
  const StartupVerificationCard({required this.state, super.key});
  final StartupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = state.profile;
    final verified = profile?.isVerified == true;
    return GlassSurface(
      color: (verified ? UnfoldColors.mint : UnfoldColors.amber).withValues(
        alpha: 0.06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified_rounded : Icons.shield_outlined,
                color: verified ? UnfoldColors.mint : UnfoldColors.amber,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  profile?.name ?? 'Verify your startup',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                verified
                    ? 'Verified'
                    : profile == null
                    ? 'Required'
                    : 'Pending',
                style: TextStyle(
                  color: verified ? UnfoldColors.mint : UnfoldColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verified
                ? (profile?.summary ?? '')
                : 'Submit a short startup profile. Publishing unlocks after verification.',
            style: const TextStyle(color: UnfoldColors.muted),
          ),
          if (profile == null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showStartupForm(context, ref),
              child: const Text('Submit for verification'),
            ),
          ],
        ],
      ),
    );
  }

  void _showStartupForm(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final summary = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Startup verification',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Startup name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: summary,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What are you building?',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty || summary.text.trim().isEmpty) {
                    return;
                  }
                  await ref
                      .read(startupProvider.notifier)
                      .submit(name.text, summary.text);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('Submit profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => GlassSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: UnfoldColors.mint,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: UnfoldColors.muted)),
      ],
    ),
  );
}

class _ApplicationReviewSheet extends ConsumerWidget {
  const _ApplicationReviewSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(applicationReviewProvider);
    return Container(
      margin: const EdgeInsets.only(top: 56),
      decoration: const BoxDecoration(
        color: Color(0xff10201d),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Review applicants',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Text(
              'Move each person through a clear, simple hiring pipeline.',
              style: TextStyle(color: UnfoldColors.muted),
            ),
            const SizedBox(height: 20),
            for (final item in applications) ...[
              _ApplicantCard(item: item),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  const _ApplicantCard({required this.item});

  final FounderApplication item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = item.application.status;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: UnfoldColors.mint.withValues(alpha: 0.14),
                foregroundColor: UnfoldColors.mint,
                child: Text(item.studentName.characters.first),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.location,
                      style: const TextStyle(
                        color: UnfoldColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _ApplicationStatusPill(status: status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.roleTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Text(
            item.application.motivation,
            style: const TextStyle(color: UnfoldColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [for (final skill in item.skills) _SkillChip(skill)],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ApplicationStatus>(
            key: ValueKey('status-${item.application.id}'),
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Application status',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final option in ApplicationStatus.values)
                DropdownMenuItem(
                  value: option,
                  child: Text(_statusLabel(option)),
                ),
            ],
            onChanged: (next) async {
              if (next == null) return;
              try {
                await ref
                    .read(applicationReviewProvider.notifier)
                    .updateStatus(item.application.id, next);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${item.studentName} moved to ${_statusLabel(next).toLowerCase()}.',
                    ),
                  ),
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Status could not be updated. Try again.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ApplicationStatusPill extends StatelessWidget {
  const _ApplicationStatusPill({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ApplicationStatus.accepted => UnfoldColors.mint,
      ApplicationStatus.rejected => Colors.redAccent,
      ApplicationStatus.shortlisted => UnfoldColors.amber,
      ApplicationStatus.reviewing => UnfoldColors.cyan,
      ApplicationStatus.submitted => UnfoldColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _statusLabel(ApplicationStatus status) => switch (status) {
  ApplicationStatus.submitted => 'Submitted',
  ApplicationStatus.reviewing => 'Reviewing',
  ApplicationStatus.shortlisted => 'Shortlisted',
  ApplicationStatus.accepted => 'Accepted',
  ApplicationStatus.rejected => 'Rejected',
};

String _ventureMark(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'U';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

class _CreateOpportunitySheet extends StatefulWidget {
  const _CreateOpportunitySheet({required this.onCreate, this.initial});

  final Future<void> Function(Opportunity) onCreate;
  final Opportunity? initial;

  @override
  State<_CreateOpportunitySheet> createState() =>
      _CreateOpportunitySheetState();
}

class _CreateOpportunitySheetState extends State<_CreateOpportunitySheet> {
  final formKey = GlobalKey<FormState>();
  final startupController = TextEditingController();
  final roleController = TextEditingController();
  final summaryController = TextEditingController();
  final skillsController = TextEditingController();
  final amountController = TextEditingController();
  final contactEmailController = TextEditingController();
  String arrangement = 'Hybrid';
  bool isPaid = false;
  String currency = 'RWF';
  OpportunityType opportunityType = OpportunityType.internship;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      startupController.text = initial.startup;
      roleController.text = initial.role;
      summaryController.text = initial.summary;
      skillsController.text = initial.skills.join(', ');
      isPaid = initial.isPaid;
      currency = initial.currency;
      amountController.text = initial.monthlyAmount?.toStringAsFixed(0) ?? '';
      contactEmailController.text = initial.contactEmail;
      opportunityType = initial.type;
    }
  }

  @override
  void dispose() {
    startupController.dispose();
    roleController.dispose();
    summaryController.dispose();
    skillsController.dispose();
    amountController.dispose();
    contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 56),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff10201d),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create opportunity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Be specific about the work and what the student will learn.',
                style: TextStyle(color: UnfoldColors.muted),
              ),
              const SizedBox(height: 22),
              _OpportunityField(
                controller: startupController,
                label: 'Startup or venture name',
                validator: _required,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: roleController,
                label: 'Role title',
                validator: _required,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: summaryController,
                label: 'What will they work on?',
                maxLines: 3,
                validator: _required,
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: skillsController,
                label: 'Skills, separated by commas',
                validator: _required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<OpportunityType>(
                initialValue: opportunityType,
                decoration: const InputDecoration(
                  labelText: 'Opportunity type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in OpportunityType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.value[0].toUpperCase() + type.value.substring(1),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => opportunityType = value);
                },
              ),
              const SizedBox(height: 12),
              _OpportunityField(
                controller: contactEmailController,
                label: 'Contact email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  return email.isNotEmpty && !email.contains('@')
                      ? 'Enter a valid email'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Paid opportunity'),
                subtitle: Text(
                  isPaid
                      ? 'Add the monthly stipend below.'
                      : 'This role is unpaid.',
                  style: const TextStyle(color: UnfoldColors.muted),
                ),
                value: isPaid,
                activeTrackColor: UnfoldColors.mint,
                onChanged: (value) => setState(() => isPaid = value),
              ),
              if (isPaid) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OpportunityField(
                        controller: amountController,
                        label: 'Monthly amount',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (!isPaid) return null;
                          final amount = double.tryParse(value ?? '');
                          return amount == null || amount <= 0
                              ? 'Enter a valid amount'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'RWF', label: Text('RWF')),
                        ButtonSegment(value: 'USD', label: Text('USD')),
                      ],
                      selected: {currency},
                      onSelectionChanged: (value) =>
                          setState(() => currency = value.first),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Remote', label: Text('Remote')),
                  ButtonSegment(value: 'Hybrid', label: Text('Hybrid')),
                  ButtonSegment(value: 'On-site', label: Text('On-site')),
                ],
                selected: {arrangement},
                onSelectionChanged: (selection) {
                  setState(() => arrangement = selection.first);
                },
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const ValueKey('publish-opportunity'),
                onPressed: submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: UnfoldColors.mint,
                  foregroundColor: UnfoldColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: Text(submitting ? 'Publishing…' : 'Publish opportunity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    final skills = skillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .take(5)
        .toList();
    setState(() => submitting = true);
    await widget.onCreate(
      Opportunity(
        id:
            widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        role: roleController.text.trim(),
        startup: startupController.text.trim(),
        summary: summaryController.text.trim(),
        location: 'Kigali · $arrangement',
        commitment: 'Flexible',
        skills: skills,
        match: 80,
        color: UnfoldColors.cyan,
        ownerId: widget.initial?.ownerId ?? '',
        isPaid: isPaid,
        monthlyAmount: isPaid ? double.parse(amountController.text) : null,
        currency: currency,
        type: opportunityType,
        contactEmail: contactEmailController.text.trim(),
      ),
    );
    if (mounted) setState(() => submitting = false);
  }
}

class _OpportunityField extends StatelessWidget {
  const _OpportunityField({
    required this.controller,
    required this.label,
    required this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}

class _OpportunitySheet extends StatelessWidget {
  const _OpportunitySheet({
    required this.opportunity,
    required this.applied,
    required this.onApply,
  });
  final Opportunity opportunity;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
      decoration: const BoxDecoration(
        color: Color(0xff10201d),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                _StartupLogo(opportunity: opportunity),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.startup,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: UnfoldColors.cyan,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified ALU startup',
                          style: TextStyle(
                            color: UnfoldColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              opportunity.role,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 14),
            Text(
              opportunity.summary,
              style: const TextStyle(color: UnfoldColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _CompensationPanel(opportunity: opportunity),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: opportunity.skills
                  .map((skill) => _SkillChip(skill))
                  .toList(),
            ),
            const SizedBox(height: 28),
            if (opportunity.contactEmail.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri(
                    scheme: 'mailto',
                    path: opportunity.contactEmail,
                    queryParameters: {
                      'subject': 'Question about ${opportunity.role}',
                    },
                  ),
                ),
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Email the organisation'),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'What you will build',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _Reason(
              text:
                  'Contribute to ${opportunity.startup} through real project work.',
            ),
            _Reason(
              text:
                  'Practice ${opportunity.skills.take(2).join(' and ')} with a small team.',
            ),
            _Reason(
              text: '${opportunity.commitment} with clear learning outcomes.',
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: applied ? null : onApply,
              style: FilledButton.styleFrom(
                backgroundColor: UnfoldColors.mint,
                foregroundColor: UnfoldColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
              child: Text(
                applied ? 'Application submitted' : 'Start application',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: UnfoldColors.cyan,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text, style: const TextStyle(color: UnfoldColors.muted)),
        ),
      ],
    ),
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 32),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white12),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        height: 1.15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 128),
    children: [
      Text(title, style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 7),
      Text(subtitle, style: const TextStyle(color: UnfoldColors.muted)),
      const SizedBox(height: 28),
      child,
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => GlassSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(icon, size: 38, color: UnfoldColors.muted),
          const SizedBox(height: 13),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: UnfoldColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            action,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UnfoldColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}

class _StartupLogo extends StatelessWidget {
  const _StartupLogo({required this.opportunity});

  final Opportunity opportunity;

  static const assets = {
    'Kayko': 'assets/logos/kayko.png',
    'Rwazi': 'assets/logos/rwazi.png',
    'Signvrse': 'assets/logos/signvrse.png',
    'Plastic Venture': 'assets/logos/plastic-venture.png',
    'Starlight': 'assets/logos/starlight.png',
    'Smartel Agri-tech': 'assets/logos/smartel-agritech.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = assets[opportunity.startup];
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      padding: asset == null ? EdgeInsets.zero : const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: asset == null ? opportunity.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: asset != null
          ? Center(
              child: Image.asset(asset, fit: BoxFit.contain, cacheWidth: 128),
            )
          : Center(
              child: Text(
                _ventureMark(opportunity.startup),
                style: const TextStyle(
                  color: UnfoldColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
    );
  }
}

class _CompensationPill extends StatelessWidget {
  const _CompensationPill({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final amount = opportunity.monthlyAmount;
    final label = opportunity.isPaid && amount != null
        ? '${opportunity.currency} ${_shortAmount(amount)} / month'
        : opportunity.isVolunteering
        ? 'Volunteer'
        : 'Unpaid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: opportunity.isPaid
            ? UnfoldColors.mint.withValues(alpha: .14)
            : Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: opportunity.isPaid ? UnfoldColors.mint : UnfoldColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompensationPanel extends StatelessWidget {
  const _CompensationPanel({required this.opportunity});
  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final amount = opportunity.monthlyAmount;
    final paid = opportunity.isPaid && amount != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paid
            ? UnfoldColors.mint.withValues(alpha: .09)
            : UnfoldColors.amber.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (paid ? UnfoldColors.mint : UnfoldColors.amber).withValues(
            alpha: .22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (paid ? UnfoldColors.mint : UnfoldColors.amber).withValues(
                alpha: .14,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              paid
                  ? Icons.payments_outlined
                  : opportunity.isVolunteering
                  ? Icons.volunteer_activism_outlined
                  : Icons.school_outlined,
              color: paid ? UnfoldColors.mint : UnfoldColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid
                      ? '${opportunity.currency} ${_shortAmount(amount)} per month'
                      : opportunity.isVolunteering
                      ? 'Volunteer opportunity'
                      : 'Unpaid learning opportunity',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  paid ? 'Monthly compensation' : 'No financial compensation',
                  style: const TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortAmount(double amount) {
  if (amount >= 1000 && amount % 1000 == 0) {
    return '${(amount / 1000).toStringAsFixed(0)}K';
  }
  return amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.75),
          radius: 1.15,
          colors: [Color(0x334f4f57), UnfoldColors.ink],
          stops: [0, 0.72],
        ),
      ),
    ),
  );
}
