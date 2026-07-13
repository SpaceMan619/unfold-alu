import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/unfold_theme.dart';
import '../../core/widgets/glass_surface.dart';
import '../home/home_shell.dart';
import 'session_controller.dart';

part 'auth_widgets.dart';
part 'profile_setup_screen.dart';
part 'role_screen.dart';
part 'welcome_screen.dart';

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
