import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RaiseProblemPage extends StatefulWidget {
  const RaiseProblemPage({super.key});

  @override
  State<RaiseProblemPage> createState() => _RaiseProblemPageState();
}

class _RaiseProblemPageState extends State<RaiseProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cropController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _picker = ImagePicker();
  XFile? selectedImage;
  String? _category;
  File? _image;
  bool _isSaving = false;

  static const _green = Color(0xFF087A55);

  @override
  void dispose() {
    _titleController.dispose();
    _cropController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  //PickImage from gallery
  Future<void> pickImage() async {
  final picked = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (picked != null && mounted) {
    setState(() => selectedImage = picked);
  }
}

//uploadImage to supabase
Future<String?> uploadImage() async {
  if (selectedImage == null) return null;

  final bytes = await selectedImage!.readAsBytes();
  final fileName =
      '${DateTime.now().millisecondsSinceEpoch}_${selectedImage!.name}';

  await Supabase.instance.client.storage
      .from('images')
      .uploadBinary(fileName, bytes);

  return Supabase.instance.client.storage
      .from('images')
      .getPublicUrl(fileName);
}

//get real from supabase and upload on firebase
 Future<void> submitProblem() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSaving = true);

  try {
    final imageUrl = await uploadImage();
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('discussions').add({
      'title': _titleController.text.trim(),
      'cropName': _cropController.text.trim(),
      'category': _category,
      'description': _descriptionController.text.trim(),
      'imageUrl': imageUrl,
      'authorId': user?.uid,
      'authorName': user?.displayName ?? user?.email ?? 'Krushi member',
      'likes': 0,
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Problem posted successfully')),
    );
    Navigator.pop(context);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post problem: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF23342B),
        elevation: 0,
        title: const Text(
          'Raise a Problem',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              const Text('Title'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: _decoration(
                  'Enter problem title',
                  hint: 'Enter problem title',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 14),

              const Text('Crop Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cropController,
                decoration: _decoration('Select crop', hint: 'Example: Tomato'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the crop name'
                    : null,
              ),
              const SizedBox(height: 14),

              const Text('Category'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _decoration('Select category'),
                items:
                    const [
                      'Pest',
                      'Disease',
                      'Soil',
                      'Irrigation',
                      'Fertilizer',
                      'Other',
                    ].map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Choose a category' : null,
              ),
              const SizedBox(height: 14),

              const Text('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _decoration(
                  'Describe the problem in detail...',
                  hint: 'Describe the problem in detail...',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 14),

              const Text('Image'),
              const SizedBox(height: 6),
              InkWell(
                onTap: pickImage,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDDE5E0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: _green),
                            SizedBox(height: 5),
                            Text(
                              'Add Image',
                              style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_image!, fit: BoxFit.cover),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: IconButton(
                                  onPressed: () =>
                                      setState(() => _image = null),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : submitProblem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                          'Post Problem',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
