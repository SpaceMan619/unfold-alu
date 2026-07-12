import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/unfold_theme.dart';
import '../../core/widgets/glass_surface.dart';
import '../home/home_shell.dart';
import 'session_controller.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: switch (session.stage) {
        SessionStage.loading => const _LoadingScreen(),
        SessionStage.signedOut => const _WelcomeScreen(),
        SessionStage.chooseRole => const _RoleScreen(),
        SessionStage.onboarding => _ProfileSetup(role: session.role!),
        SessionStage.authenticated => const HomeShell(),
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _UnfoldMark extends StatelessWidget {
  const _UnfoldMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: UnfoldColors.surface,
      borderRadius: BorderRadius.circular(size * .28),
      border: Border.all(color: Colors.white12),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'U',
          style: TextStyle(
            color: UnfoldColors.mint,
            fontSize: size * .58,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        Positioned(
          right: size * .16,
          top: size * .12,
          child: Transform.rotate(
            angle: .18,
            child: Container(
              width: size * .24,
              height: size * .13,
              decoration: BoxDecoration(
                color: UnfoldColors.cyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _WelcomeScreen extends ConsumerStatefulWidget {
  const _WelcomeScreen();

  @override
  ConsumerState<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<_WelcomeScreen> {
  static const messages = [
    'Potential needs\na place to begin.',
    'Discover work\nthat moves you.',
    'Build experience.\nGrow with purpose.',
    'Your next chapter\nstarts at ALU.',
  ];
  Timer? timer;
  int messageIndex = 0;
  bool messageVisible = true;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      setState(() => messageVisible = false);
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      setState(() {
        messageIndex = (messageIndex + 1) % messages.length;
        messageVisible = true;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.7, -0.75),
            radius: 1.25,
            colors: [Color(0xff31584c), UnfoldColors.ink],
            stops: [0, 0.72],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _UnfoldMark(size: 42),
                    const SizedBox(width: 11),
                    const Text(
                      'unfold',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: SizedBox(
                    width: double.infinity,
                    height: (MediaQuery.sizeOf(context).height * .16).clamp(
                      120.0,
                      170.0,
                    ),
                    child: Image.asset(
                      'assets/images/alu-community.jpg',
                      fit: BoxFit.cover,
                      cacheWidth: 1000,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 104,
                  child: AnimatedOpacity(
                    opacity: messageVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        messages[messageIndex],
                        style: const TextStyle(
                          fontSize: 47,
                          height: 0.98,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Discover meaningful work with verified student ventures across the ALU community.',
                  style: TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('get-started'),
                    onPressed: () => ref.read(sessionProvider.notifier).begin(),
                    style: FilledButton.styleFrom(
                      backgroundColor: UnfoldColors.mint,
                      foregroundColor: UnfoldColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Get started'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('google-sign-in'),
                    onPressed: session.isSubmitting
                        ? null
                        : () => ref
                              .read(sessionProvider.notifier)
                              .signInWithGoogle(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                    label: Text(
                      session.isSubmitting
                          ? 'Connecting…'
                          : 'Continue with Google',
                    ),
                  ),
                ),
                if (session.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    session.error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Built for the ALU community',
                    style: TextStyle(color: UnfoldColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.7, -0.8),
            radius: 1.2,
            colors: [Color(0xff25443b), UnfoldColors.ink],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 40, 22, 30),
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: UnfoldColors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(subtitle, style: const TextStyle(color: UnfoldColors.muted)),
              const SizedBox(height: 34),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
