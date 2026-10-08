// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'universal_image_picker_stub.dart';

export 'universal_image_picker_stub.dart' show PickedImageData;

Future<PickedImageData?> pickImageFromDevice() async {
  final completer = Completer<PickedImageData?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        if (reader.result != null) {
          final bytes = reader.result as Uint8List;
          completer.complete(PickedImageData(bytes: bytes, name: file.name));
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((e) {
        completer.complete(null);
      });
      reader.readAsArrayBuffer(file);
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
