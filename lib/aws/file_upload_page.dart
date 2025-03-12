// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:amplify_flutter/amplify_flutter.dart';
// import 'package:amplify_storage_s3/amplify_storage_s3.dart';
// import 'package:image_picker/image_picker.dart';
// import 'credentials.dart';

// class ImageUploadScreen extends StatefulWidget {
//   @override
//   _ImageUploadScreenState createState() => _ImageUploadScreenState();
// }

// class _ImageUploadScreenState extends State<ImageUploadScreen> {
//   File? _selectedImage;
//   double _uploadProgress = 0.0;
//   bool _isUploading = false;

//   Future<void> pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No image selected')));
//       return;
//     }

//     setState(() {
//       _selectedImage = File(pickedFile.path);
//     });
//   }

//   Future<void> uploadImage() async {
//     if (_selectedImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image first')));
//       return;
//     }

//     setState(() {
//       _isUploading = true;
//       _uploadProgress = 0.0;
//     });

//     try {
//       final result = await Amplify.Storage.uploadFile(
//         localFile: AWSFile.fromPath(_selectedImage!.path),
//         path: StoragePath.fromString('public/${_selectedImage!.path.split('/').last}'),
//         onProgress: (progress) {
//           setState(() {
//             _uploadProgress = progress.fractionCompleted;
//           });
//         },
//       ).result;

//       setState(() {
//         _isUploading = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Successful: ${result.uploadedItem.path}')));
//     } on StorageException catch (e) {
//       setState(() {
//         _isUploading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: ${e.message}')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Upload Image to AWS S3')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _selectedImage != null
//                 ? Image.file(_selectedImage!, width: 200, height: 200, fit: BoxFit.cover)
//                 : Icon(Icons.image, size: 100, color: Colors.grey),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: pickImage,
//               child: Text('Pick Image'),
//             ),
//             SizedBox(height: 10),
//             _isUploading
//                 ? Column(
//                     children: [
//                       LinearProgressIndicator(value: _uploadProgress),
//                       SizedBox(height: 10),
//                       Text('${(_uploadProgress * 100).toStringAsFixed(2)}% uploaded'),
//                     ],
//                   )
//                 : ElevatedButton(
//                     onPressed: uploadImage,
//                     child: Text('Upload Image'),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
