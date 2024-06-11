import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:translator/translator.dart';


String prevtranscription = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBudjYLis32Z9oDoVEOOFkxqL8DGcfKcNQ',
      appId: '1:195039826381:android:4f568463141e3053f87484',
      messagingSenderId: '195039826381',
      projectId: 'specz-d79eb',
      databaseURL: 'https://specz-d79eb-default-rtdb.firebaseio.com/',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech to Text',
      home: SpeechToTextScreen(),
    );
  }
}

class SpeechToTextScreen extends StatefulWidget {
  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _transcription = '';
  final List<String> _transcriptionBuffer = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _requestPermissions();
  }

  void _initSpeechToText() {
    _speechToText.initialize(
      onStatus: (status) {},
      onError: (error) {
        print('Speech recognition error: $error');
      },
    );
  }

  void _startListening() async {
    if (!_isListening) {
      _transcriptionBuffer.clear();
      _isListening = true;
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        _stopListening();
        _startListening();
      });
      try {
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _transcription = result.recognizedWords;
              print(_transcription);
            });
          },
        );
      } catch (e) {
        print('Error starting speech recognition: $e');
      }
    }
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
    });
    _timer?.cancel();
    _speechToText.stop();
    _processTranscription();
    _startListening();
  }

  void stopListening() async {
    setState(() {
      _isListening = false;
    });
    _timer?.cancel();
    _speechToText.stop();
    _processTranscription();
  }

  void _processTranscription() {
    // Send the current transcription to Firebase
    _sendToFirebase(_transcription);
    _transcription = '';
    // Clear the transcription for the next batch
  }

  void _sendToFirebase(String transcription) {
    
    
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference().child('transcriptions');
    //_databaseReference.child(timestamp).set({'transcription': transcription});
    // String? newPostKey = _databaseReference.child('values').push().key;
    _databaseReference.child('data').set({'transcription':transcription});
    _databaseReference.child(timestamp).set({'transcription': transcription});


    // Data to be saved
    // Map<String, dynamic> postData = {
    //   'timestamp': timestamp,
    //   'content': transcription,
    // };

    // Save data to Firebase Realtime Database
    
    //transcription = transcription.substring(prevtranscription.length).trim();
    // _databaseReference.child('data').set({'transcription': transcription});
    // ref.push().set(postData);
    prevtranscription = transcription;
    transcription = '';
    _transcription = '';
  }

  void _requestPermissions() async {
    if (await Permission.microphone.request().isGranted &&
        await Permission.speech.request().isGranted) {
      // Microphone and speech permissions granted, you can proceed with speech recognition
    } else {
      // Permissions denied, handle the error or show a message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech to Text'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _transcription,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isListening ? stopListening : _startListening,
              child: Text(_isListening ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
  items: const <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mic),
      label: 'Record',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.language), // or use a different icon for translation
      label: 'Translate',
    ),
  ],
  currentIndex: 0, // set the initial index
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.black,
  onTap: (int index) {
    // Handle navigation
    if (index == 0) {
      // Do nothing or navigate to home
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecordPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TranslatePage()),
      );
    }
  },
),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Map<dynamic, dynamic>> transcriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchTranscriptions();
  }

  void _fetchTranscriptions() {
  final DatabaseReference transcriptionsRef =
      FirebaseDatabase.instance.reference().child('transcriptions');

  transcriptionsRef.onValue.listen((DatabaseEvent event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      List<Map<dynamic, dynamic>> entries = data.entries.map((entry) {
        return {
          'key': entry.key,
          'transcription': entry.value['transcription'],
        };
      }).toList();

      // Sort the list based on timestamps in descending order
      entries.sort((a, b) {
        // Check if both keys are numbers
        if (RegExp(r'^-?[0-9]+$').hasMatch(a['key']) &&
            RegExp(r'^-?[0-9]+$').hasMatch(b['key'])) {
          return int.parse(b['key']).compareTo(int.parse(a['key']));
        }
        // If one of the keys is not a number, put the non-numeric key at the end
        else if (!RegExp(r'^-?[0-9]+$').hasMatch(a['key'])) {
          return 1;
        } else {
          return -1;
        }
      });

      setState(() {
        transcriptions = entries;
      });
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: ListView.builder(
  itemCount: transcriptions.length,
  itemBuilder: (context, index) {
    final transcription = transcriptions[index];
    String? formattedTime;

    // Check if the key is a number
    if (RegExp(r'^-?[0-9]+$').hasMatch(transcription['key'])) {
      final timestamp = int.parse(transcription['key']);
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      formattedTime = DateFormat('hh:mm a').format(dateTime);
    }

    return ListTile(
      title: Text(transcription['transcription']),
      subtitle: formattedTime != null ? Text(formattedTime) : null,
    );
  },
),
      bottomNavigationBar: BottomNavigationBar(
  items: const <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mic),
      label: 'Record',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.language), // or use a different icon for translation
      label: 'Translate',
    ),
  ],
  currentIndex: 1, // set the initial index
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.black,
  onTap: (int index) {
    // Handle navigation
    if (index == 1) {
      // Do nothing or navigate to home
    } else if (index == 0) {
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecordPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TranslatePage()),
      );
    }
  },
),
    );
  }
}


class RecordPage extends StatefulWidget {
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String _transcription = '';

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  var audioFile;
  var audioUri;
  String filePath = '';
  String tempDir = '';

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    await _speechToText.initialize();
  }

Future<void> _startRecording() async {
  print('here');
  final status = await Permission.microphone.request();
  if (status != PermissionStatus.granted) {
    throw 'Microphone permission not granted';
  }
  tempDir = (await getTemporaryDirectory()).path;
  print(tempDir);
  await _recorder.openRecorder();
  await _recorder.startRecorder(
    toFile: '$tempDir/audio.aac',
    codec: Codec.aacADTS,
  );
  print("started");
  setState(() {
    _isRecording = true;
  });

  // Get the file path
  //filePath = 'audio.aac'; // Update this with the correct file path if needed
  
  // Create a File object
  //audioFile = File(filePath);
  //audioUri = Uri.file(filePath);
  
  // Return the URI of the file
}


  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    setState(() {
      _isRecording = false;
    });
    print('STOPPED');
    _transcribeAudio();
  }

  Future<void> _transcribeAudio() async {
  final player = AudioPlayer();
  // Play the recorded audio file
  await player.play(DeviceFileSource('$tempDir/audio.aac'));

  // Transcribe the audio while playing
  _speechToText.listen(
    onResult: (result) {
      setState(() {
        _transcription = result.recognizedWords;
      });
    },
    localeId: 'en_US',
    cancelOnError: true, // Stop transcription if there's an error
  );

  // Stop transcription and send transcription to Firebase when playback finishes
  player.onPlayerComplete.listen((event) {
    _speechToText.stop();
    _sendToFirebase(_transcription);
    _transcription = '';
  });
}

  void _sendToFirebase(String transcription) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final DatabaseReference _databaseReference =
        FirebaseDatabase.instance.reference().child('transcriptions');
    _databaseReference..child('data').set({'transcription': transcription});
    _databaseReference.child(timestamp).set({'transcription': transcription});
    transcription = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record'),
      ),
      body: Container(
        child: Center(
          child: Text('Transcription: $_transcription'),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
  items: const <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mic),
      label: 'Record',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.language), // or use a different icon for translation
      label: 'Translate',
    ),
  ],
  currentIndex: 2, // set the initial index
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.black,
  onTap: (int index) {
    // Handle navigation
    if (index == 2) {
      // Do nothing or navigate to home
    } else if (index == 0) {
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TranslatePage()),
      );
    }
  },
),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        child: Text(_isRecording ? 'stop' : 'start'),
      ),
    );
  }
}

class TranslatePage extends StatefulWidget {
  @override
  _TranslatePageState createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  late String _selectedLanguage;
  List<String> _translatedTextList = [];
  List<Map<String, String>> _localeNames = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'es', 'name': 'Spanish'},
    
    // Add more languages as needed
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'en'; // Set the default language to English
    _fetchTranscriptions();
  }

  void _fetchTranscriptions() {
  final DatabaseReference transcriptionsRef =
      FirebaseDatabase.instance.reference().child('transcriptions');

  transcriptionsRef.onValue.listen((DatabaseEvent event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      List<String> textsToTranslate = [];
      
      // Convert the data keys to a list and sort them
      List<dynamic> sortedKeys = data.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // Sort in descending order
      
      // Extract texts based on sorted keys
      sortedKeys.forEach((key) {
        final transcription = data[key]['transcription'];
        if (transcription != null) {
          textsToTranslate.add(transcription);
        }
      });

      // Translate each text one by one
      textsToTranslate.forEach((text) {
        _translateText(text);
      });
    }
  });
}

  void _translateText(String text) async {
    final translator = GoogleTranslator();
    final translatedText = await translator.translate(text, to: _selectedLanguage);
    setState(() {
      _translatedTextList.add(translatedText.text); // Add translated text to the list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translate'),
        actions: [
          DropdownButton<String>(
            value: _selectedLanguage,
            onChanged: (String? newValue) {
              setState(() {
                _selectedLanguage = newValue!;
                _translatedTextList.clear(); // Clear translated text list
                _fetchTranscriptions(); // Re-fetch and translate all texts
              });
            },
            items: _localeNames.map((locale) {
              return DropdownMenuItem<String>(
                value: locale['code']!,
                child: Text(locale['name']!),
              );
            }).toList(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _translatedTextList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_translatedTextList[index]),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.language),
            label: 'Translate',
          ),
        ],
        currentIndex: 3, // set the initial index to 3 for the Translate page
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: (int index) {
          // Handle navigation
          if (index == 3) {}
          else if (index == 0) {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecordPage()),
            );
          }
        },
      ),
    );
  }
}