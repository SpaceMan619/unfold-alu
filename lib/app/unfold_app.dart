import 'package:flutter/material.dart';

import '../features/home/home_shell.dart';
import '../features/auth/auth_gate.dart';
import 'unfold_theme.dart';

class UnfoldApp extends StatelessWidget {
  const UnfoldApp({super.key, this.demoAuthenticated = false});

  final bool demoAuthenticated;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unfold',
      debugShowCheckedModeBanner: false,
      theme: UnfoldTheme.dark,
      home: demoAuthenticated
          ? const HomeShell(demoMode: true)
          : const AuthGate(),
    );
  }
}
