// ignore_for_file: empty_catches

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agq_app/screens/utils/utilities.dart';


void downloadToFiles(String documentName) async {
  Directory downloadDir = await getApplicationDocumentsDirectory();
  var path = '${downloadDir.path}/$documentName';
  var file = File(path);
  var res = await http.get(Uri.parse('https://source.unsplash.com/random')); 
  await file.writeAsBytes(res.bodyBytes);

  // Open share options
}

Future<String> downloadFile(context, clientId, documentName) async {
  String filePath = '';

  try {
    final directory = await getTemporaryDirectory();

    filePath = '${directory.path}/$documentName';

    final ref = FirebaseStorage.instance.ref().child(Config.get('FIRESTORE_ACTIVE_USERS_COLLECTION')).child(clientId).child(documentName);

    final bytes = await ref.getData();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } else {
    }
  } catch (e) {
  }

  return filePath;
}