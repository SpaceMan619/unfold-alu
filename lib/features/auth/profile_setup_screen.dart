part of 'auth_gate.dart';

class _ProfileSetup extends ConsumerStatefulWidget {
  const _ProfileSetup({required this.role});

  final AccountRole role;

  @override
  ConsumerState<_ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends ConsumerState<_ProfileSetup> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: 'Rajveer Singh Jolly');
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role == AccountRole.student;
    final session = ref.watch(sessionProvider);
    return _AuthScaffold(
      eyebrow: isStudent ? 'Student profile' : 'Founder profile',
      title: isStudent
          ? 'What are you growing into?'
          : 'Tell us who is building.',
      subtitle: isStudent
          ? 'Start simple. You can add your CV and skills later.'
          : 'Startup verification comes after your personal account.',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _Field(
              controller: nameController,
              label: 'Full name',
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: emailController,
              label: 'ALU email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim().toLowerCase() ?? '';
                final isAluEmail =
                    email.endsWith('@alustudent.com') ||
                    email.endsWith('@alueducation.com');
                return isAluEmail ? null : 'Use your ALU email address';
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: passwordController,
              label: 'Password',
              obscureText: true,
              validator: (value) =>
                  (value?.length ?? 0) < 6 ? 'Use at least 6 characters' : null,
            ),
            if (session.error != null) ...[
              const SizedBox(height: 14),
              Text(
                session.error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('complete-profile'),
                onPressed: session.isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        await ref
                            .read(sessionProvider.notifier)
                            .register(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                            );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: UnfoldColors.mint,
                  foregroundColor: UnfoldColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: session.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('google-sign-in-onboarding'),
                onPressed: session.isSubmitting
                    ? null
                    : () =>
                          ref.read(sessionProvider.notifier).signInWithGoogle(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                label: const Text('Use Google instead'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
