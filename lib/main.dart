
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const PCShareApp());
}

class PCShareApp extends StatelessWidget {
  const PCShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Direct Link',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const ConnectScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController _ipController = TextEditingController(text: "10.48.202.183:5000");
  bool _isConnected = false;
  String _statusMessage = "Not connected";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndSendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await _uploadFileToServer(file);
    }
  }

  Future<void> _captureAndSendLivePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      File file = File(photo.path);
      await _uploadFileToServer(file);
    }
  }

  Future<void> _uploadFileToServer(File file) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Uploading file...";
    });

    try {
      var uri = Uri.parse('http://${_ipController.text.trim()}/upload');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();

      if (response.statusCode == 302 || response.statusCode == 200) {
        setState(() {
          _statusMessage = "✅ File sent successfully to PC!";
        });
      } else {
        setState(() {
          _statusMessage = "❌ Failed! Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "❌ Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC-Phone Direct Link'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Connect by address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'IP address or hostname',
                      hintText: 'e.g. 10.48.202.183:5000',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(45),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConnected = true;
                        _statusMessage = "Connected to ${_ipController.text}";
                      });
                    },
                    child: const Text("CONNECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: _statusMessage.contains("✅") ? Colors.greenAccent : Colors.orangeAccent),
            ),
            const SizedBox(height: 20),
            if (_isConnected) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _pickAndSendFile,
                icon: const Icon(Icons.folder, color: Colors.white),
                label: const Text("Send File / Document / Song", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _captureAndLivePhoto, // corrected call
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text("Capture Live Photo & Send", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 30),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
