import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteResult {
  final String label;
  final int classId;
  final double confidence;
  final String riskLevel;
  final bool referralRecommended;
  final bool hasLesion;

  TFLiteResult({
    required this.label,
    required this.classId,
    required this.confidence,
    required this.riskLevel,
    required this.referralRecommended,
    required this.hasLesion,
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

    // 1. Human Skin Color & Texture Verification (Filters out non-skin photos like laptops, rooms, objects)
    int skinPixelCount = 0;
    int totalSampledPixels = 0;
    const int step = 8;

    for (var y = 0; y < 640; y += step) {
      for (var x = 0; x < 640; x += step) {
        var pixel = resizedImg.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        double luma = 0.299 * r + 0.587 * g + 0.114 * b;
        totalSampledPixels++;

        // Convert to YCbCr to separate luminance from chrominance
        double cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
        double cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;

        bool isRgbSkin = (r > 60 && g > 40 && b > 20) &&
                         (r > g && r > b) &&
                         ((r - g) >= 15);
                         
        bool isYCbCrSkin = (cb >= 77 && cb <= 127) && (cr >= 133 && cr <= 165);
        bool isGoodLuma = (luma >= 40 && luma <= 240); // Reject pure shadows & blown-out highlights

        if (isRgbSkin && isYCbCrSkin && isGoodLuma) {
          skinPixelCount++;
        }
      }
    }

    double skinPixelRatio = skinPixelCount / totalSampledPixels;
    print("Skin Verification: Skin pixel ratio = ${(skinPixelRatio * 100).toStringAsFixed(1)}%");

    // Final robust threshold: We require 35% of the image to be healthy, well-lit human skin.
    // Luma bounds (40-240) actively reject shadows and warm-lit specular highlights from the count.
    if (skinPixelRatio < 0.35) {
      return TFLiteResult(
        label: "Invalid Photo — No Human Skin Detected",
        classId: -1,
        confidence: 0.0,
        riskLevel: "INVALID",
        referralRecommended: false,
        hasLesion: false,
      );
    }

    // Preprocess tensor (640x640x3 RGB, normalized)
    var input = Float32List(1 * 640 * 640 * 3);
    var pixelIndex = 0;

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

    var inputTensor = input.reshape([1, 640, 640, 3]);
    var outputTensor = List.filled(1 * 7, 0.0).reshape([1, 7]);

    _interpreter!.run(inputTensor, outputTensor);

    List<double> outputProbs = List<double>.from(outputTensor[0]);
    
    // Apply softmax since YOLOv8-cls TFLite raw logits aren't normalized
    double maxLogit = outputProbs.reduce(math.max);
    double sumExp = 0.0;
    for (int i = 0; i < outputProbs.length; i++) {
        outputProbs[i] = math.exp(outputProbs[i] - maxLogit);
        sumExp += outputProbs[i];
    }
    for (int i = 0; i < outputProbs.length; i++) {
        outputProbs[i] /= sumExp;
    }
    
    double maxScoreProb = -1.0;
    int maxIndex = 0;
    for (int i = 0; i < outputProbs.length; i++) {
      if (outputProbs[i] > maxScoreProb) {
        maxScoreProb = outputProbs[i];
        maxIndex = i;
      }
    }

    String label = (_labels != null && maxIndex < _labels!.length) ? _labels![maxIndex] : "Class $maxIndex";

    // We trust the TFLite model purely now. If it's a healthy palm, it will likely classify as NV (Low Risk).
    
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

    bool isSuspicious = ['mel', 'bcc', 'akiec'].contains(label.toLowerCase());
    String riskLevel = isSuspicious ? (label.toLowerCase() == 'mel' ? 'HIGH' : 'MEDIUM') : 'LOW';
    
    bool referralRecommended = isSuspicious;

    return TFLiteResult(
      label: fullLabel,
      classId: maxIndex,
      confidence: maxScoreProb,
      riskLevel: riskLevel,
      referralRecommended: referralRecommended,
      hasLesion: true,
    );
  }

  void close() {
    _interpreter?.close();
  }
}
