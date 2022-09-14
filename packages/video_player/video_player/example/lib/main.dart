import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(
    const MaterialApp(
      home: MyVideo(),
    ),
  );
}

class MyVideo extends StatefulWidget {
  const MyVideo({Key? key}) : super(key: key);

  @override
  _MyVideoState createState() => _MyVideoState();
}

class _MyVideoState extends State<MyVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Video"),
      ),
      body: Center(
        child: _controller!.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        )
            : Container(
          child: const Text('loading...'),
        ),
      ),
    );
  }

  Future<void> init() async {
    _controller = VideoPlayerController.network(
      'https://service.beta.sanjieke.cn/video/media/11244355/608p.m3u8?user_id=18942194&class_id=33254014&time=1663055202&nonce=868849&token=73daa6bce6e2643a3a9d2f28f3385ce86fa5ec82',
    );

    _controller?.addListener(() {
      setState(() {});
    });

    await _controller?.initialize();

    _controller?.play();
  }
}