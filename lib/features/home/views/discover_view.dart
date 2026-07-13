part of '../home_shell.dart';

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
    final visibleOpportunities = filteredOpportunities;
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
        const SizedBox(height: 24),
        SizedBox(
          height: 112,
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Explore opportunities',
          action: '${visibleOpportunities.length} open',
        ),
        const SizedBox(height: 14),
        if (visibleOpportunities.isEmpty) ...[
          const _EmptyState(
            icon: Icons.search_off_rounded,
            message: 'No opportunities match those filters yet.',
          ),
          if (!widget.hasCvEvidence) ...[
            const SizedBox(height: 14),
            const _ProfileMatchBanner(),
          ],
        ],
        for (final (index, opportunity) in visibleOpportunities.indexed) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OpportunityCard(
              opportunity: opportunity,
              saved: widget.saved.contains(opportunity.id),
              onSave: () => widget.onSave(opportunity.id),
              onTap: () => widget.onOpen(opportunity),
            ),
          ),
          if (index == 1 && !widget.hasCvEvidence) ...[
            const _ProfileMatchBanner(),
            const SizedBox(height: 14),
          ],
        ],
        if (visibleOpportunities.length == 1 && !widget.hasCvEvidence)
          const _ProfileMatchBanner(),
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
      radius: 26,
      padding: const EdgeInsets.all(16),
      color: opportunity.color.withValues(alpha: 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StartupLogo(opportunity: opportunity),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            opportunity.startup,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: opportunity.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _categoryFor(opportunity).toUpperCase(),
                      style: TextStyle(
                        color: opportunity.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('save-${opportunity.id}'),
                tooltip: saved ? 'Remove bookmark' : 'Save opportunity',
                visualDensity: VisualDensity.compact,
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
          const SizedBox(height: 15),
          Text(
            opportunity.role,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _OpportunityFact(
                icon: _opportunityTypeIcon(opportunity.type),
                label: _opportunityTypeLabel(opportunity.type),
              ),
              _OpportunityFact(
                icon: Icons.location_on_outlined,
                label: opportunity.location,
              ),
              _CompensationPill(opportunity: opportunity),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            opportunity.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: UnfoldColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (opportunity.skills.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: opportunity.skills.take(3).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
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
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: .08), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: UnfoldColors.muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  opportunity.commitment,
                  style: const TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                'View details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 15),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpportunityFact extends StatelessWidget {
  const _OpportunityFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: UnfoldColors.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: UnfoldColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
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

String _opportunityTypeLabel(OpportunityType type) {
  return switch (type) {
    OpportunityType.internship => 'Internship',
    OpportunityType.job => 'Job',
    OpportunityType.volunteering => 'Volunteer',
    OpportunityType.project => 'Project',
  };
}

IconData _opportunityTypeIcon(OpportunityType type) {
  return switch (type) {
    OpportunityType.internship => Icons.school_outlined,
    OpportunityType.job => Icons.work_outline_rounded,
    OpportunityType.volunteering => Icons.volunteer_activism_outlined,
    OpportunityType.project => Icons.rocket_launch_outlined,
  };
}
