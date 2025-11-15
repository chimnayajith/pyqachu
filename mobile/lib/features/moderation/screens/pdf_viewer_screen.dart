import 'package:flutter/material.dart';
import 'package:pyqachu/core/models/api_models.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final PreviousYearQuestion pyq;

  const PdfViewerScreen({
    Key? key,
    required this.pyq,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  PdfController? _pdfController;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    downloadAndSavePdf();
  }

  Future<void> downloadAndSavePdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pyq.pdfUrl));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/temp_${widget.pyq.id}.pdf');
        
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          _pdfController = PdfController(
            document: PdfDocument.openFile(file.path),
          );
          
          setState(() {
            localPath = file.path;
            isLoading = false;
            isReady = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load PDF: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error downloading PDF: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pyq.subjectName} - ${widget.pyq.year}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isReady && _pdfController != null) ...[
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: () {
                try {
                  _pdfController!.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                } catch (e) {
                  print('First page error: $e');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed: () async {
                try {
                  final doc = await _pdfController!.document;
                  _pdfController!.animateToPage(
                    doc.pagesCount,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                  );
                } catch (e) {
                  print('Last page error: $e');
                }
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading PDF',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      downloadAndSavePdf();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_pdfController != null)
            PdfView(
              controller: _pdfController!,
              onPageChanged: (page) {
                // Handle page changes if needed
              },
            ),
        ],
      ),
      floatingActionButton: isReady && _pdfController != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "previous",
                  mini: true,
                  onPressed: () {
                    try {
                      _pdfController!.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.ease,
                      );
                    } catch (e) {
                      print('Previous page error: $e');
                    }
                  },
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "next",
                  mini: true,
                  onPressed: () {
                    try {
                      _pdfController!.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.ease,
                      );
                    } catch (e) {
                      print('Next page error: $e');
                    }
                  },
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            )
          : null,
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    
    // Clean up the temporary file
    if (localPath != null) {
      try {
        File(localPath!).delete().catchError((e) {
          print('Error deleting temp file: $e');
          return File('');
        });
      } catch (e) {
        print('Error in dispose: $e');
      }
    }
    super.dispose();
  }
}