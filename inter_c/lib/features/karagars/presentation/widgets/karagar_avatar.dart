import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class KaragarAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final double borderWidth;

  const KaragarAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  String _resolveImageUrl(String url) {
    final imageUri = Uri.parse(url);
    if (imageUri.hasScheme) return imageUri.toString();

    final baseUrl = AppConstants.apiBaseUrl.endsWith('/')
        ? AppConstants.apiBaseUrl
        : '${AppConstants.apiBaseUrl}/';
    final relativePath = url.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse(baseUrl).resolve(relativePath).toString();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: foregroundColor,
          ),
        ),
      ),
    );
    final image = imageUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      foregroundDecoration: borderColor == null
          ? null
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor!, width: borderWidth),
            ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: image == null || image.trim().isEmpty
            ? fallback
            : Image.network(
                _resolveImageUrl(image),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}
