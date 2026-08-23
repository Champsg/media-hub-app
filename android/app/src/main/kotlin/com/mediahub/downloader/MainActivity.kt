package com.mediahub.downloader

import android.app.Activity
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_SCANNER = "media_hub/media_scanner"
        private const val CHANNEL_SAF = "media_hub/saf"
        private const val REQ_OPEN_TREE = 6001
    }

    private var pendingTreeResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ------------------------------------------------------------------
        // MediaScanner platform channel: immediate gallery indexing
        // ------------------------------------------------------------------
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
                    else -> result.notImplemented()
                }
            }

        // ------------------------------------------------------------------
        // SAF platform channel: WhatsApp status vault (tree pick + copy)
        // ------------------------------------------------------------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SAF)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDirectory" -> {
                        if (pendingTreeResult != null) {
                            result.error("BUSY", "A folder picker is already open", null)
                        } else {
                            pendingTreeResult = result
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                            intent.addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                            )
                            startActivityForResult(intent, REQ_OPEN_TREE)
                        }
                    }
                    "listTree" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString == null) {
                            result.error("INVALID_ARGUMENT", "uri is required", null)
                        } else {
                            try {
                                result.success(listChildren(Uri.parse(uriString)))
                            } catch (e: Exception) {
                                result.error(
                                    "LIST_FAILED",
                                    e.message ?: "Failed to list directory",
                                    null
                                )
                            }
                        }
                    }
                    "copyTo" -> {
                        val src = call.argument<String>("srcUri")
                        val dest = call.argument<String>("destPath")
                        if (src == null || dest == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "srcUri and destPath are required",
                                null
                            )
                        } else {
                            try {
                                val copied = copyContent(Uri.parse(src), File(dest))
                                MediaScannerConnection.scanFile(
                                    this,
                                    arrayOf(dest),
                                    null,
                                    null
                                )
                                result.success(if (copied) dest else null)
                            } catch (e: Exception) {
                                result.error(
                                    "COPY_FAILED",
                                    e.message ?: "Failed to copy file",
                                    null
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Android, but still the simplest path for OPEN_DOCUMENT_TREE")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_OPEN_TREE) {
            val result = pendingTreeResult ?: return
            pendingTreeResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri = data.data!!
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                } catch (_: SecurityException) {
                    // Permission not persistable — the app can still use the
                    // tree for the duration of the session.
                }
                result.success(uri.toString())
            } else {
                result.error("CANCELLED", "Folder selection was cancelled", null)
            }
        }
    }

    private fun listChildren(uri: Uri): List<Map<String, Any?>> {
        val children = mutableListOf<Map<String, Any?>>()
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val mimeIndex =
                cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
            val docIdIndex =
                cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)

            while (cursor.moveToNext()) {
                val name =
                    if (nameIndex >= 0) cursor.getString(nameIndex) ?: "Untitled" else "Untitled"
                val mime =
                    if (mimeIndex >= 0) cursor.getString(mimeIndex) ?: "" else ""
                val docId = if (docIdIndex >= 0) cursor.getString(docIdIndex) else null
                val size =
                    if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) cursor.getLong(sizeIndex)
                    else -1L
                val childUri =
                    if (docId != null) DocumentsContract.buildDocumentUriUsingTree(uri, docId)
                    else uri

                children.add(
                    mapOf(
                        "name" to name,
                        "mimeType" to mime,
                        "uri" to childUri.toString(),
                        "isDirectory" to (mime == DocumentsContract.Document.MIME_TYPE_DIR),
                        "size" to size
                    )
                )
            }
        }
        return children
    }

    private fun copyContent(src: Uri, dest: File): Boolean {
        dest.parentFile?.mkdirs()
        val input = contentResolver.openInputStream(src) ?: return false
        input.use { stream ->
            FileOutputStream(dest).use { output ->
                stream.copyTo(output)
            }
        }
        return true
    }
}
