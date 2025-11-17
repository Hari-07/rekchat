import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileUploader extends StatelessWidget {
  const FileUploader({super.key, required this.uploadFiles});

  final void Function(FilePickerResult) uploadFiles;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (result == null) return;

        // TODO: Split selecting files and uploading them to the server
        uploadFiles(result);
      },
      child: Text('Choose File'),
    );
  }
}
