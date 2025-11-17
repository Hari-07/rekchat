import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'provider/app_state_view_model.dart';
import 'query_input/query_input_field.dart';
import 'views/file_uploader.dart';
import 'views/uploaded_files_details.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(body: const HomePage()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateViewModel(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<AppStateViewModel>(
          builder: (context, viewModel, child) => Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FileUploader(uploadFiles: viewModel.uploadFiles),
                      SizedBox(height: 20),
                      // File details display
                      if (viewModel.uploadedFiles.isNotEmpty) ...[
                        UploadedFilesDetails(
                          uploadedFiles: viewModel.uploadedFiles,
                        ),
                        SizedBox(height: 20),
                      ],
                      SizedBox(
                        width: 200,
                        child: QueryInputField(
                          controller: viewModel.queryTextFieldController,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: viewModel.isUploadingFiles
                            ? null
                            : viewModel.submitQuery,
                        child: Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: switch (viewModel.dataState) {
                    DataStates.empty => Center(
                      child: DataPlaceholder(text: 'Empty Data'),
                    ),
                    DataStates.fetchingResponse => Center(
                      child: DataPlaceholder(
                        text: 'Generating Code...',
                        showLoading: true,
                      ),
                    ),
                    DataStates.executingCode => Center(
                      child: DataPlaceholder(
                        text: 'Received Code. Processing Data...',
                        showLoading: true,
                      ),
                    ),
                    DataStates.error => Center(
                      child: DataPlaceholder(text: 'Something went wrong :('),
                    ),
                    DataStates.receivedData => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        children: [
                          // Header row
                          if (viewModel.columns.isNotEmpty)
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.black45),
                                ),
                              ),
                              child: Row(
                                children: viewModel.columns
                                    .map(
                                      (column) => Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            column,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          // Data rows with ListView.builder for virtualization
                          Expanded(
                            child: ListView.builder(
                              itemCount: viewModel.data.length,
                              itemBuilder: (context, index) {
                                final row = viewModel.data[index];
                                return Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    // color: index % 2 == 0
                                    //     ? Colors.white
                                    //     : Colors.grey[50],
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: viewModel.columns
                                        .map(
                                          (column) => Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              child: Text(
                                                row[column]?.toString() ?? '',
                                                style: TextStyle(fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DataPlaceholder extends StatelessWidget {
  const DataPlaceholder({
    super.key,
    this.showLoading = false,
    required this.text,
  });

  final bool showLoading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        if (showLoading) ...[
          const SizedBox(height: 10),
          SizedBox.square(dimension: 40, child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
