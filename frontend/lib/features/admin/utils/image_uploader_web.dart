// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> pickAndUploadImage() async {
  try {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    await uploadInput.onChange.first;
    if (uploadInput.files == null || uploadInput.files!.isEmpty) return null;

    final file = uploadInput.files![0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    final bytes = reader.result as List<int>;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = 'catalog/$fileName';

    final client = Supabase.instance.client;
    await client.storage.from('products').uploadBinary(path, Uint8List.fromList(bytes));

    return client.storage.from('products').getPublicUrl(path);
  } catch (e) {
    rethrow;
  }
}
