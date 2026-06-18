import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/gemini_ai_service.dart';
import '../../auth/widgets/auth_validator_field.dart';
import '../providers/create_post_provider.dart';
import '../widgets/image_picker_widget.dart';

class CreateItemForm extends ConsumerStatefulWidget {
  const CreateItemForm({super.key, this.initialType});

  /// Optional preset ('lost' or 'found') passed from the home report cards.
  final String? initialType;

  @override
  ConsumerState<CreateItemForm> createState() => _CreateItemFormState();
}

class _CreateItemFormState extends ConsumerState<CreateItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationName = TextEditingController();
  final _locationDetails = TextEditingController();
  final _finderNotes = TextEditingController();

  late String _type = widget.initialType ?? ItemType.lost;
  CategoryModel? _category;
  XFile? _image;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _locationName.dispose();
    _locationDetails.dispose();
    _finderNotes.dispose();
    super.dispose();
  }

  Future<void> _submit(List<CategoryModel> categories) async {
    if (!_formKey.currentState!.validate()) return;
    final category = _category ?? categories.first;

    final result = await ref.read(createPostControllerProvider.notifier).submit(
          title: _title.text,
          description: _description.text,
          type: _type,
          category: category,
          locationName: _locationName.text,
          locationDetails: _locationDetails.text,
          image: _image,
          finderClaimRequestNotes:
              _type == ItemType.found ? _finderNotes.text : null,
        );

    if (!mounted) return;
    final state = ref.read(createPostControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(state.error.toString()),
            backgroundColor: AppTheme.danger),
      );
      return;
    }

    if (result != null && result.suggestedMatches.isNotEmpty) {
      await _showMatchDialog(result.suggestedMatches);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. JazakAllahu khairan!')),
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _showMatchDialog(List<AiMatch> matches) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.accent),
            SizedBox(width: 8),
            Text('Possible Matches'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our AI found existing listings that may match your report:',
            ),
            const SizedBox(height: 12),
            ...matches.take(3).map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text('${m.confidence}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                    title: Text(m.reason,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/item/${m.itemId}');
                    },
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Item')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (categories) {
          _category ??= categories.first;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: ItemType.lost,
                          label: Text('I Lost'),
                          icon: Icon(Icons.search_off)),
                      ButtonSegment(
                          value: ItemType.found,
                          label: Text('I Found'),
                          icon: Icon(Icons.volunteer_activism_outlined)),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                  const SizedBox(height: 20),
                  if (_type == ItemType.found)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.accent),
                          SizedBox(width: 10),
                          Expanded(
                              child: Text(AppStrings.luqatahFinderNotice,
                                  style: TextStyle(fontSize: 12.5))),
                        ],
                      ),
                    ),
                  ImagePickerWidget(
                      onChanged: (f) => setState(() => _image = f)),
                  const SizedBox(height: 16),
                  AuthValidatorField(
                    controller: _title,
                    label: 'Item Title',
                    hint: 'e.g. Blue leather wallet',
                    icon: Icons.title,
                    validator: (v) =>
                        Validators.requiredField(v, field: 'Title'),
                  ),
                  AuthValidatorField(
                    controller: _description,
                    label: 'Detailed Description',
                    hint: 'Colour, brand, distinctive marks…',
                    icon: Icons.description_outlined,
                    validator: (v) =>
                        Validators.requiredField(v, field: 'Description'),
                  ),
                  DropdownButtonFormField<CategoryModel>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() => _category = c),
                  ),
                  const SizedBox(height: 16),
                  AuthValidatorField(
                    controller: _locationName,
                    label: 'Location',
                    hint: 'e.g. HS Cafe',
                    icon: Icons.place_outlined,
                    validator: (v) =>
                        Validators.requiredField(v, field: 'Location'),
                  ),
                  AuthValidatorField(
                    controller: _locationDetails,
                    label: 'Specific Details (optional)',
                    hint: 'e.g. Third table from entrance',
                    icon: Icons.notes_outlined,
                  ),
                  if (_type == ItemType.found)
                    AuthValidatorField(
                      controller: _finderNotes,
                      label: 'Handover Notes (optional)',
                      hint: 'How should the owner collect this item?',
                      icon: Icons.handshake_outlined,
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed:
                        state.isLoading ? null : () => _submit(categories),
                    icon: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(state.isLoading
                        ? 'Submitting & matching…'
                        : 'Submit Report'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
