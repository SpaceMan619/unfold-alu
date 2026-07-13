part of '../home_shell.dart';

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
