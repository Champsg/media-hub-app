import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';

class LocalMediaMerger {
  const LocalMediaMerger();

  /// Merges separate video and audio streams into a single MP4 on the device.
  /// Uses stream copy (-c copy) so this is near-instant and doesn't re-encode.
  Future<bool> mergeVideoAndAudio({
    required String videoPath,
    required String audioPath,
    required String outputPath,
  }) async {
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    // 1. First attempt: stream copy video and mux audio as aac if needed
    final command =
        '-y -i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest "$outputPath"';

    var session = await FFmpegKit.execute(command);
    var returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode) &&
        await outputFile.exists() &&
        (await outputFile.length()) > 0) {
      return true;
    }

    // 2. Fallback attempt: direct stream copy
    final fallbackCommand =
        '-y -i "$videoPath" -i "$audioPath" -c:v copy -c:a copy "$outputPath"';
    session = await FFmpegKit.execute(fallbackCommand);
    returnCode = await session.getReturnCode();

    return ReturnCode.isSuccess(returnCode) &&
        await outputFile.exists() &&
        (await outputFile.length()) > 0;
  }

  /// Converts or extracts audio track locally on device.
  Future<bool> extractAudio({
    required String inputPath,
    required String outputPath,
    String format = 'm4a',
  }) async {
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final command = format == 'mp3'
        ? '-y -i "$inputPath" -vn -c:a libmp3lame -q:a 2 "$outputPath"'
        : '-y -i "$inputPath" -vn -c:a aac -b:a 192k "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    return ReturnCode.isSuccess(returnCode) &&
        await outputFile.exists() &&
        (await outputFile.length()) > 0;
  }
}
