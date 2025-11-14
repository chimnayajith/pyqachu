import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pyqachu/core/models/api_models.dart';
import 'package:pyqachu/core/services/api_service.dart';

class PYQUploadPage extends StatefulWidget {
  const PYQUploadPage({super.key});

  @override
  State<PYQUploadPage> createState() => _PYQUploadPageState();
}

class _PYQUploadPageState extends State<PYQUploadPage> {
  College? selectedCollege;
  Branch? selectedBranch;
  Subject? selectedSubject;
  
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _regulationController = TextEditingController();
  
  File? selectedFile;
  String? selectedFileName;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _yearController.dispose();
    _semesterController.dispose();
    _regulationController.dispose();
    super.dispose();
  }

  void _openSelectionModal(String type) async {
    // Reuse the same modal logic from SearchPage
    List<dynamic> options = [];
    dynamic currentValue;
    bool hasError = false;
    String? errorMessage;

    if (type == 'branch' && selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a college first')),
      );
      return;
    }
    if (type == 'subject' && selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a college first')),
      );
      return;
    }
    if (type == 'subject' && selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (type == 'college') {
        final response = await ApiService.getColleges();
        if (response.success) {
          options = response.results;
          currentValue = selectedCollege;
        } else {
          hasError = true;
          errorMessage = response.error;
        }
      } else if (type == 'branch') {
        final response = await ApiService.getBranches(selectedCollege!.id);
        if (response.success) {
          options = response.results;
          currentValue = selectedBranch;
        } else {
          hasError = true;
          errorMessage = response.error;
        }
      } else {
        final response = await ApiService.getSubjects(branchId: selectedBranch!.id);
        if (response.success) {
          options = response.results;
          currentValue = selectedSubject;
        } else {
          hasError = true;
          errorMessage = response.error;
        }
      }
    } catch (e) {
      hasError = true;
      errorMessage = 'Network error: $e';
    }

    setState(() {
      _isLoading = false;
    });

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? 'An error occurred')),
      );
      return;
    }

    await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            List<dynamic> filteredOptions = List.from(options);
            return StatefulBuilder(
              builder: (context, setStateModal) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      Container(
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search ${type[0].toUpperCase()}${type.substring(1)}',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setStateModal(() {
                              filteredOptions = options
                                  .where((element) => element.name
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredOptions.length,
                          itemBuilder: (context, index) {
                            final item = filteredOptions[index];
                            final isSelected = currentValue?.id == item.id;
                            
                            return ListTile(
                              title: Text(item.name),
                              subtitle: type == 'college' && item.location != null
                                  ? Text(item.location)
                                  : null,
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Colors.black)
                                  : null,
                              onTap: () {
                                Navigator.pop(context, item);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          if (type == 'college') {
            selectedCollege = result;
            selectedBranch = null;
            selectedSubject = null;
          }
          if (type == 'branch') {
            selectedBranch = result;
            selectedSubject = null;
          }
          if (type == 'subject') selectedSubject = result;
        });
      }
    });
  }

  Future<void> _pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
          selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadPYQ() async {
    if (!_validateForm()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ApiService.uploadPYQ(
        subjectId: selectedSubject!.id,
        year: int.parse(_yearController.text),
        semester: int.parse(_semesterController.text),
        pdfFile: selectedFile!,
        regulation: _regulationController.text.isNotEmpty 
            ? _regulationController.text 
            : null,
      );

      setState(() {
        _isUploading = false;
      });

      if (response.success) {
        _showSuccessMessage();
      } else {
        _showErrorSnackBar(response.error ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Network error: $e');
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Upload successful. Will be reviewed by moderators.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
    
    // Navigate back after showing message
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _validateForm() {
    if (selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a college')),
      );
      return false;
    }
    if (selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch')),
      );
      return false;
    }
    if (selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return false;
    }
    if (_yearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the year')),
      );
      return false;
    }
    if (_semesterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the semester')),
      );
      return false;
    }
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return false;
    }

    final year = int.tryParse(_yearController.text);
    if (year == null || year < 1950 || year > DateTime.now().year + 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid year')),
      );
      return false;
    }

    final semester = int.tryParse(_semesterController.text);
    if (semester == null || semester < 1 || semester > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid semester (1-8)')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady = selectedCollege != null && 
                        selectedBranch != null && 
                        selectedSubject != null &&
                        _yearController.text.isNotEmpty &&
                        _semesterController.text.isNotEmpty &&
                        selectedFile != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Upload PYQ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload a Previous Year Question Paper',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your upload will be reviewed by moderators before being published.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                
                // College Selection
                _buildSelector(
                  label: 'College',
                  value: selectedCollege?.name,
                  onTap: () => _openSelectionModal('college'),
                ),
                const SizedBox(height: 20),
                
                // Branch Selection
                _buildSelector(
                  label: 'Branch',
                  value: selectedBranch?.name,
                  onTap: () => _openSelectionModal('branch'),
                ),
                const SizedBox(height: 20),
                
                // Subject Selection
                _buildSelector(
                  label: 'Subject',
                  value: selectedSubject?.name,
                  onTap: () => _openSelectionModal('subject'),
                ),
                const SizedBox(height: 20),
                
                // Year and Semester
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          hintText: 'e.g., 2023',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: _semesterController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Semester',
                          hintText: 'e.g., 3',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Regulation (Optional)
                TextField(
                  controller: _regulationController,
                  decoration: InputDecoration(
                    labelText: 'Regulation (Optional)',
                    hintText: 'e.g., R18, R20',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // File Selection
                GestureDetector(
                  onTap: _pickPDFFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: selectedFile != null ? Colors.green : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFileName ?? 'Select PDF File',
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedFile != null ? Colors.black : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedFile != null)
                          const Icon(Icons.check, color: Colors.green),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isReady && !_isUploading) ? _uploadPYQ : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isReady && !_isUploading) 
                          ? Colors.black 
                          : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Uploading...',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Upload PYQ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? 'Select $label',
                style: TextStyle(
                  fontSize: 16,
                  color: value == null ? Colors.grey : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}