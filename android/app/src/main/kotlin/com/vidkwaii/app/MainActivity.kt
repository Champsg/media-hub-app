package com.vidkwaii.app

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_SCANNER = "media_hub/media_scanner"
        private const val REQUEST_WRITE_STORAGE = 4101
    }

    private var pendingGalleryPath: String? = null
    private var pendingGalleryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SCANNER)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanFile" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_ARGUMENT", "path is required", null)
                        } else {
                            MediaScannerConnection.scanFile(
                                this,
                                arrayOf(path),
                                null,
                                null
                            )
                            result.success(true)
                        }
                    }
                    "scanDir" -> {
                        val dir = call.argument<String>("path")
                        if (dir == null) {
                            result.error("INVALID_ARGUMENT", "path is required", null)
                        } else {
                            val files = File(dir).listFiles() ?: emptyArray()
                            val paths = files.map { it.absolutePath }.toTypedArray()
                            MediaScannerConnection.scanFile(this, paths, null, null)
                            result.success(paths.size)
                        }
                    }
                    "saveToGallery" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_ARGUMENT", "path is required", null)
                        } else {
                            requestGallerySaveIfNeeded(path, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_WRITE_STORAGE) return

        val path = pendingGalleryPath
        val result = pendingGalleryResult
        pendingGalleryPath = null
        pendingGalleryResult = null
        if (path == null || result == null) return

        val granted =
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            result.error(
                "PERMISSION_DENIED",
                "Storage permission is required to save to the gallery on this device.",
                null
            )
        } else {
            respondWithGallerySave(path, result)
        }
    }

    private fun requestGallerySaveIfNeeded(
        path: String,
        result: MethodChannel.Result
    ) {
        val needsLegacyPermission = Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        if (needsLegacyPermission) {
            pendingGalleryPath = path
            pendingGalleryResult = result
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                REQUEST_WRITE_STORAGE
            )
        } else {
            respondWithGallerySave(path, result)
        }
    }

    private fun respondWithGallerySave(
        path: String,
        result: MethodChannel.Result
    ) {
        try {
            val uri = saveToGallery(File(path))
            result.success(uri?.toString())
        } catch (e: Exception) {
            result.error(
                "SAVE_FAILED",
                e.message ?: "Failed to save to gallery",
                null
            )
        }
    }

    /**
     * Exports a downloaded file into the public media collections so gallery
     * apps can see it. Uses MediaStore (works without permissions on
     * Android 10+; falls back to a plain scan on older versions).
     */
    private fun saveToGallery(source: File): Uri? {
        val name = source.name
        val mime = guessMimeType(name)
        val collection = when {
            mime.startsWith("video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            mime.startsWith("audio/") -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            mime.startsWith("image/") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            else -> MediaStore.Files.getContentUri("external")
        }
        val folder = when {
            mime.startsWith("audio/") -> Environment.DIRECTORY_MUSIC
            mime.startsWith("image/") -> Environment.DIRECTORY_PICTURES
            else -> Environment.DIRECTORY_MOVIES
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= 29) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "$folder/VidKwaii")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val uri = contentResolver.insert(collection, values) ?: return null
        try {
            val output = contentResolver.openOutputStream(uri)
                ?: run {
                    contentResolver.delete(uri, null, null)
                    return null
                }
            output.use { out ->
                source.inputStream().use { input -> input.copyTo(out) }
            }
            if (Build.VERSION.SDK_INT >= 29) {
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
            }
        } catch (e: Exception) {
            contentResolver.delete(uri, null, null)
            throw e
        }
        return uri
    }

    private fun guessMimeType(name: String): String {
        val lower = name.lowercase()
        return when {
            lower.endsWith(".mp4") || lower.endsWith(".m4v") || lower.endsWith(".3gp") ->
                "video/mp4"
            lower.endsWith(".mkv") -> "video/x-matroska"
            lower.endsWith(".ts") -> "video/mp2t"
            lower.endsWith(".webm") -> "video/webm"
            lower.endsWith(".mov") -> "video/quicktime"
            lower.endsWith(".mp3") -> "audio/mpeg"
            lower.endsWith(".m4a") -> "audio/mp4"
            lower.endsWith(".aac") -> "audio/aac"
            lower.endsWith(".wav") -> "audio/wav"
            lower.endsWith(".flac") -> "audio/flac"
            lower.endsWith(".ogg") || lower.endsWith(".opus") -> "audio/ogg"
            lower.endsWith(".jpg") || lower.endsWith(".jpeg") -> "image/jpeg"
            lower.endsWith(".png") -> "image/png"
            lower.endsWith(".webp") -> "image/webp"
            lower.endsWith(".gif") -> "image/gif"
            else -> "application/octet-stream"
        }
    }
}
