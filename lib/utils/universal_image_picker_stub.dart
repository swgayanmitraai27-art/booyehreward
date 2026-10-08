import 'dart:typed_data';

class PickedImageData {
  final Uint8List bytes;
  final String name;

  PickedImageData({required this.bytes, required this.name});
}

Future<PickedImageData?> pickImageFromDevice() async {
  throw UnsupportedError('Cannot pick image on unsupported platform.');
}
