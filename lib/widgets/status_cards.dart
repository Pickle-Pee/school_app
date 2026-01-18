import 'package:flutter/material.dart';
import 'package:school_test_app/theme/app_theme.dart';

/// Единый стиль для пустых состояний/ошибок/лоадеров.
///
/// Используй эти виджеты вместо локальных _ErrorCard/_InfoCard,
/// чтобы типографика и цвета не выбивались из общего дизайна.

class _BaseStatusCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? message;
  final Widget? action;

  const _BaseStatusCard({
    required this.leading,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null && message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

class AppLoadingCard extends StatelessWidget {
  final String text;

  const AppLoadingCard({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _BaseStatusCard(
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: 'Загрузка',
      message: text,
    );
  }
}

class AppEmptyCard extends StatelessWidget {
  final String text;
  final IconData icon;

  const AppEmptyCard({
    Key? key,
    required this.text,
    this.icon = Icons.inbox_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _BaseStatusCard(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: 'Нет данных',
      message: text,
    );
  }
}

class AppInfoCard extends StatelessWidget {
  final String text;
  final IconData icon;

  const AppInfoCard({
    Key? key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _BaseStatusCard(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: 'Информация',
      message: text,
    );
  }
}

class AppErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const AppErrorCard({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _BaseStatusCard(
      leading: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
      title: 'Ошибка',
      message: error,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            ),
    );
  }
}
