import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(LanguageDetectionApp());
}

class LanguageDetectionApp extends StatelessWidget {
  const LanguageDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Maestro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'GoogleSans',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
      home: LanguageDetectionPage(),
    );
  }
}

class LanguageDetectionPage extends StatefulWidget {
  const LanguageDetectionPage({super.key});

  @override
  _LanguageDetectionPageState createState() => _LanguageDetectionPageState();
}

class _LanguageDetectionPageState extends State<LanguageDetectionPage>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String _selectedLanguage = 'English';
  String _detectedLanguage = '';
  double _confidence = 0.0;
  bool _isLoading = false;
  late AnimationController _animationController;

  final List<String> _supportedLanguages = [
    'English',
    'French',
    'Telugu',
    'German',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _detectLanguage() async {
    if (_selectedFile == null) {
      _showCustomSnackbar('Please select an audio file first');
      return;
    }

    setState(() {
      _isLoading = true;
      _detectedLanguage = '';
      _confidence = 0.0;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/detect_language'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('audio', _selectedFile!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _detectedLanguage = data['language'];
          _confidence = data['confidence'];
        });

        // Automatically open transcription dialog
        await _showTranscriptionDialog();
      } else {
        _showCustomSnackbar('Error detecting language');
      }
    } catch (e) {
      _showCustomSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTranscriptionDialog() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/transcribe'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('audio', _selectedFile!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Show dialog with transcription
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Audio Transcription',
                style: TextStyle(color: Colors.deepPurple),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Language: ${data['language']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(data['transcription'], style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      } else {
        _showCustomSnackbar('Error transcribing audio');
      }
    } catch (e) {
      _showCustomSnackbar('Error: ${e.toString()}');
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _detectedLanguage = '';
      _confidence = 0.0;
    });
  }

  void _showCustomSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Language Maestro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated Header
              SizedBox(
                height: 200,
                child: Lottie.network(
                  'https://assets2.lottiefiles.com/packages/lf20_UJNc2t.json',
                  controller: _animationController,
                  onLoaded: (composition) {
                    _animationController
                      ..duration = composition.duration
                      ..repeat();
                  },
                ),
              ),
              SizedBox(height: 20),

              // Language Selection Dropdown with Fancy Decoration
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Preferred Language',
                    prefixIcon: Icon(Icons.language, color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.purple.shade50,
                  ),
                  value: _selectedLanguage,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLanguage = newValue!;
                    });
                  },
                  items:
                      _supportedLanguages.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        );
                      }).toList(),
                ),
              ),
              SizedBox(height: 20),

              // File Selection Button with Icon and Text
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file, color: Colors.white),
                label: Text(
                  _selectedFile == null
                      ? 'Select Audio File'
                      : 'Change Audio File',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: _pickAudioFile,
              ),
              SizedBox(height: 16),

              // Selected File Display
              if (_selectedFile != null)
                Chip(
                  avatar: Icon(Icons.audiotrack, color: Colors.deepPurple),
                  label: Text(
                    _selectedFile!.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                  ),
                  deleteIcon: Icon(Icons.clear),
                  onDeleted: _clearSelection,
                ),
              SizedBox(height: 20),

              // Detect Language Button
              ElevatedButton.icon(
                icon: Icon(Icons.language, color: Colors.white),
                label: Text('Detect Language', style: TextStyle(fontSize: 16)),
                onPressed: _detectLanguage,
              ),
              SizedBox(height: 20),

              // Loading Indicator
              if (_isLoading)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      SizedBox(height: 10),
                      Text(
                        'Analyzing Audio...',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),

              // Results Display
              if (_detectedLanguage.isNotEmpty)
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Detected Language',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _detectedLanguage,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
