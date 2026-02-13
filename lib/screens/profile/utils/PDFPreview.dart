// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:agq_app/screens/utils/resources.dart';

class PDFScreen extends StatelessWidget {
  final String path;

  const PDFScreen(this.path, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.defaultBlueGray700,
        title: const Text(
          'PDF Preview',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
}