import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteResult {
  final String label;
  final int classId;
  final double confidence;
  final String riskLevel;
  final bool referralRecommended;

  TFLiteResult({
    required this.label,
    required this.classId,
    required this.confidence,
    required this.riskLevel,
    required this.referralRecommended,
  });
}

class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model/best_int8.tflite');
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((s) => s.trim().isNotEmpty).toList();
      print("TFLite Model loaded successfully. Input shape: ${_interpreter!.getInputTensor(0).shape}");
    } catch (e) {
      print("Error loading TFLite model: $e");
    }
  }

  Future<TFLiteResult> classifyImage(File imageFile) async {
    if (_interpreter == null) {
      await loadModel();
    }

    // Load and decode image
    final imageBytes = await imageFile.readAsBytes();
    img_lib.Image? rawImg = img_lib.decodeImage(imageBytes);
    if (rawImg == null) {
      throw Exception("Could not decode image");
    }

    // Resize to 640x640 expected by YOLOv8n-cls
    img_lib.Image resizedImg = img_lib.copyResize(rawImg, width: 640, height: 640);

    // Preprocess tensor (640x640x3 RGB, normalized)
    var input = Float32List(1 * 640 * 640 * 3);
    var pixelIndex = 0;

    // ImageNet mean and std stats
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    for (var y = 0; y < 640; y++) {
      for (var x = 0; x < 640; x++) {
        var pixel = resizedImg.getPixel(x, y);
        var r = (pixel.r / 255.0 - mean[0]) / std[0];
        var g = (pixel.g / 255.0 - mean[1]) / std[1];
        var b = (pixel.b / 255.0 - mean[2]) / std[2];

        input[pixelIndex++] = r;
        input[pixelIndex++] = g;
        input[pixelIndex++] = b;
      }
    }

    // Reshape tensor to [1, 640, 640, 3] or [1, 3, 640, 640]
    var inputTensor = input.reshape([1, 640, 640, 3]);
    var outputTensor = List.filled(1 * 7, 0.0).reshape([1, 7]);

    // Execute ON-DEVICE offline inference (0 internet calls)
    _interpreter!.run(inputTensor, outputTensor);

    List<double> outputProbs = List<double>.from(outputTensor[0]);
    
    // Find top-1 class
    double maxScore = -1.0;
    int maxIndex = 0;
    for (int i = 0; i < outputProbs.length; i++) {
      if (outputProbs[i] > maxScore) {
        maxScore = outputProbs[i];
        maxIndex = i;
      }
    }

    String label = (_labels != null && maxIndex < _labels!.length) ? _labels![maxIndex] : "Class $maxIndex";
    
    // Map class names to full labels
    Map<String, String> displayNames = {
      'akiec': 'Actinic Keratosis (AKIEC)',
      'bcc': 'Basal Cell Carcinoma (BCC)',
      'bkl': 'Benign Keratosis (BKL)',
      'df': 'Dermatofibroma (DF)',
      'mel': 'Melanoma (MEL)',
      'nv': 'Melanocytic Nevus (NV)',
      'vasc': 'Vascular Lesion (VASC)'
    };

    String fullLabel = displayNames[label.toLowerCase()] ?? label.toUpperCase();

    // Risk level classification
    bool isSuspicious = ['mel', 'bcc', 'akiec'].contains(label.toLowerCase());
    String riskLevel = isSuspicious ? (label.toLowerCase() == 'mel' ? 'HIGH' : 'MEDIUM') : 'LOW';
    bool referralRecommended = isSuspicious;

    return TFLiteResult(
      label: fullLabel,
      classId: maxIndex,
      confidence: maxScore,
      riskLevel: riskLevel,
      referralRecommended: referralRecommended,
    );
  }

  void close() {
    _interpreter?.close();
  }
}
