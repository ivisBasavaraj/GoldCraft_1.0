import 'dart:typed_data';

import 'package:image/image.dart' as img;

const maxKaragarProfilePictureBytes = 750 * 1024;

Uint8List? normalizeKaragarProfilePicture(Uint8List bytes) {
  if (bytes.length <= maxKaragarProfilePictureBytes) return bytes;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final longestSide =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  for (final maxSide in [1200, 1024, 800, 640]) {
    final targetSide = maxSide < longestSide ? maxSide : longestSide;
    final resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: targetSide)
        : img.copyResize(decoded, height: targetSide);
    for (final quality in [80, 70, 60, 50]) {
      final compressed =
          Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      if (compressed.length <= maxKaragarProfilePictureBytes) {
        return compressed;
      }
    }
  }

  return null;
}
