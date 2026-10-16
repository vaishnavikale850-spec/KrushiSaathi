import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krushi/CommunityPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  static const Color green = Color(0xFF087A55);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = const ['Crop', 'Product', 'Region'];

  String? _category;
  XFile? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      _showMessage('not able to select image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    final bytes = await _selectedImage!.readAsBytes();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}';

    await Supabase.instance.client.storage
        .from('images')
        .uploadBinary(fileName, bytes);

    return Supabase.instance.client.storage
        .from('images')
        .getPublicUrl(fileName);
  }

 Future<void> _createCommunity() async {
  if (!_formKey.currentState!.validate()) return;

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    _showMessage('To create community please login.');
    return;
  }

  setState(() => _isSaving = true);

  try {
    final imageUrl = await _uploadImage();

    await FirebaseFirestore.instance.collection('communities').add({
      'name': _nameController.text.trim(),
      'category': _category,
      'region': _regionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'imageUrl': imageUrl,
      'createdBy': user.uid,
      'createdByName': user.displayName ?? user.email ?? 'Krushi member',
      'memberIds': <String>[],
      'members': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const CommunityPage(),
      ),
      (route) => false,
    );
  } catch (e) {
    _showMessage('Community was not created: $e');
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('Create Community'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // const Text(
            //   'Start a community',
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //     color: Color(0xFF26382E),
            //   ),
            // ),
            // const SizedBox(height: 5),
            // const Text(
            //   'Bring farmers and shopkeepers together.',
            //   style: TextStyle(color: Colors.black54),
            // ),
            // const SizedBox(height: 20),

            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(
                'Community name',
                hint: 'Example: Tomato Growers',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Community name .'
                      : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: _decoration('Category'),
              hint: const Text('Select category'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _category = value),
              validator: (value) =>
                  value == null ? 'Select Category.' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _regionController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(
                'Region',
                hint: 'Example: Pune',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Region.'
                      : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _decoration(
                'Description',
                hint: 'Describe the community',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Description'
                      : null,
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _selectedImage == null
                    ? 'Add community image (optional)'
                    : 'Change community image',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: green),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 10),
              FutureBuilder(
                future: _selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.memory(
                      snapshot.data!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _createCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 21,
                        width: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Community',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}