import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_saver/file_saver.dart' as saver;

typedef ProgressCallback = void Function(int received, int total);

class DownloadService {
  final Dio _dio = Dio();

  /// Downloads a file from url and saves it with fileName.
  /// Returns the saved file path on success.
  Future<String> downloadToDevice({
    required String url,
    required String fileName,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    // Ensure filename is safe
    final safeName = _sanitize(fileName);

    // We'll try to save to Downloads on Android if possible; if that fails (permissions/scoped storage),
    // we fall back to the app documents directory which doesn't require special permissions.
    final primaryDir = await _getPreferredDownloadDirectory();
    final primaryPath = p.join(primaryDir.path, safeName);

    try {
      if (Platform.isAndroid) {
        // Use MediaStore via FileSaver so the file lands in the Downloads collection
        final resp = await _dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
          ),
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
        );
        final bytes = Uint8List.fromList(resp.data ?? []);
        final mime = _inferMimeType(safeName);
        final savedName = await saver.FileSaver.instance.saveAs(
          name: p.basenameWithoutExtension(safeName),
          ext: p.extension(safeName).replaceFirst('.', ''),
          bytes: bytes,
          mimeType: saver.MimeType.other,
          customMimeType: mime,
        );
        return savedName ?? primaryPath;
      } else {
        await _dio.download(
          url,
          primaryPath,
          onReceiveProgress: onProgress,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
          ),
        );
        return primaryPath;
      }
    } on DioException catch (e) {
      // If auth-protected, try fetching bytes then writing
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        try {
          final bytes = await _fetchBytes(url, cancelToken: cancelToken);
          if (Platform.isAndroid) {
            // Save to public Downloads via MediaStore
            final mime = _inferMimeType(safeName);
            final savedName = await saver.FileSaver.instance.saveAs(
              name: p.basenameWithoutExtension(safeName),
              ext: p.extension(safeName).replaceFirst('.', ''),
              bytes: bytes,
              mimeType: saver.MimeType.other,
              customMimeType: mime,
            );
            return savedName ?? primaryPath;
          } else {
            // iOS/macOS: write to app documents dir
            final fallbackDir = await getApplicationDocumentsDirectory();
            final fallbackPath = p.join(fallbackDir.path, safeName);
            await File(fallbackPath).writeAsBytes(bytes);
            return fallbackPath;
          }
        } catch (_) {
          rethrow;
        }
      }
      // If saving to primary path failed (likely due to storage permissions), retry in app documents dir
      final fallbackDir = await getApplicationDocumentsDirectory();
      final fallbackPath = p.join(fallbackDir.path, safeName);
      try {
        if (Platform.isAndroid) {
          // Try FileSaver into Downloads as a fallback as well
          final bytes = await _fetchBytes(url, cancelToken: cancelToken);
          final mime = _inferMimeType(safeName);
          final savedName = await saver.FileSaver.instance.saveAs(
            name: p.basenameWithoutExtension(safeName),
            ext: p.extension(safeName).replaceFirst('.', ''),
            bytes: bytes,
            mimeType: saver.MimeType.other,
            customMimeType: mime,
          );
          return savedName ?? fallbackPath;
        } else {
          await _dio.download(
            url,
            fallbackPath,
            onReceiveProgress: onProgress,
            cancelToken: cancelToken,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
            ),
          );
          return fallbackPath;
        }
      } on DioException catch (e2) {
        // Last resort, fetch bytes then write to fallback
        if (e2.response?.statusCode == 403 || e2.response?.statusCode == 401) {
          final bytes = await _fetchBytes(url, cancelToken: cancelToken);
          await File(fallbackPath).writeAsBytes(bytes);
          return fallbackPath;
        }
        rethrow;
      }
    } catch (_) {
      // Non-Dio exception (e.g., FileSystemException) -> try fallback path with bytes
      final fallbackDir = await getApplicationDocumentsDirectory();
      final fallbackPath = p.join(fallbackDir.path, safeName);
      final bytes = await _fetchBytes(url, cancelToken: cancelToken);
      await File(fallbackPath).writeAsBytes(bytes);
      return fallbackPath;
    }
  }

  String _inferMimeType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Try to resolve a Downloads directory on Android, or documents dir elsewhere.
  Future<Directory> _getPreferredDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Attempt to use public Downloads directory
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
    }
    // iOS and fallback: app documents directory
    return await getApplicationDocumentsDirectory();
  }

  Future<Uint8List> _fetchBytes(String url, {CancelToken? cancelToken}) async {
    final resp = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
    );
    return Uint8List.fromList(resp.data ?? []);
  }

  /// Optionally request permissions for legacy Android saves. Not strictly required for app dir.
  Future<bool> ensurePermissions() async {
    // Not required for MediaStore saves; keep as no-op on Android.
    return true;
  }

  String _sanitize(String name) {
    final trimmed = name.trim().isEmpty ? 'file' : name.trim();
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}
