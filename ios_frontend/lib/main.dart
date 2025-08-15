import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:flutter_opus/flutter_opus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 56, 160, 53)),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _channel = WebSocketChannel.connect(Uri.parse("ws://100.92.36.5:8083"));
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  OpusDecoder? decoder = OpusDecoder.create(sampleRate: 48000, channels: 2);
  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: true,
      numChannels: 2,
      sampleRate: 48000,
      bufferSize: 16000,
    );

    _channel.stream.listen((event) {
      if (event is Uint8List) {
        final pcm = decoder!.decode(event, (48000 * 20) ~/ 1000);
        if (pcm != null) {
          _player.uint8ListSink!.add(pcm);
        } else {
          debugPrint("Failed to decode Opus data");
        }
      } else if (event is String) {
        debugPrint("Server sent text: $event");
      }
    }, onError: (error) {
      debugPrint("WebSocket error: $error");
    }, onDone: () {
      debugPrint("WebSocket closed");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const Center(child: Text('Streaming audio...')),

    );
    
  }
  @override
  void dispose() {
    _channel.sink.close();
    _player.closePlayer();
    super.dispose();
  }
}
