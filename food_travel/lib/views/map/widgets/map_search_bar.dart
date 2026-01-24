import 'package:flutter/material.dart';

import '../../../services/map/places_service.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    required this.controller,
    required this.loading,
    required this.suggestions,
    required this.onQueryChanged,
    required this.onClear,
    required this.onSelect,
  });

  final TextEditingController controller;
  final bool loading;
  final List<GoongPrediction> suggestions;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<GoongPrediction> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search input.
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search place...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return ListTile(
                  title: Text(item.description),
                  onTap: () => onSelect(item),
                );
              },
            ),
          ),
      ],
    );
  }
}
