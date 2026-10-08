import 'package:image_picker/image_picker.dart';
import 'universal_image_picker_stub.dart';

export 'universal_image_picker_stub.dart' show PickedImageData;

Future<PickedImageData?> pickImageFromDevice() async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      return PickedImageData(bytes: bytes, name: picked.name);
    }
  } catch (_) {}
  return null;
}
