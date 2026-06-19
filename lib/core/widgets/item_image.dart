import 'dart:convert';

import 'package:flutter/material.dart';

class ItemImage extends StatelessWidget {
  final String source;
  final double height;
  final double borderRadius;
  final bool showUnavailableLabel;

  const ItemImage({
    super.key,
    required this.source,
    required this.height,
    required this.borderRadius,
    this.showUnavailableLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = source.startsWith('data:image/')
        ? _buildInlineImage()
        : Image.network(
            source,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _loadingPlaceholder();
            },
            errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }

  Widget _buildInlineImage() {
    try {
      final separatorIndex = source.indexOf(',');
      if (separatorIndex == -1) return _errorPlaceholder();

      final bytes = base64Decode(source.substring(separatorIndex + 1));
      return Image.memory(
        bytes,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
      );
    } on FormatException {
      return _errorPlaceholder();
    }
  }

  Widget _loadingPlaceholder() {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
          if (showUnavailableLabel) ...[
            const SizedBox(height: 8),
            const Text('Image unavailable'),
          ],
        ],
      ),
    );
  }
}
