import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

enum UploadSourceType { camera, gallery, file }

enum UploadItemState { uploading, success, failure }

class PickedUploadFile {
  const PickedUploadFile({
    required this.id,
    required this.name,
    required this.path,
    required this.sourceType,
    required this.state,
    required this.isImage,
    this.sizeLabel,
    this.errorMessage,
    this.progress = 0.48,
  });

  final String id;
  final String name;
  final String path;
  final UploadSourceType sourceType;
  final UploadItemState state;
  final bool isImage;
  final String? sizeLabel;
  final String? errorMessage;
  final double progress;

  PickedUploadFile copyWith({
    String? id,
    String? name,
    String? path,
    UploadSourceType? sourceType,
    UploadItemState? state,
    bool? isImage,
    String? sizeLabel,
    Object? errorMessage = _sentinel,
    double? progress,
  }) {
    return PickedUploadFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      sourceType: sourceType ?? this.sourceType,
      state: state ?? this.state,
      isImage: isImage ?? this.isImage,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      progress: progress ?? this.progress,
    );
  }

  static const Object _sentinel = Object();
}

class UploadPickerUtils {
  UploadPickerUtils._();

  static final ImagePicker _imagePicker = ImagePicker();

  static Future<List<PickedUploadFile>> pickFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null) {
      return const <PickedUploadFile>[];
    }
    return <PickedUploadFile>[
      _buildUploadFile(
        path: image.path,
        sourceType: UploadSourceType.camera,
        name: image.name,
      ),
    ];
  }

  static Future<List<PickedUploadFile>> pickFromGallery() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 90,
    );
    if (images.isEmpty) {
      return const <PickedUploadFile>[];
    }
    return images
        .map(
          (XFile image) => _buildUploadFile(
            path: image.path,
            sourceType: UploadSourceType.gallery,
            name: image.name,
          ),
        )
        .toList();
  }

  static Future<List<PickedUploadFile>> pickFromFiles() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
    );
    if (result == null) {
      return const <PickedUploadFile>[];
    }

    return result.files
        .where((PlatformFile file) => file.path != null)
        .map(
          (PlatformFile file) => _buildUploadFile(
            path: file.path!,
            sourceType: UploadSourceType.file,
            name: file.name,
            sizeBytes: file.size,
          ),
        )
        .toList();
  }

  static PickedUploadFile _buildUploadFile({
    required String path,
    required UploadSourceType sourceType,
    String? name,
    int? sizeBytes,
  }) {
    final int resolvedSizeBytes = sizeBytes ?? readFileSize(path);
    final String resolvedName = (name == null || name.isEmpty)
        ? basename(path)
        : name;
    return PickedUploadFile(
      id: '${DateTime.now().microsecondsSinceEpoch}_${path.hashCode}',
      name: resolvedName,
      path: path,
      sourceType: sourceType,
      state: UploadItemState.success,
      isImage: isImagePath(path),
      sizeLabel: resolvedSizeBytes > 0 ? formatFileSize(resolvedSizeBytes) : null,
    );
  }

  static String basename(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  static int readFileSize(String path) {
    try {
      final File file = File(path);
      if (!file.existsSync()) {
        return 0;
      }
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  static bool isImagePath(String path) {
    final String normalizedPath = path.toLowerCase();
    return normalizedPath.endsWith('.jpg') ||
        normalizedPath.endsWith('.jpeg') ||
        normalizedPath.endsWith('.png') ||
        normalizedPath.endsWith('.webp') ||
        normalizedPath.endsWith('.gif') ||
        normalizedPath.endsWith('.heic') ||
        normalizedPath.endsWith('.heif');
  }

  static String formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0KB';
    }
    if (bytes < 1024 * 1024) {
      final double kb = bytes / 1024;
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)}KB';
    }
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)}MB';
  }
}
