import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileUploader {
  // Upload image from bytes
  Future<String?> uploadBytes(Uint8List bytes, String fileName) async {
    String uploadUrl = 'https://brainu.onrender.com/upload'; // Adjust as needed

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // Field name should match backend expectations
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'png'),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData);
        return jsonData["imageUrl"]; // Adjust based on API response
      } else {
        print("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // Pick a file (image or audio)
  Future<File?> pickFile({required bool isImage}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.audio,
    );

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  // Upload a file (image or audio)
  Future<String?> uploadFile(File file) async {
    bool isAudio = file.path.endsWith(".mp3") ||
        file.path.endsWith(".wav") ||
        file.path.endsWith(".aac");

    String uploadUrl = isAudio
        ? 'https://brainu.onrender.com/upload-audio'
        : 'https://brainu.onrender.com/upload';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.files.add(
        await http.MultipartFile.fromPath(
          isAudio ? 'audio' : 'image',
          file.path,
          contentType: isAudio
              ? MediaType('audio', 'mpeg') // Adjust based on actual format
              : MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData);
        return jsonData["imageUrl"] ?? jsonData["audioUrl"];
      } else {
        print("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}
