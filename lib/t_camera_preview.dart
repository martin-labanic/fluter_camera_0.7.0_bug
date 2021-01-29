
import 'dart:io';

import "package:camera/camera.dart";
import "package:flutter/material.dart";
import 'package:image/image.dart' as I;
import 'package:path_provider/path_provider.dart';

class TCameraPreview extends StatefulWidget {
  @override
  _TCameraPreviewState createState() {
    return _TCameraPreviewState();
  }
}

class _TCameraPreviewState extends State<TCameraPreview>{
  CameraController _camera_controller;
  List<CameraDescription> _available_cameras;
  int frame = 0;

  @override
  void initState() {
    super.initState();
    this.setupCameraPreview();
  }

  // Saves the camera image, just iOS at the moment.
  Future<Map<String, dynamic>> saveImage(CameraImage image) async {
    var result = {'retval': false, 'message': '', 'file_name': null};
    try {
      if (image == null) {
        result['message'] = 'no image data';
      } else {
        String file_name = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
        I.Image img;
        if (Platform.isIOS) {
          img = I.Image.fromBytes(
            image.width,
            image.height,
            image.planes[0].bytes,
            format: I.Format.bgra,
          );
        } else {
          final int width = image.width;
          final int height = image.height;
          final int uvRowStride = image.planes[1].bytesPerRow;
          final int uvPixelStride = image.planes[1].bytesPerPixel;
          img = I.Image(width, height);
          for (int x = 0; x < width; x++) {
            for (int y = 0; y < height; y++) {
              final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
              final int index = y * uvRowStride + x;
              final yp = image.planes[0].bytes[index];
              final up = image.planes[1].bytes[uvIndex];
              final vp = image.planes[2].bytes[uvIndex];
              int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255).toInt();
              int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255).toInt();
              int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255).toInt();
              img.setPixelRgba(x, y, r, g, b);
            }
          }
        }
        List<int> jpeg_data = I.encodeJpg(img, quality: 100);

        if (jpeg_data == null || jpeg_data.isEmpty) {
          result['message'] = 'image conversion failed';
        } else {
          Directory directory = await getApplicationSupportDirectory();
          File image_file = await File(directory.path + '/' + file_name).create();
          await image_file.writeAsBytes(jpeg_data, mode: FileMode.writeOnly);
          result['file_name'] = file_name;
          result['retval'] = true;
        }
      }
    } catch (e, s) {
      print("ZZZZZ saveImage: Exception: ${e.toString()}");
      result['retval'] = false;
      result['message'] = e.toString();
    } finally {
      return result;
    }
  }

  void setupCameraPreview() async {
    _available_cameras = await availableCameras();

    var image_format_group = Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420; // Use with v0.7.0 of the camera plugin.
    _camera_controller = CameraController(_available_cameras[1], ResolutionPreset.medium, enableAudio: false, imageFormatGroup: image_format_group);

    // _camera_controller = CameraController(_available_cameras[1], ResolutionPreset.medium, enableAudio: false); // Use with v0.6.4+5 of the camera plugin.

    await _camera_controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });

    await _camera_controller.startImageStream(
      (CameraImage image) async {
        try {
          if (frame % 60 == 0) {
            print("image size: width: ${image.width} | height: ${image.height}");
            saveImage(image);
          }
          frame++;
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

    return CameraPreview(_camera_controller);
  }
}
