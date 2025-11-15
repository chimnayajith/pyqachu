import 'package:flutter/material.dart';
import 'package:pyqachu/core/models/api_models.dart';
import 'package:pyqachu/core/services/api_service.dart';
import 'package:pyqachu/features/pyq/screens/pyq_viewer.dart';

class PyqResultsPage extends StatefulWidget {
  final Subject subject;
  final List<PreviousYearQuestion> initialPyqs;

  const PyqResultsPage({
    super.key,
    required this.subject,
    required this.initialPyqs,
  });

  @override
  State<PyqResultsPage> createState() => _PyqResultsPageState();
}

class _PyqResultsPageState extends State<PyqResultsPage> {
  List<PreviousYearQuestion> _allPyqs = [];
  List<PreviousYearQuestion> _filteredPyqs = [];
  bool _isGridView = false;
  bool _isLoading = false;

  // Filter variables
  int? _selectedYear;
  int? _selectedSemester;
  String? _selectedRegulation;

  // Get unique values for filters
  List<int> get _availableYears {
    final years = _allPyqs.map((pyq) => pyq.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Sort descending (newest first)
    return years;
  }

  List<int> get _availableSemesters {
    final semesters = _allPyqs.map((pyq) => pyq.semester).toSet().toList();
    semesters.sort();
    return semesters;
  }

  List<String> get _availableRegulations {
    final regulations = _allPyqs
        .where((pyq) => pyq.regulation != null && pyq.regulation!.isNotEmpty)
        .map((pyq) => pyq.regulation!)
        .toSet()
        .toList();
    regulations.sort();
    return regulations;
  }

  @override
  void initState() {
    super.initState();
    _allPyqs = List.from(widget.initialPyqs);
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredPyqs = _allPyqs.where((pyq) {
        if (_selectedYear != null && pyq.year != _selectedYear) return false;
        if (_selectedSemester != null && pyq.semester != _selectedSemester) return false;
        if (_selectedRegulation != null && pyq.regulation != _selectedRegulation) return false;
        return true;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getPYQs(
        subjectId: widget.subject.id,
        year: _selectedYear,
        semester: _selectedSemester,
        regulation: _selectedRegulation,
      );

      if (response.success) {
        setState(() {
          _allPyqs = response.results;
          _applyFilters();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to refresh data'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.black87,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedSemester = null;
      _selectedRegulation = null;
    });
    _applyFilters();
  }

  void _onPyqTapped(PreviousYearQuestion pyq) {
    // Navigate to PDF viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pyq: pyq),
      ),
    );
  }

  Widget _buildFilterChips() {
    final hasActiveFilters = _selectedYear != null || _selectedSemester != null || _selectedRegulation != null;

    return Container(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Year filter
            if (_availableYears.isNotEmpty)
              _buildFilterChip(
                label: _selectedYear?.toString() ?? 'Year',
                isSelected: _selectedYear != null,
                onTap: () => _showFilterModal('year'),
              ),

            if (_availableYears.isNotEmpty && (_availableSemesters.isNotEmpty || _availableRegulations.isNotEmpty))
              const SizedBox(width: 12),

            // Semester filter
            if (_availableSemesters.isNotEmpty)
              _buildFilterChip(
                label: _selectedSemester != null ? 'Sem $_selectedSemester' : 'Semester',
                isSelected: _selectedSemester != null,
                onTap: () => _showFilterModal('semester'),
              ),

            if (_availableSemesters.isNotEmpty && _availableRegulations.isNotEmpty)
              const SizedBox(width: 12),

            // Regulation filter
            if (_availableRegulations.isNotEmpty)
              _buildFilterChip(
                label: _selectedRegulation ?? 'Regulation',
                isSelected: _selectedRegulation != null,
                onTap: () => _showFilterModal('regulation'),
              ),

            // Clear filters
            if (hasActiveFilters) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showFilterModal(String filterType) {
    List<dynamic> options = [];
    dynamic currentValue;

    switch (filterType) {
      case 'year':
        options = _availableYears;
        currentValue = _selectedYear;
        break;
      case 'semester':
        options = _availableSemesters;
        currentValue = _selectedSemester;
        break;
      case 'regulation':
        options = _availableRegulations;
        currentValue = _selectedRegulation;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Filter by ${filterType}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: Text('All ${filterType}s'),
                      trailing: currentValue == null ? const Icon(Icons.check, size: 20) : null,
                      onTap: () {
                        setState(() {
                          switch (filterType) {
                            case 'year':
                              _selectedYear = null;
                              break;
                            case 'semester':
                              _selectedSemester = null;
                              break;
                            case 'regulation':
                              _selectedRegulation = null;
                              break;
                          }
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                    );
                  }

                  final option = options[index - 1];
                  final isSelected = currentValue == option;

                  return ListTile(
                    title: Text(option.toString()),
                    trailing: isSelected ? const Icon(Icons.check, size: 20) : null,
                    onTap: () {
                      setState(() {
                        switch (filterType) {
                          case 'year':
                            _selectedYear = option;
                            break;
                          case 'semester':
                            _selectedSemester = option;
                            break;
                          case 'regulation':
                            _selectedRegulation = option;
                            break;
                        }
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredPyqs.length,
      itemBuilder: (context, index) {
        final pyq = _filteredPyqs[index];
        return GestureDetector(
          onTap: () => _onPyqTapped(pyq),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pyq.year}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Semester ${pyq.semester}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (pyq.regulation != null && pyq.regulation!.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              pyq.regulation!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredPyqs.length,
      itemBuilder: (context, index) {
        final pyq = _filteredPyqs[index];
        return GestureDetector(
          onTap: () => _onPyqTapped(pyq),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    Text(
                      'Sem ${pyq.semester}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Year ${pyq.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                if (pyq.regulation != null && pyq.regulation!.isNotEmpty)
                  Text(
                    pyq.regulation!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPyqResultsContent() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              child: Image.asset(
                'assets/images/logo.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.subject.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.subject.branchName} • ${widget.subject.collegeName}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Filter chips
          if (_availableYears.isNotEmpty || _availableSemesters.isNotEmpty || _availableRegulations.isNotEmpty)
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFilterChips(),
            ),

          // Results count
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredPyqs.length} question paper${_filteredPyqs.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (_isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _filteredPyqs.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No question papers found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: Colors.black,
                    child: _isGridView ? _buildGridView() : _buildListView(),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPyqResultsContent();
  }
}