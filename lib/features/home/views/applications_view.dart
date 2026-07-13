part of '../home_shell.dart';

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
