part of 'auth_gate.dart';

class _RoleScreen extends ConsumerWidget {
  const _RoleScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return _AuthScaffold(
      eyebrow: 'Your path',
      title: 'How will you use Unfold?',
      subtitle:
          'Your experience will be shaped around the work you want to do.',
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * 0.16),
        child: Column(
          children: [
            _RoleCard(
              icon: Icons.school_rounded,
              title: 'I am a student',
              description:
                  'Find opportunities, apply, and grow your portfolio.',
              onTap: session.isSubmitting
                  ? () {}
                  : () {
                      if (session.awaitingGoogleRole) {
                        ref
                            .read(sessionProvider.notifier)
                            .completeGoogleProfile(AccountRole.student);
                      } else {
                        ref
                            .read(sessionProvider.notifier)
                            .chooseRole(AccountRole.student);
                      }
                    },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.rocket_launch_rounded,
              title: 'I am building a startup',
              description: 'Get verified, publish roles, and discover talent.',
              onTap: session.isSubmitting
                  ? () {}
                  : () {
                      if (session.awaitingGoogleRole) {
                        ref
                            .read(sessionProvider.notifier)
                            .completeGoogleProfile(AccountRole.founder);
                      } else {
                        ref
                            .read(sessionProvider.notifier)
                            .chooseRole(AccountRole.founder);
                      }
                    },
            ),
            if (session.isSubmitting) ...[
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ],
            if (session.error != null) ...[
              const SizedBox(height: 14),
              Text(
                session.error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: UnfoldColors.mint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: UnfoldColors.mint),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: UnfoldColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: UnfoldColors.muted),
        ],
      ),
    );
  }
}
