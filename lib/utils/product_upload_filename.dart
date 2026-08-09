import 'package:path/path.dart' as p;

const _allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

/// Temporary multipart filename; server assigns the final unique product path.
String productUploadFilename(String filePath) {
  final rawExt = p.extension(filePath).toLowerCase();
  final ext = _allowedExtensions.contains(rawExt)
      ? (rawExt == '.jpeg' ? '.jpg' : rawExt)
      : '.jpg';
  return '${DateTime.now().millisecondsSinceEpoch}$ext';
}
