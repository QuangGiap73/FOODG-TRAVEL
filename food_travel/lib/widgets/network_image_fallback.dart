import 'package:flutter/material.dart';

Widget networkImageErrorBuilder(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) {
  final theme = Theme.of(context);
  return Container(
    color: theme.colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      Icons.broken_image_outlined,
      size: 32,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}
