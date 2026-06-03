import 'package:flutter/material.dart';

/// Affiche une bottom sheet limitée à 560px de large sur tablette.
Future<T?> showResponsiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  final w = MediaQuery.of(context).size.width;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    constraints: w >= 600
        ? const BoxConstraints(maxWidth: 560)
        : const BoxConstraints(),
    builder: builder,
  );
}
