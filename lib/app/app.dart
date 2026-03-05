import 'package:flutter/material.dart';
import 'package:logistics_app/app/router.dart';
import 'package:logistics_app/app/theme.dart';

class App extends StatelessWidget {
  App({super.key});

  final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Некст',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
