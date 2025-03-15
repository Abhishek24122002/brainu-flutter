import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileUploader {
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
}
