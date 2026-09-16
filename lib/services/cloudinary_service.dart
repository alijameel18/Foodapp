import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  final String cloudName = 'dd4ltmvcj'; // Replace with your Cloud Name
  final String uploadPreset = 'restaurant_upload'; // Replace with your Unsigned Upload Preset

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      print("Attempting upload to: $cloudName with preset: $uploadPreset");

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        return jsonMap['secure_url'];
      } else {
        // READ THIS MESSAGE IN YOUR CONSOLE 👇
        print("------------------------------------------------");
        print("CLOUDINARY ERROR: ${response.statusCode}");
        print("REASON: ${response.body}");
        print("------------------------------------------------");
        return null;
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }
}