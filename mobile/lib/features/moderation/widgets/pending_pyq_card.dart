import 'package:flutter/material.dart';
import 'package:pyqachu/core/models/api_models.dart';
import 'package:pyqachu/core/services/api_service.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

class PendingPyqCard extends StatelessWidget {
  final PreviousYearQuestion pyq;
  final Function(String?) onApprove;
  final Function(String?) onReject;

  const PendingPyqCard({
    super.key,
    required this.pyq,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _openPdfViewer(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDetails(),
              const SizedBox(height: 16),
              _buildViewButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pyq.subjectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${pyq.collegeName} - ${pyq.branchName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        _buildDetailRow('Year', pyq.year.toString()),
        _buildDetailRow('Semester', pyq.semester.toString()),
        if (pyq.regulation != null && pyq.regulation!.isNotEmpty)
          _buildDetailRow('Regulation', pyq.regulation!),
        _buildDetailRow('Uploaded By', pyq.uploadedByUsername),
        _buildDetailRow('Uploaded', _formatDate(pyq.uploadedAt)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton() {
    return Builder(
      builder: (context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openPdfViewer(context),
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('View & Review'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _openPdfViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          pyq: pyq,
          onApprove: onApprove,
          onReject: onReject,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes;
      
      if (hours == 0) {
        if (minutes == 0) {
          return 'Just now';
        }
        return '${minutes}m ago';
      }
      return '${hours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class PdfViewerPage extends StatefulWidget {
  final PreviousYearQuestion pyq;
  final Function(String?) onApprove;
  final Function(String?) onReject;

  const PdfViewerPage({
    super.key,
    required this.pyq,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isEditing = false;
  late int _selectedYear;
  late int _selectedSemester;
  late String _selectedRegulation;
  PdfControllerPinch? _pdfController;
  bool _isLoadingPdf = true;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.pyq.year;
    _selectedSemester = widget.pyq.semester;
    _selectedRegulation = widget.pyq.regulation ?? '';
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      setState(() {
        _isLoadingPdf = true;
        _pdfError = null;
      });

      if (widget.pyq.pdfUrl.isNotEmpty) {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(
            http.get(Uri.parse(widget.pyq.pdfUrl)).then((response) {
              if (response.statusCode == 200) {
                return response.bodyBytes;
              } else {
                throw Exception('Failed to load PDF: HTTP ${response.statusCode}');
              }
            }),
          ),
        );

        if (mounted) {
          setState(() {
            _isLoadingPdf = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingPdf = false;
            _pdfError = 'PDF URL not available';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
          _pdfError = 'Error loading PDF: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.pyq.subjectName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
            tooltip: _isEditing ? 'Save Changes' : 'Edit Details',
          ),
        ],
      ),
      body: Column(
        children: [
          // PDF Info Header - now editable
          _buildInfoHeader(),
          
          // PDF Viewer with proper error handling
          Expanded(
            child: _isLoadingPdf
                ? const Center(child: CircularProgressIndicator())
                : _pdfError != null
                    ? Center(
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
                              _pdfError!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : PdfViewPinch(controller: _pdfController!),
          ),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: _isEditing ? Colors.grey.shade50 : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            const Text(
              'Edit PYQ Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildEditableFields(),
          ] else ...[
            Text(
              '$_selectedYear - Semester $_selectedSemester',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.pyq.branchName} • Uploaded by ${widget.pyq.uploadedByUsername}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (_selectedRegulation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Regulation: $_selectedRegulation',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEditableFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEditableField(
                label: 'Year',
                onTap: () => _showYearPicker(),
                value: _selectedYear.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEditableField(
                label: 'Semester',
                onTap: () => _showSemesterPicker(),
                value: _selectedSemester.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildEditableField(
          label: 'Regulation (optional)',
          onTap: () => _showRegulationDialog(),
          value: _selectedRegulation.isEmpty ? 'Not specified' : _selectedRegulation,
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required VoidCallback onTap,
    required String value,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showApprovalDialog(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showApprovalDialog(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Approve',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApprovalDialog(BuildContext context, bool isApproval) async {
    final notesController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isApproval ? 'Approve PYQ' : 'Reject PYQ',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show changes if any were made
            if (_hasChanges()) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Changes will be applied:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedYear != widget.pyq.year)
                      Text('Year: ${widget.pyq.year} → $_selectedYear', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    if (_selectedSemester != widget.pyq.semester)
                      Text('Semester: ${widget.pyq.semester} → $_selectedSemester', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    if (_selectedRegulation != (widget.pyq.regulation ?? ''))
                      Text('Regulation: "${widget.pyq.regulation ?? 'None'}" → "$_selectedRegulation"', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
            Text(
              isApproval 
                ? 'Are you sure you want to approve this PYQ?'
                : 'Are you sure you want to reject this PYQ?',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: isApproval ? 'Notes (optional)' : 'Rejection reason',
                hintText: isApproval 
                  ? 'Add any notes about the approval...'
                  : 'Please provide a reason for rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Apply changes and then approve/reject
              await _applyChangesAndReview(isApproval, notesController.text.trim());
              
              Navigator.of(context).pop(); // Close PDF viewer
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.black : Colors.white,
              foregroundColor: isApproval ? Colors.white : Colors.black,
              side: isApproval ? null : BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isApproval ? 'Approve' : 'Reject',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasChanges() {
    return _selectedYear != widget.pyq.year ||
           _selectedSemester != widget.pyq.semester ||
           _selectedRegulation != (widget.pyq.regulation ?? '');
  }

  Future<void> _applyChangesAndReview(bool isApproval, String notes) async {
    try {
      // First apply changes if any
      if (_hasChanges()) {
        await _updatePyqDetails();
      }
      
      // Then approve/reject
      if (isApproval) {
        widget.onApprove(notes.isEmpty ? null : notes);
      } else {
        widget.onReject(notes.isEmpty ? null : notes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.grey.shade800,
        ),
      );
    }
  }

  Future<void> _updatePyqDetails() async {
    try {
      final success = await ApiService.updatePyqDetails(
        widget.pyq.id,
        year: _selectedYear != widget.pyq.year ? _selectedYear : null,
        semester: _selectedSemester != widget.pyq.semester ? _selectedSemester : null,
        regulation: _selectedRegulation != (widget.pyq.regulation ?? '') ? _selectedRegulation : null,
      );
      
      if (!success) {
        throw Exception('Failed to update PYQ details');
      }
    } catch (e) {
      print('Error updating PYQ details: $e');
      throw e;
    }
  }

  void _showYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(20, (index) => currentYear - index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Year',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  return ListTile(
                    title: Text(year.toString()),
                    trailing: _selectedYear == year ? const Icon(Icons.check) : null,
                    onTap: () {
                      setState(() {
                        _selectedYear = year;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSemesterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 250,
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Semester',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (context, index) {
                  final semester = index + 1;
                  return ListTile(
                    title: Text('Semester $semester'),
                    trailing: _selectedSemester == semester ? const Icon(Icons.check) : null,
                    onTap: () {
                      setState(() {
                        _selectedSemester = semester;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegulationDialog() {
    final controller = TextEditingController(text: _selectedRegulation);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Edit Regulation',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Regulation (optional)',
            hintText: 'e.g., R18, R20, 2019-20',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedRegulation = controller.text.trim();
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}