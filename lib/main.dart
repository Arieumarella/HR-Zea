import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/blocked_page.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_shell.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ApiClient.instance.init();

      final container = ProviderContainer();
      try {
        await container.read(authProvider.notifier).bootstrap();
      } catch (_) {
        // Bootstrapping tidak boleh mematikan aplikasi.
      }

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const ZeaHrApp(),
        ),
      );
    },
    (error, stack) {
      // Tangkap error zona agar tidak force-close.
      // ignore: avoid_print
      print('Uncaught error: $error');
    },
  );
}

class ZeaHrApp extends ConsumerWidget {
  const ZeaHrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'Zea HR',
      debugShowCheckedModeBanner: false,
      theme: buildZeaTheme(),
      home: switch (auth.status) {
        AuthStatus.unknown => const _SplashScreen(),
        AuthStatus.loggedOut => const LoginPage(),
        AuthStatus.blocked => const BlockedPage(),
        AuthStatus.loggedIn => const HomeShell(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 110, height: 110),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
