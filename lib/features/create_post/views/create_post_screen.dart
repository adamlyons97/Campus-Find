import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/create_post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _locationDetailsController = TextEditingController();
  
  String _itemType = 'lost'; // Default segment value
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // Static campus-centric classifications mapping directly to your system requirements
  final List<Map<String, String>> _categories = [
    {'id': 'cat_electronics', 'name': 'Electronics & Gadgets'},
    {'id': 'cat_docs', 'name': 'Documents & Cards (Matric/IC)'},
    {'id': 'cat_wallets', 'name': 'Wallets, Purses & Bags'},
    {'id': 'cat_keys', 'name': 'Keys & Access Cards'},
    {'id': 'cat_books', 'name': 'Books & Stationery'},
    {'id': 'cat_others', 'name': 'Others'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _locationDetailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(createPostControllerProvider.notifier).submitItem(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _itemType,
            categoryId: _selectedCategoryId!,
            categoryName: _selectedCategoryName!,
            locationName: _locationNameController.text.trim(),
            locationDetails: _locationDetailsController.text.trim(),
          );

      if (ref.read(createPostControllerProvider).hasError == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully!')),
        );
        context.pop(); // Returns back to dashboard feed smoothly
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(createPostControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Campus Item'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Segmented Toggle for Lost vs Found
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'lost', label: Text('I Lost Something'), icon: Icon(Icons.search_off)),
                    ButtonSegment(value: 'found', label: Text('I Found Something'), icon: Icon(Icons.check_circle_outline)),
                  ],
                  selected: {_itemType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _itemType = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.teal,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                if (submissionState.hasError)
                  Text(
                    submissionState.error.toString(),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Item Name / Title', border: OutlineInputBorder(), hintText: 'e.g., iPhone 13 Pro, Black Wallet'),
                  validator: (value) => value!.isEmpty ? 'Please specify item name' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat['id'], child: Text(cat['name']!));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                      _selectedCategoryName = _categories.firstWhere((element) => element['id'] == val)['name'];
                    });
                  },
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Detailed Description', border: OutlineInputBorder(), hintText: 'Provide unique identifiers (stickers, keychains, scratches) to help verification'),
                  validator: (value) => value!.isEmpty ? 'Please add a description' : null,
                ),
                const SizedBox(height: 24),

                const Text('Location Context', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationNameController,
                  decoration: const InputDecoration(labelText: 'General Location', border: OutlineInputBorder(), hintText: 'e.g., Kuliyyah of ICT, Mahallah Ali Lounge'),
                  validator: (value) => value!.isEmpty ? 'General location context required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationDetailsController,
                  decoration: const InputDecoration(labelText: 'Specific Details / Spot', border: OutlineInputBorder(), hintText: 'e.g., On the corner table near the vending machine'),
                  validator: (value) => value!.isEmpty ? 'Please provide spot detail context' : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: submissionState.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: submissionState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('PUBLISH DISCOVERY REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}