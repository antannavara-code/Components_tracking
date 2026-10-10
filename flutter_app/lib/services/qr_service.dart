import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QrService {
  static Future<Uint8List?> fetchQrImage(String assetId) async {
    try {
      final barcode = Barcode.code128();
      const width = 512.0;
      const height = 200.0;

      final recipe = barcode.make(
        assetId,
        width: width,
        height: height,
        drawText: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final black = ui.Paint()..color = const ui.Color(0xFF000000);

      for (final elem in recipe) {
        if (elem is BarcodeBar && elem.black) {
          canvas.drawRect(
            ui.Rect.fromLTWH(elem.left, elem.top, elem.width, elem.height),
            black,
          );
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  static Future<void> printLabel({
    required String assetId,
    required String assetName,
    required String category,
    String? assignedTo,
    String? status,
    String? remarks,
  }) async {
    final pdf = pw.Document();

    final receiptWidth = 55.0 * PdfPageFormat.mm;
    final receiptHeight = 70.0 * PdfPageFormat.mm;
    final pageFormat = PdfPageFormat(receiptWidth, receiptHeight,
        marginLeft: 3 * PdfPageFormat.mm,
        marginRight: 3 * PdfPageFormat.mm,
        marginTop: 3 * PdfPageFormat.mm,
        marginBottom: 3 * PdfPageFormat.mm);

    // Generate Code128 barcode
    final barcode = Barcode.code128();
    final barcodeSvg = barcode.toSvg(
      assetId,
      width: 50 * PdfPageFormat.mm,
      height: 18 * PdfPageFormat.mm,
      drawText: false,
    );
    final barcodeSvgImage = pw.SvgImage(svg: barcodeSvg);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Barcode
            pw.Center(child: pw.SizedBox(
              width: 48 * PdfPageFormat.mm,
              height: 16 * PdfPageFormat.mm,
              child: barcodeSvgImage,
            )),
            pw.SizedBox(height: 2),
            // Barcode ID text (what scanner reads)
            pw.Text(assetId,
                style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                    letterSpacing: 0.5)),
            pw.SizedBox(height: 3),
            pw.Divider(height: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 2),
            // Asset name
            pw.Text(assetName,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 1),
            // Category
            pw.Text(category,
                style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600)),
            // Assigned to
            if (assignedTo != null && assignedTo.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text('To: $assignedTo',
                    style: pw.TextStyle(
                        fontSize: 7, color: PdfColors.blue800)),
              ),
            ],
            // Status
            if (status != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(status.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.grey500,
                      letterSpacing: 1)),
            ],
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Barcode_$assetId',
    );
  }
}
