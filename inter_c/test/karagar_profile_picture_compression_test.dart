import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:inter_c/features/karagars/presentation/utils/karagar_profile_picture.dart';

void main() {
  test('large photos are compressed below the upload threshold', () {
    final image = img.Image(width: 1024, height: 1024);
    final random = Random(42);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgb(
          x,
          y,
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
      }
    }

    final original = Uint8List.fromList(img.encodePng(image));
    expect(original.length, greaterThan(maxKaragarProfilePictureBytes));

    final compressed = normalizeKaragarProfilePicture(original);
    expect(compressed, isNotNull);
    expect(
        compressed!.length, lessThanOrEqualTo(maxKaragarProfilePictureBytes));
    expect(compressed[0], 0xFF);
    expect(compressed[1], 0xD8);
  });

  test('small photos are left unchanged', () {
    final smallImage = Uint8List.fromList([1, 2, 3]);

    expect(normalizeKaragarProfilePicture(smallImage), same(smallImage));
  });

  test('unsupported oversized data is rejected', () {
    final unsupportedImage = Uint8List(maxKaragarProfilePictureBytes + 1);

    expect(normalizeKaragarProfilePicture(unsupportedImage), isNull);
  });
}
