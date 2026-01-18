import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';

PreferredSizeWidget appHeader(
  String title, {
  BuildContext? context,
  List<Widget>? actions,
  bool showBack = true,
  String fallbackRoute = '/home',
}) {
  final canPop = context != null ? Navigator.of(context).canPop() : false;

  return AppBar(
    title: Text(title),
    centerTitle: false,
    elevation: 0,
    actions: actions,
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context == null) return;

              if (canPop) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(fallbackRoute);
              }
            },
          )
        : null,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
    ),
  );
}
