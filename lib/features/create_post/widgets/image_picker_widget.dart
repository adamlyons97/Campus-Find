import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';

/// Lets the user attach clear photo evidence (Feature 2) from camera or
/// gallery. Calls [onChanged] with the selected [XFile] (or null if cleared).
///
/// Uses [XFile] + in-memory bytes so it works identically on web and mobile
/// (a `dart:io` File is not available in the browser).
class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key, required this.onChanged});

  final ValueChanged<XFile?> onChanged;

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _bytes;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _picked = picked;
        _bytes = bytes;
      });
      widget.onChanged(_picked);
    }
  }

  void _clear() {
    setState(() {
      _picked = null;
      _bytes = null;
    });
    widget.onChanged(null);
  }

  void _showSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            if (_picked != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.danger),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  _clear();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showSheet,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8DED8)),
          image: _bytes == null
              ? null
              : DecorationImage(
                  image: MemoryImage(_bytes!), fit: BoxFit.cover),
        ),
        child: _bytes != null
            ? null
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40, color: AppTheme.primaryLight),
                  SizedBox(height: 8),
                  Text('Add photo evidence'),
                ],
              ),
      ),
    );
  }
}
