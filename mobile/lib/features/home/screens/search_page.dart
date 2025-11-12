import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? selectedCollege;
  String? selectedBranch;
  String? selectedSubject;

  // Empty lists for future database integration
  final List<String> colleges = [];
  final Map<String, List<String>> branchesByCollege = {};
  final Map<String, List<String>> subjectsByCollege = {};

  // Admin emails for colleges
  final Map<String, String> collegeAdminEmails = {
    'ABC Engineering College': 'abc_admin@pyqachu.com',
    'XYZ Institute of Tech': 'xyz_admin@pyqachu.com',
    'PQR University': 'pqr_admin@pyqachu.com',
  };

  void _openSelectionModal(String type) async {
    List<String> options;
    String? currentValue;
    String? adminEmail;

    // Dependency checks
    if (type == 'branch' && selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a college first')),
      );
      return;
    }
    if (type == 'subject' && (selectedCollege == null || selectedBranch == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select college and branch first')),
      );
      return;
    }

    // Set options
    if (type == 'college') {
      options = colleges;
      currentValue = selectedCollege;
    } else if (type == 'branch') {
      options = branchesByCollege[selectedCollege] ?? [];
      currentValue = selectedBranch;
      adminEmail = collegeAdminEmails[selectedCollege] ?? 'admin@pyqachu.com';
    } else {
      options = subjectsByCollege[selectedCollege] ?? [];
      currentValue = selectedSubject;
      adminEmail = collegeAdminEmails[selectedCollege] ?? 'admin@pyqachu.com';
    }

    await showModalBottomSheet<String>(
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
              List<String> filteredOptions = List.from(options);
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
                                    .where((element) => element
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
                                    return ListTile(
                                      title: Text(item,
                                          style:
                                              const TextStyle(fontSize: 16)),
                                      trailing: currentValue == item
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
                                  child: Text(
                                    type == 'college'
                                        ? 'College not found? Mail to moderator@pyqachu.com'
                                        : 'No $type found. Mail to $adminEmail',
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey),
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
            selectedSubject = null;
          }
          if (type == 'subject') selectedSubject = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady =
        selectedCollege != null && selectedBranch != null && selectedSubject != null;

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Previous Year Question Papers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            _buildSelector(
              label: 'College',
              value: selectedCollege,
              onTap: () => _openSelectionModal('college'),
            ),
            const SizedBox(height: 20),
            _buildSelector(
              label: 'Branch',
              value: selectedBranch,
              onTap: () => _openSelectionModal('branch'),
            ),
            const SizedBox(height: 20),
            _buildSelector(
              label: 'Subject',
              value: selectedSubject,
              onTap: () => _openSelectionModal('subject'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isReady ? () {} : null,
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
            Text(
              value ?? 'Select $label',
              style: TextStyle(
                fontSize: 16,
                color: value == null ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
