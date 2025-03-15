import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedFile;
  String? _uploadedFileUrl;

  // Function to pick an image or audio file
  Future<void> _pickFile(bool isImage) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // Function to upload the selected file to AWS S3
  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No file selected'), backgroundColor: Colors.red),
      );
      return;
    }

    bool isAudio = _selectedFile!.path.endsWith(".mp3") ||
        _selectedFile!.path.endsWith(".wav") ||
        _selectedFile!.path.endsWith(".aac");

    String uploadUrl = isAudio
        ? 'https://brainu.onrender.com/upload-audio'
        : 'https://brainu.onrender.com/upload';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.files.add(
        await http.MultipartFile.fromPath(
          isAudio ? 'audio' : 'image',
          _selectedFile!.path,
          contentType:
              isAudio ? MediaType('audio', 'mpeg') : MediaType('image', 'jpeg'),
        ),
      );

      // Debugging: Print request details
      print("Uploading to: $uploadUrl");
      print("File path: ${_selectedFile!.path}");

      var response = await request.send();

      // Read response data
      var responseData = await response.stream.bytesToString();
      print("Response Code: ${response.statusCode}");
      print("Response Data: $responseData");

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData);
        setState(() {
          _uploadedFileUrl = jsonData["imageUrl"] ?? jsonData["audioUrl"];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload successful!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload to AWS S3")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Pick Image or Audio Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickFile(true),
                  icon: Icon(Icons.image),
                  label: Text("Pick Image"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickFile(false),
                  icon: Icon(Icons.audiotrack),
                  label: Text("Pick Audio"),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Show selected file
            _selectedFile != null
                ? Text("Selected: ${_selectedFile!.path.split('/').last}")
                : Text("No file selected"),

            SizedBox(height: 20),

            // Upload button
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text("Upload"),
            ),

            SizedBox(height: 20),

            // Show uploaded file URL
            _uploadedFileUrl != null
                ? SelectableText("Uploaded File URL: $_uploadedFileUrl")
                : Container(),
          ],
        ),
      ),
    );
  }
}
