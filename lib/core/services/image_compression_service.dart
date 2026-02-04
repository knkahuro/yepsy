import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for compressing images to reduce storage usage
class ImageCompressionService {
  /// Compression quality levels
  static const int qualityLow = 60;
  static const int qualityMedium = 75;
  static const int qualityHigh = 85;

  /// Maximum dimensions for compressed images
  static const int maxWidth = 1200;
  static const int maxHeight = 1200;

  /// Compress an image file and save it to app directory
  ///
  /// [sourceFile] - The original image file
  /// [quality] - JPEG quality (0-100), defaults to medium (75)
  /// [maxDimension] - Maximum width/height, defaults to 1200px
  ///
  /// Returns the path to the compressed image file
  Future<String> compressImage(
    File sourceFile, {
    int quality = qualityMedium,
    int maxDimension = maxWidth,
  }) async {
    try {
      // Read the image
      final bytes = await sourceFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed (maintain aspect ratio)
      if (image.width > maxDimension || image.height > maxDimension) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxDimension : null,
          height: image.height > image.width ? maxDimension : null,
        );
      }

      // Compress to JPEG
      final compressedBytes = img.encodeJpg(image, quality: quality);

      // Save to app directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'meal_$timestamp.jpg';
      final compressedFile = File(path.join(directory.path, 'meals', filename));

      // Create meals directory if it doesn't exist
      await compressedFile.parent.create(recursive: true);

      // Write compressed image
      await compressedFile.writeAsBytes(compressedBytes);

      // Log compression stats
      final originalSize = bytes.length;
      final compressedSize = compressedBytes.length;
      final savings = ((originalSize - compressedSize) / originalSize * 100)
          .toStringAsFixed(1);
      debugPrint(
          'Image compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} ($savings% savings)');

      return compressedFile.path;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // If compression fails, copy original file
      return _copyOriginalFile(sourceFile);
    }
  }

  /// Compress image from bytes
  Future<Uint8List> compressImageBytes(
    Uint8List bytes, {
    int quality = qualityMedium,
    int maxDimension = maxWidth,
  }) async {
    try {
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        return bytes;
      }

      // Resize if needed
      if (image.width > maxDimension || image.height > maxDimension) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxDimension : null,
          height: image.height > image.width ? maxDimension : null,
        );
      }

      // Compress
      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      debugPrint('Error compressing image bytes: $e');
      return bytes;
    }
  }

  /// Get estimated compressed size without actually compressing
  Future<int> getEstimatedCompressedSize(
    File sourceFile, {
    int quality = qualityMedium,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final originalSize = bytes.length;

      // Rough estimation: JPEG compression typically achieves 70-90% of original size
      // depending on quality
      final estimatedRatio = quality / 100;
      return (originalSize * estimatedRatio).round();
    } catch (e) {
      return 0;
    }
  }

  /// Copy original file if compression fails
  Future<String> _copyOriginalFile(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(sourceFile.path);
    final filename = 'meal_$timestamp$extension';
    final destFile = File(path.join(directory.path, 'meals', filename));

    await destFile.parent.create(recursive: true);
    await sourceFile.copy(destFile.path);

    return destFile.path;
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Delete old compressed images to free up space
  Future<void> cleanupOldImages({int daysToKeep = 90}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mealsDir = Directory(path.join(directory.path, 'meals'));

      if (!await mealsDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final files = await mealsDir.list().toList();

      for (var entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            debugPrint('Deleted old image: ${path.basename(entity.path)}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }

  /// Get total size of all meal images
  Future<int> getTotalImageSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mealsDir = Directory(path.join(directory.path, 'meals'));

      if (!await mealsDir.exists()) return 0;

      int totalSize = 0;
      final files = await mealsDir.list().toList();

      for (var entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
