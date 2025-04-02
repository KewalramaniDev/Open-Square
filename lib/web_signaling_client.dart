import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef CallStateChangeCallback = void Function(String state);
typedef ConnectionStateChangeCallback = void Function(String state);
typedef RemoteStreamCallback = void Function(MediaStream stream);

class WebSignalingClient {
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  bool isInitiator = false;

  RTCSessionDescription? _localDescription;
  RTCSessionDescription? _remoteDescription;

  List<Map<String, dynamic>> _pendingIceCandidates = [];

  CallStateChangeCallback? onCallStateChange;
  ConnectionStateChangeCallback? onConnectionStateChange;
  RemoteStreamCallback? onRemoteStream;

  StreamSubscription<DocumentSnapshot>? _subscription;

  Future<void> initialize(String roomId, bool isInitiator, bool withVideo) async {
    this.roomId = roomId;
    this.isInitiator = isInitiator;

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': "turn:global.relay.metered.ca:80",
          'username': "25e65e8ca8452a57b1b57cdf",
          'credential': "dO80xow+jFQkluuJ",
        },
        {
          'urls': "turn:global.relay.metered.ca:80?transport=tcp",
          'username': "25e65e8ca8452a57b1b57cdf",
          'credential': "dO80xow+jFQkluuJ",
        },
        {
          'urls': "turn:global.relay.metered.ca:443",
          'username': "25e65e8ca8452a57b1b57cdf",
          'credential': "dO80xow+jFQkluuJ",
        },
        {
          'urls': "turns:global.relay.metered.ca:443?transport=tcp",
          'username': "25e65e8ca8452a57b1b57cdf",
          'credential': "dO80xow+jFQkluuJ",
        },
      ],
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': withVideo,
      });
      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });
    } catch (err) {
      print('Error accessing media: $err');
      rethrow;
    }

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate != null && roomId != null) {
        final Map<String, dynamic> iceCandidate = {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'serverUrl': "",
          'type': isInitiator ? "offer" : "answer",
        };

        FirebaseFirestore.instance
            .collection('calls')
            .doc(roomId)
            .update({'ice': iceCandidate}).then((_) {
          print('ICE candidate updated successfully: ${candidate.candidate}');
        }).catchError((error) {
          print('Error updating ICE candidate: $error');
        });
      }
    };

    peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state changed: $state');
      if (onConnectionStateChange != null) {
        onConnectionStateChange!(state.toString());
      }
    };

    peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        print("Received remote stream with id: ${remoteStream!.id}");
        if (onRemoteStream != null) {
          onRemoteStream!(remoteStream!);
        }
      }
    };

    await listenToCallState();
  }

  /// NEW: Switches the camera (front/back) on the local stream.
  Future<void> switchCamera() async {
    if (localStream != null) {
      final videoTracks = localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await videoTracks.first.switchCamera();
        print("Camera switched.");
      }
    }
  }

  Future<bool> checkRoomExists(String roomId) async {
    final docSnap = await FirebaseFirestore.instance.collection('calls').doc(roomId).get();
    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>?;
      return (data != null && data['type'] != 'END_CALL');
    }
    return false;
  }

  Future<void> createCall(String meetingID) async {
    try {
      RTCSessionDescription offer = await peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await peerConnection!.setLocalDescription(offer);
      _localDescription = offer;
      await FirebaseFirestore.instance.collection('calls').doc(meetingID).set({
        'type': "OFFER",
        'sdp': offer.sdp,
      }, SetOptions(merge: true));
      print('Offer created and sent.');
    } catch (err) {
      print('Error creating call: $err');
      rethrow;
    }
  }

  Future<void> listenToCallState() async {
    if (roomId == null) return;

    final callDoc = FirebaseFirestore.instance.collection('calls').doc(roomId);
    _subscription = callDoc.snapshots().listen((DocumentSnapshot snapshot) async {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      try {
        if (data['type'] == "END_CALL") {
          handleCallEnd();
          return;
        }

        if (data['type'] == "OFFER" && !isInitiator) {
          if (data['sdp'] == null) {
            print("Received OFFER with null SDP");
            return;
          }
          RTCSessionDescription remoteOffer = RTCSessionDescription(data['sdp'], 'offer');
          await peerConnection!.setRemoteDescription(remoteOffer);
          _remoteDescription = remoteOffer;
          print('Remote offer set.');

          for (var ice in _pendingIceCandidates) {
            try {
              RTCIceCandidate candidate = RTCIceCandidate(
                ice['candidate'],
                ice['sdpMid'],
                ice['sdpMLineIndex'],
              );
              await peerConnection!.addCandidate(candidate);
              print('Added pending ICE candidate: ${candidate.candidate}');
            } catch (e) {
              print('Error adding pending ICE candidate: $e');
            }
          }
          _pendingIceCandidates.clear();

          RTCSessionDescription answer = await peerConnection!.createAnswer({
            'offerToReceiveAudio': true,
            'offerToReceiveVideo': true,
          });
          await peerConnection!.setLocalDescription(answer);
          _localDescription = answer;
          await callDoc.set({
            'type': "ANSWER",
            'sdp': answer.sdp,
          }, SetOptions(merge: true));
          print('Answer created and sent.');
        } else if (data['type'] == "ANSWER" && isInitiator) {
          if (data['sdp'] == null) {
            print("Received ANSWER with null SDP");
            return;
          }
          if (peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateStable) {
            RTCSessionDescription remoteAnswer = RTCSessionDescription(data['sdp'], 'answer');
            await peerConnection!.setRemoteDescription(remoteAnswer);
            _remoteDescription = remoteAnswer;
            print('Remote answer set.');

            for (var ice in _pendingIceCandidates) {
              try {
                RTCIceCandidate candidate = RTCIceCandidate(
                  ice['candidate'],
                  ice['sdpMid'],
                  ice['sdpMLineIndex'],
                );
                await peerConnection!.addCandidate(candidate);
                print('Added pending ICE candidate: ${candidate.candidate}');
              } catch (e) {
                print('Error adding pending ICE candidate: $e');
              }
            }
            _pendingIceCandidates.clear();
          } else {
            print("Peer connection signaling state is stable; skipping setRemoteDescription for ANSWER.");
          }
        }

        if (data.containsKey('ice')) {
          if (_remoteDescription != null) {
            try {
              RTCIceCandidate candidate = RTCIceCandidate(
                data['ice']['candidate'],
                data['ice']['sdpMid'],
                data['ice']['sdpMLineIndex'],
              );
              await peerConnection!.addCandidate(candidate);
              print('Added ICE candidate: ${candidate.candidate}');
            } catch (e) {
              print('Error adding ICE candidate: $e');
            }
          } else {
            print('Remote description not set. Storing ICE candidate for later.');
            _pendingIceCandidates.add(data['ice']);
          }
        }
      } catch (err) {
        print('Error in call state handling: $err');
      }
    });
  }

  Future<void> endCall() async {
    if (_subscription != null) {
      await _subscription!.cancel();
    }
    if (localStream != null) {
      localStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) {
      await peerConnection!.close();
    }
    if (roomId != null) {
      await FirebaseFirestore.instance.collection('calls').doc(roomId).set({
        'type': 'END_CALL',
      }, SetOptions(merge: true));
      print('Call ended and updated in Firestore.');
    }
    if (onCallStateChange != null) {
      onCallStateChange!('ended');
    }
  }

  void handleCallEnd() {
    if (onCallStateChange != null) {
      onCallStateChange!('ended');
    }
    endCall();
  }

  void toggleAudio(bool enabled) {
    if (localStream != null) {
      localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  void toggleVideo(bool enabled) {
    if (localStream != null) {
      localStream!.getVideoTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
