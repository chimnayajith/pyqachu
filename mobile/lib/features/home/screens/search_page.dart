import 'package:flutter/material.dart';
import 'package:pyqachu/core/models/api_models.dart';
import 'package:pyqachu/core/services/api_service.dart';
import 'package:pyqachu/features/pyq/screens/pyq_results_page.dart';
import 'package:pyqachu/features/pyq/screens/pyq_upload_page.dart';
import 'package:pyqachu/features/bookmark/screens/bookmark_page.dart';
import 'package:pyqachu/features/profile/screens/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  College? selectedCollege;
  Branch? selectedBranch;
  Subject? selectedSubject;

  bool _isLoading = false;
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openSelectionModal(String type) async {
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
          // Add "All Branches" as the first option with a special ID
          final allBranchesOption = Branch(
            id: -1, // Special ID to identify "All Branches"
            name: 'All Branches',
            code: null,
            college: selectedCollege!.id,
            collegeName: selectedCollege!.name,
            isActive: true,
            createdBy: null,
            createdByUsername: null,
            createdAt: DateTime.now(),
          );
          options.insert(0, allBranchesOption);
          currentValue = selectedBranch;
        } else {
          hasError = true;
          errorMessage = response.error;
        }
      } else {
        // Subject selection logic
        ApiResponse<Subject> response;
        if (selectedBranch!.id == -1) {
          // "All Branches" is selected, search across all branches
          response = await ApiService.getSubjects(collegeId: selectedCollege!.id);
        } else {
          // Specific branch is selected
          response = await ApiService.getSubjects(branchId: selectedBranch!.id);
        }
        
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
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            );
          },
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              List<dynamic> filteredOptions = List.from(options);
              return StatefulBuilder(
                builder: (context, setStateModal) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(25)),
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
                              hintText:
                                  'Search ${type[0].toUpperCase()}${type.substring(1)}',
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
                          child: filteredOptions.isNotEmpty
                              ? ListView.builder(
                                  controller: scrollController,
                                  itemCount: filteredOptions.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredOptions[index];
                                    final isSelected = currentValue?.id == item.id;
                                    String? subtitle;
                                    Widget? leadingIcon;
                                    
                                    if (type == 'college' && item.location != null) {
                                      subtitle = item.location;
                                    } else if (type == 'branch' && item.id == -1) {
                                      // Special styling for "All Branches" option
                                      subtitle = 'Search subjects from any branch';
                                      leadingIcon = Icon(Icons.apps, color: Colors.grey.shade600, size: 20);
                                    } else if (type == 'subject' && selectedBranch?.id == -1) {
                                      // Show branch name when "All Branches" is selected
                                      subtitle = item.branchName;
                                    }
                                    
                                    return ListTile(
                                      leading: leadingIcon,
                                      title: Text(item.name,
                                          style:
                                              const TextStyle(fontSize: 16)),
                                      subtitle: subtitle != null 
                                          ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600))
                                          : null,
                                      trailing: isSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.black)
                                          : null,
                                      onTap: () {
                                        Navigator.pop(context, item);
                                      },
                                    );
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.search_off, 
                                           size: 64, 
                                           color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No ${type}s found',
                                        style: const TextStyle(
                                            fontSize: 18, 
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        type == 'college'
                                            ? 'College not found? Contact moderator@pyqachu.com'
                                            : 'No ${type}s available for this selection',
                                        style: TextStyle(
                                            fontSize: 14, 
                                            color: Colors.grey.shade600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
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
            selectedSubject = null; // Clear subject when branch changes
          }
          if (type == 'subject') selectedSubject = result;
        });
      }
    });
  }

  void _searchPYQs() async {
    if (selectedCollege == null || selectedBranch == null || selectedSubject == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getPYQs(subjectId: selectedSubject!.id);
      
      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PyqResultsPage(
              subject: selectedSubject!,
              initialPyqs: response.results,
            ),  
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to search PYQs')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  Widget _buildSearchContent() {
    final bool isReady = selectedCollege != null && selectedBranch != null && selectedSubject != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Find your PYQs',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Image.asset(
            'assets/images/logo.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Search Previous Year Question Papers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PYQUploadPage()),
                        );
                        if (result == true) {
                          // Refresh data if needed
                        }
                      },
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text(
                        'Upload',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSelector(
                  label: 'College',
                  value: selectedCollege?.name,
                  onTap: () => _openSelectionModal('college'),
                ),
                const SizedBox(height: 20),
                _buildSelector(
                  label: 'Branch',
                  value: selectedBranch?.name,
                  onTap: () => _openSelectionModal('branch'),
                ),
                const SizedBox(height: 20),
                _buildSelector(
                  label: 'Subject',
                  value: selectedSubject?.name,
                  onTap: () => _openSelectionModal('subject'),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isReady ? _searchPYQs : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isReady ? Colors.black : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
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
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildSearchContent(),
          const BookmarkPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Bookmark',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String? value,
    required VoidCallback onTap,
    String? hint,
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
                value ?? hint ?? 'Select $label',
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
