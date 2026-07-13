part of '../home_shell.dart';

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
