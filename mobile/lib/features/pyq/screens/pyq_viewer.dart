import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pyqachu/core/models/api_models.dart';
import 'package:pyqachu/core/services/api_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final PreviousYearQuestion pyq;

  const PdfViewerScreen({Key? key, required this.pyq}) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;
  String? _localPath;
  bool _isBookmarked = false;
  bool _isLoadingBookmark = false;

  @override
  void initState() {
    super.initState();
    _initializePdf();
    _loadBookmarkStatus();
  }

  Future<void> _initializePdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Download PDF and save locally for better performance
      final response = await http.get(Uri.parse(widget.pyq.pdfUrl));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/pyq_${widget.pyq.id}.pdf');
        
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          _pdfController = PdfController(
            document: PdfDocument.openFile(file.path),
          );
          
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load PDF: HTTP ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final isBookmarked = await ApiService.isBookmarked(widget.pyq.id);
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      print('Error loading bookmark status: $e');
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    // Clean up temporary file
    if (_localPath != null) {
      File(_localPath!).delete().catchError((e) {
        print('Error deleting temp file: $e');
        return File(_localPath!); // Return the file object for proper error handling
      });
    }
    super.dispose();
  }

  void _showInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Document Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Subject', widget.pyq.subjectName),
            _buildInfoRow('Year', widget.pyq.year.toString()),
            _buildInfoRow('Semester', 'Semester ${widget.pyq.semester}'),
            _buildInfoRow('Regulation', widget.pyq.regulation ?? 'Not specified'),
            _buildInfoRow('Branch', widget.pyq.branchName),
            _buildInfoRow('College', widget.pyq.collegeName),
            _buildInfoRow('Uploaded by', widget.pyq.uploadedByUsername),
            if (widget.pyq.reviewedByUsername != null)
              _buildInfoRow('Reviewed by', widget.pyq.reviewedByUsername!),
            _buildInfoRow('Status', widget.pyq.statusDisplay),
            const SizedBox(height: 16),
            if (widget.pyq.reviewNotes != null && widget.pyq.reviewNotes!.isNotEmpty) ...[
              const Text(
                'Review Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.pyq.reviewNotes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Downloading PDF...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // Use the backend download URL
      final downloadUrl = ApiService.getPYQDownloadUrl(widget.pyq.id, download: true);
      
      // For now, just show success. In a real app, you'd save to Downloads folder
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF download URL: $downloadUrl'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoadingBookmark) return;
    
    setState(() {
      _isLoadingBookmark = true;
    });

    try {
      bool success;
      if (_isBookmarked) {
        success = await ApiService.removeBookmark(widget.pyq.id);
      } else {
        success = await ApiService.addBookmark(widget.pyq.id);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isLoadingBookmark = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _isBookmarked ? Colors.green : Colors.grey[600],
          ),
        );
      } else {
        setState(() {
          _isLoadingBookmark = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isBookmarked ? 'Failed to remove bookmark' : 'Failed to add bookmark'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingBookmark = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: Please try again'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reportPdf() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Report Issue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildReportOption(
              icon: Icons.error_outline,
              title: 'Wrong Content',
              subtitle: 'This PDF doesn\'t match the subject/year/semester',
              onTap: () => _submitReport('wrong_content'),
            ),
            _buildReportOption(
              icon: Icons.visibility_off,
              title: 'Poor Quality',
              subtitle: 'PDF is blurry, unclear, or unreadable',
              onTap: () => _submitReport('poor_quality'),
            ),
            _buildReportOption(
              icon: Icons.file_download_off,
              title: 'Corrupted File',
              subtitle: 'PDF won\'t load or is damaged',
              onTap: () => _submitReport('corrupted_file'),
            ),
            _buildReportOption(
              icon: Icons.copyright,
              title: 'Copyright Issue',
              subtitle: 'This content violates copyright',
              onTap: () => _submitReport('copyright'),
            ),
            _buildReportOption(
              icon: Icons.report,
              title: 'Other Issue',
              subtitle: 'Report another problem',
              onTap: () => _submitReport('other'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _submitReport(String reportType) {
    Navigator.pop(context); // Close the modal
    
    // TODO: Implement actual report submission to backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report submitted successfully. Thank you for helping improve our content!'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.pyq.subjectName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
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
                    'Error Loading PDF',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _initializePdf();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_pdfController != null)
            Container(
              margin: const EdgeInsets.only(bottom: 70), // Match bottom bar height
              child: PdfView(
                controller: _pdfController!,
                scrollDirection: Axis.vertical,
                onPageChanged: (page) {
                  // Handle page changes if needed
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomButton(
                icon: Icons.flag_outlined,
                label: 'Report',
                onTap: _reportPdf,
              ),
              _buildBottomButton(
                icon: Icons.info_outline,
                label: 'Info',
                onTap: _showInfoDialog,
              ),
              _buildBottomButton(
                icon: Icons.download_outlined,
                label: 'Download',
                onTap: _downloadPdf,
              ),
              _buildBottomButton(
                icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                label: 'Bookmark',
                onTap: _toggleBookmark,
                isLoading: _isLoadingBookmark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Icon(
                        icon,
                        color: Colors.black,
                        size: 20,
                      ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}