import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfHelper {
  static Future<String> extractText(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }
}
