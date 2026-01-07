import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';

PreferredSizeWidget appHeader(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(title),
    centerTitle: false,
    elevation: 0,
    actions: actions,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
    ),
  );
}
