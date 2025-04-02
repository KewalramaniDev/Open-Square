import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:intl/intl.dart';
import 'web_signaling_client.dart';

class VideoCallPage extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String currentUserFcmToken;
  final String chatUserId;
  final String currentUserName;
  final String chatUserName;
  final bool isCaller;

  const VideoCallPage({
    Key? key,
    required this.roomId,
    required this.currentUserId,
    required this.currentUserFcmToken,
    required this.chatUserId,
    required this.currentUserName,
    required this.chatUserName,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool isInCall = false;
  bool isGeneratingCall = false;
  String connectionState = 'new';
  WebSignalingClient? signalingClient;
  bool isMuted = false;
  bool isVideoEnabled = true;
  bool isFrontCamera = true;
  int callDuration = 0;
  Timer? timer;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRenderers();

    if (widget.isCaller) {
      generateCall();
    } else {
      joinCall();
    }
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  @override
  void dispose() {
    timer?.cancel();
    localRenderer.dispose();
    remoteRenderer.dispose();
    signalingClient?.dispose();
    super.dispose();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        callDuration += 1;
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  String formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> generateCall() async {
    try {
      setState(() {
        isGeneratingCall = true;
      });
      final room = widget.roomId;
      signalingClient = WebSignalingClient();
      await signalingClient!.initialize(room, true, true);
      await signalingClient!.createCall(room);

      signalingClient!.onCallStateChange = (state) {
        if (state == 'ended') {
          setState(() {
            isInCall = false;
            isGeneratingCall = false;
          });
          Fluttertoast.showToast(msg: 'Call ended');
          Navigator.pop(context);
        }
      };

      signalingClient!.onConnectionStateChange = (state) {
        setState(() {
          connectionState = state;
        });
        if (state == 'connected') {
          startTimer();
          Fluttertoast.showToast(msg: 'Call connected!');
        } else if (state == 'disconnected' || state == 'failed') {
          stopTimer();
          Fluttertoast.showToast(msg: 'Call disconnected');
          handleEndCall();
        }
      };

      signalingClient!.onRemoteStream = (stream) {
        setState(() {
          remoteRenderer.srcObject = stream;
        });
      };

      if (signalingClient!.localStream != null) {
        localRenderer.srcObject = signalingClient!.localStream;
      }

      setState(() {
        isInCall = true;
      });
      Fluttertoast.showToast(
          msg: 'Call generated! Room ID: ${widget.roomId}',
          timeInSecForIosWeb: 5);
    } catch (e) {
      setState(() {
        isGeneratingCall = false;
      });
      Fluttertoast.showToast(msg: 'Failed to generate call');
      print('Error generating call: $e');
    }
  }

  Future<void> joinCall() async {
    try {
      setState(() {
        callDuration = 0;
      });
      stopTimer();

      signalingClient = WebSignalingClient();
      await signalingClient!.initialize(widget.roomId, false, true);

      signalingClient!.onCallStateChange = (state) {
        if (state == 'ended') {
          setState(() {
            isInCall = false;
          });
          Fluttertoast.showToast(msg: 'Call ended');
          Navigator.pop(context);
        }
      };

      signalingClient!.onConnectionStateChange = (state) {
        setState(() {
          connectionState = state;
        });
        if (state == 'connected') {
          startTimer();
          Fluttertoast.showToast(msg: 'Call connected!');
        } else if (state == 'disconnected' || state == 'failed') {
          stopTimer();
          Fluttertoast.showToast(msg: 'Call disconnected');
          handleEndCall();
        }
      };

      signalingClient!.onRemoteStream = (stream) {
        setState(() {
          remoteRenderer.srcObject = stream;
        });
      };

      if (signalingClient!.localStream != null) {
        localRenderer.srcObject = signalingClient!.localStream;
      }

      setState(() {
        isInCall = true;
      });
      Fluttertoast.showToast(
          msg: 'Joined call successfully', timeInSecForIosWeb: 5);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to join call');
      print('Error joining call: $e');
    }
  }

  Future<void> handleEndCall() async {
    try {
      await signalingClient?.endCall();
      setState(() {
        isInCall = false;
      });
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      Fluttertoast.showToast(msg: 'Call ended');
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error ending call');
      print('Error ending call: $e');
    }
  }

  void toggleAudio() {
    if (signalingClient != null) {
      bool newState = !isMuted;
      signalingClient!.toggleAudio(newState);
      setState(() {
        isMuted = newState;
      });
    }
  }

  void toggleVideo() {
    if (signalingClient != null) {
      bool newState = !isVideoEnabled;
      signalingClient!.toggleVideo(newState);
      setState(() {
        isVideoEnabled = newState;
      });
    }
  }

  void switchCamera() {
    if (signalingClient != null) {
      signalingClient!.switchCamera();
      setState(() {
        isFrontCamera = !isFrontCamera;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: remoteRenderer.srcObject != null
                  ? RTCVideoView(remoteRenderer)
                  : const Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              right: 16,
              bottom: 100,
              width: 120,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: localRenderer.srcObject != null
                    ? RTCVideoView(localRenderer, mirror: true)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatTime(callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connectionState.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: toggleAudio,
                    icon: Icon(
                      isMuted ? Icons.mic_off : Icons.mic,
                      color: isMuted ? Colors.red : Colors.white,
                    ),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: toggleVideo,
                    icon: Icon(
                      isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: isVideoEnabled ? Colors.white : Colors.red,
                    ),
                    iconSize: 32,
                  ),

                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: switchCamera,
                    icon: const Icon(
                      Icons.switch_camera,
                      color: Colors.white,
                    ),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: handleEndCall,
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.red,
                    ),
                    iconSize: 32,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
