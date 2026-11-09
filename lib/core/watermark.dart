import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Menempelkan watermark pada foto absensi: nama, toko, waktu, koordinat, jarak.
Uint8List addAttendanceWatermark({
  required Uint8List photoBytes,
  required String name,
  required String store,
  required String timestamp,
  required double latitude,
  required double longitude,
  required double distanceMeters,
}) {
  var image = img.decodeImage(photoBytes);
  if (image == null) return photoBytes;

  if (image.width > 900) {
    image = img.copyResize(image, width: 900);
  }

  final lines = <String>[
    '$name | $store',
    timestamp,
    'Lat ${latitude.toStringAsFixed(6)}, Lng ${longitude.toStringAsFixed(6)}',
    'Jarak ${distanceMeters.toStringAsFixed(0)} m',
  ];

  const fontSize = 24;
  final lineHeight = fontSize + 8;
  final bandHeight = lineHeight * lines.length + 14;

  img.fillRect(
    image,
    x1: 0,
    y1: image.height - bandHeight,
    x2: image.width,
    y2: image.height,
    color: img.ColorRgba8(0, 0, 0, 150),
  );

  for (var i = 0; i < lines.length; i++) {
    img.drawString(
      image,
      lines[i],
      font: img.arial24,
      x: 10,
      y: image.height - bandHeight + 8 + i * lineHeight,
      color: img.ColorRgba8(255, 255, 255, 255),
    );
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}
