
import 'dart:io';

import "package:camera/camera.dart";
import "package:flutter/material.dart";

class TCameraPreview extends StatefulWidget {
  @override
  _TCameraPreviewState createState() {
    return _TCameraPreviewState();
  }
}

class _TCameraPreviewState extends State<TCameraPreview>{
  CameraController _camera_controller;
  List<CameraDescription> _available_cameras;

  @override
  void initState() {
    super.initState();
    this.setupCameraPreview();
  }

  void setupCameraPreview() async {
    _available_cameras = await availableCameras();
    var image_format_group = Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420;
    _camera_controller = CameraController(_available_cameras[1], ResolutionPreset.medium, enableAudio: false, imageFormatGroup: image_format_group);
    await _camera_controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });

    await _camera_controller.startImageStream(
      (CameraImage image) async {
        try {
          print("image size: width: ${image.width} | height: ${image.height}");
        } catch (e) {
          print("ZZZZZ startImageStream: Exception: ${e.toString()}");
        }
      }
    );
  }

  @override
  void dispose() {
    _camera_controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_camera_controller == null || !_camera_controller.value.isInitialized) {
      return Container(width: 100, height: 100);
    }
    // return Text('????');
    return CameraPreview(_camera_controller);

    // return Stack(
    // 	children: <Widget>[
    // 		AspectRatio(
    // 			aspectRatio: _cameraController.value.aspectRatio,
    // 			child: CameraPreview(_cameraController)
    // 		),
    // 		Align(
    // 			alignment: Alignment.topRight,
    // 			child: Container(
    // 				color: _detected ? Colors.green : Colors.pink,
    // 				height: 50.0,
    // 				width: 50.0,
    // 			),
    // 		)
    // 	]
    // );
  }
}
