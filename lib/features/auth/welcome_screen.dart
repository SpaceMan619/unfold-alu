part of 'auth_gate.dart';

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
