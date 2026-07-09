import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/app_theme.dart';

/// Menampilkan preview sertifikat dan tombol untuk mengunduh/mencetaknya
/// sebagai PDF. Dipanggil dari halaman Activity ketika status pendaftaran
/// relawan sudah "completed".
class CertificateScreen extends StatelessWidget {
  final String volunteerName;
  final String eventTitle;
  final DateTime? eventDate;
  final String organizerName;

  const CertificateScreen({
    super.key,
    required this.volunteerName,
    required this.eventTitle,
    required this.eventDate,
    required this.organizerName,
  });

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final dateStr = eventDate != null ? DateFormat('d MMMM y', 'id_ID').format(eventDate!) : '-';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#4E8EA2'), width: 6),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('RajutAksi', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#3A6E80'))),
                pw.SizedBox(height: 6),
                pw.Text('Satu Wadah, Seribu Aksi', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 28),
                pw.Text('SERTIFIKAT PENGHARGAAN', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                pw.SizedBox(height: 24),
                pw.Text('Diberikan kepada', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Text(volunteerName, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4E8EA2'))),
                pw.SizedBox(height: 18),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 60),
                  child: pw.Text(
                    'Atas partisipasi dan kontribusinya sebagai relawan dalam kegiatan sosial:',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('"$eventTitle"', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('diselenggarakan pada $dateStr', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 36),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 30),
                        pw.Container(width: 160, height: 1, color: PdfColors.grey600),
                        pw.SizedBox(height: 4),
                        pw.Text(organizerName, style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('Penyelenggara', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sertifikat Relawan')),
      body: SafeArea(
        child: PdfPreview(
          build: (format) => _buildPdf(),
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
          pdfFileName: 'Sertifikat_${volunteerName.replaceAll(' ', '_')}.pdf',
        ),
      ),
    );
  }
}
