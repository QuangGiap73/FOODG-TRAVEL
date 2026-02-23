import 'package:flutter/material.dart';

import 'package:food_travel/l10n/app_localizations.dart';

class DishDetailLoadingView extends StatelessWidget {
  const DishDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class DishDetailErrorView extends StatelessWidget {
  const DishDetailErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 34),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.commonBack),
            ),
          ],
        ),
      ),
    );
  }
}

class DishDetailNotFoundView extends StatelessWidget {
  const DishDetailNotFoundView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(t.dishNotFound),
      ),
    );
  }
}

