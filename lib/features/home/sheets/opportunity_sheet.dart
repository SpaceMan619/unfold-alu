part of '../home_shell.dart';

class _OpportunitySheet extends StatelessWidget {
  const _OpportunitySheet({
    required this.opportunity,
    required this.applied,
    required this.onApply,
    required this.scrollController,
    required this.userSkills,
    required this.related,
    required this.onOpenRelated,
  });

  final Opportunity opportunity;
  final bool applied;
  final VoidCallback onApply;
  final ScrollController scrollController;
  final List<String> userSkills;
  final List<Opportunity> related;
  final ValueChanged<Opportunity> onOpenRelated;

  @override
  Widget build(BuildContext context) {
    final match = OpportunityMatch.of(opportunity, userSkills);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: UnfoldColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 116),
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
                // Identity + the same ring that was on the card (Hero-shared).
                Row(
                  children: [
                    _StartupLogo(opportunity: opportunity),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opportunity.startup,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: opportunity.color,
                              ),
                              const SizedBox(width: 4),
                              const Flexible(
                                child: Text(
                                  'Verified ALU startup',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: UnfoldColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Hero(
                      tag: 'match-ring-${opportunity.id}',
                      child: MatchRing(
                        score: match.score,
                        color: opportunity.color,
                        hasSignal: match.hasSignal,
                        size: 54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  opportunity.role,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  opportunity.summary,
                  style: const TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _SheetLedger(opportunity: opportunity),
                const SizedBox(height: 4),
                _WhyYouMatch(opportunity: opportunity, match: match),
                const _SheetLabel('What you\'ll build'),
                _Reason(
                  text:
                      'Ship real project work for ${opportunity.startup}, not busywork.',
                ),
                if (opportunity.skills.isNotEmpty)
                  _Reason(
                    text:
                        'Practise ${opportunity.skills.take(2).join(' and ')} alongside a small team.',
                  ),
                _Reason(
                  text:
                      '${opportunity.commitment} with clear, reviewable learning outcomes.',
                ),
                if (opportunity.contactEmail.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _AskRow(opportunity: opportunity),
                ],
                if (related.isNotEmpty) ...[
                  const _SheetLabel('More like this'),
                  _RelatedRow(
                    related: related,
                    userSkills: userSkills,
                    onOpen: onOpenRelated,
                  ),
                ],
              ],
            ),
            // Apply never scrolls away.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _SheetActionBar(applied: applied, onApply: onApply),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pay · time · place — the three questions a student asks first, as a single
/// grouped strip with tabular figures.
class _SheetLedger extends StatelessWidget {
  const _SheetLedger({required this.opportunity});
  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final amount = opportunity.monthlyAmount;
    final paid = opportunity.isPaid && amount != null;
    final payValue = paid
        ? _shortAmount(amount)
        : opportunity.isVolunteering
        ? 'Volunteer'
        : 'Unpaid';
    final payUnit = paid ? '${opportunity.currency}/mo' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: [
          _LedgerCell(
            label: 'Pay',
            value: payValue,
            unit: payUnit,
            highlight: paid,
          ),
          _ledgerDivider(),
          _LedgerCell(label: 'Time', value: opportunity.commitment),
          _ledgerDivider(),
          _LedgerCell(label: 'Place', value: opportunity.location),
        ],
      ),
    );
  }

  Widget _ledgerDivider() => Container(
    width: 1,
    height: 30,
    color: Colors.white.withValues(alpha: .08),
  );
}

class _LedgerCell extends StatelessWidget {
  const _LedgerCell({
    required this.label,
    required this.value,
    this.unit = '',
    this.highlight = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .4),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlight ? UnfoldColors.mint : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: const TextStyle(
                  color: UnfoldColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The match score, explained. Cites each skill the student already has and is
/// honest about the gap instead of padding the card with template sentences.
class _WhyYouMatch extends StatelessWidget {
  const _WhyYouMatch({required this.opportunity, required this.match});
  final Opportunity opportunity;
  final OpportunityMatch match;

  @override
  Widget build(BuildContext context) {
    if (!match.hasSignal) {
      return Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: UnfoldColors.cyan.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: UnfoldColors.cyan.withValues(alpha: .18)),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: UnfoldColors.cyan),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add your CV in Profile to see exactly how this role fits you.',
                  style: TextStyle(color: UnfoldColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetLabel('Why you match — ${match.score}%'),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: opportunity.color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: opportunity.color.withValues(alpha: .2)),
          ),
          child: Column(
            children: [
              for (final signal in match.breakdown)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: signal == match.breakdown.last ? 0 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        signal.have
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 17,
                        color: signal.have
                            ? opportunity.color
                            : UnfoldColors.amber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: signal.skill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: signal.have
                                    ? ' — already on your profile'
                                    : ' — new for you, learn on the job',
                                style: const TextStyle(
                                  color: UnfoldColors.muted,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AskRow extends StatelessWidget {
  const _AskRow({required this.opportunity});
  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => launchUrl(
        Uri(
          scheme: 'mailto',
          path: opportunity.contactEmail,
          queryParameters: {
            'subject': 'Question regarding (${opportunity.role}) on Unfold.',
          },
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .09)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: UnfoldColors.cyan,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ask ${opportunity.startup} a question',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: UnfoldColors.cyan,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skill-adjacent listings so a "no" flows into the next option.
class _RelatedRow extends StatelessWidget {
  const _RelatedRow({
    required this.related,
    required this.userSkills,
    required this.onOpen,
  });

  final List<Opportunity> related;
  final List<String> userSkills;
  final ValueChanged<Opportunity> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: related.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = related[index];
          final score = OpportunityMatch.of(item, userSkills).score;
          return GestureDetector(
            onTap: () => onOpen(item),
            child: Container(
              width: 210,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .09)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.startup,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: UnfoldColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (score > 0)
                        Text(
                          '$score%',
                          style: TextStyle(
                            color: item.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.role,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: UnfoldColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SheetActionBar extends StatelessWidget {
  const _SheetActionBar({required this.applied, required this.onApply});
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            UnfoldColors.surface.withValues(alpha: 0),
            UnfoldColors.surface,
            UnfoldColors.surface,
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: FilledButton(
        onPressed: applied ? null : onApply,
        style: FilledButton.styleFrom(
          backgroundColor: UnfoldColors.mint,
          foregroundColor: UnfoldColors.ink,
          disabledBackgroundColor: Colors.white.withValues(alpha: .1),
          disabledForegroundColor: UnfoldColors.muted,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Text(
          applied ? 'Application submitted' : 'Start application',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 24, 0, 11),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: .4),
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    ),
  );
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
