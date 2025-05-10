import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'home.dart';

class ApiDoc {
  String name;
  String description;
  String baseUrl;

  ApiDoc({
    required this.name,
    required this.description,
    required this.baseUrl,
  });

  /// Convert ApiDoc to Parse Object
  ParseObject toParseObject(ParseUser user) {
    final parseObject =
        ParseObject('ApiDoc')
          ..set('name', name)
          ..set('description', description)
          ..set('baseUrl', baseUrl)
          ..set('user', user);
    return parseObject;
  }
}

class ApiDocPage extends StatefulWidget {
  final ApiDoc? apiDoc; // Accepting ApiDoc object for Edit mode

  const ApiDocPage({Key? key, this.apiDoc}) : super(key: key);

  @override
  State<ApiDocPage> createState() => _ApiDocPageState();
}

class _ApiDocPageState extends State<ApiDocPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _baseUrlController;

  bool get isEditMode => widget.apiDoc != null;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with ApiDoc data if in edit mode
    _nameController = TextEditingController(text: widget.apiDoc?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.apiDoc?.description ?? '',
    );
    _baseUrlController = TextEditingController(
      text: widget.apiDoc?.baseUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final baseUrl = _baseUrlController.text.trim();

    if (name.isEmpty || baseUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Name and Base URL are required')));
      return;
    }

    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No logged-in user found')));
      return;
    }

    try {
      ParseObject apiDocObject;

      // Try to find an existing ApiDoc by name and user
      final query =
          QueryBuilder(ParseObject('ApiDoc'))
            ..whereEqualTo('name', name)
            ..whereEqualTo('user', currentUser);

      final queryResponse = await query.query();

      if (queryResponse.success &&
          queryResponse.results != null &&
          queryResponse.results!.isNotEmpty) {
        // Edit existing
        apiDocObject = queryResponse.results!.first as ParseObject;
      } else {
        // Create new
        apiDocObject = ParseObject('ApiDoc')..set('user', currentUser);
      }

      // Update fields
      apiDocObject
        ..set('name', name)
        ..set('description', description)
        ..set('baseUrl', baseUrl);

      // Save
      final saveResponse = await apiDocObject.save();

      if (saveResponse.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('API Doc saved successfully')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(),
          ), // replace with your actual home page widget
          (route) => false, // removes all previous routes
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${saveResponse.error?.message}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit API Doc' : 'Create API Doc',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3B4151), // Dark grey app bar
        centerTitle: true,
        elevation: 0, // Removes default shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // White back arrow
          onPressed: () {
            Navigator.pop(context); // Pop the current screen to go back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Name is required';
                  if (value.length > 20)
                    return 'Name must be at most 20 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                maxLines: 3,
                style: TextStyle(fontSize: 13), // Smaller text size
                validator: (value) {
                  if (value != null && value.length > 50) {
                    return 'Description must be at most 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Base URL field
              TextFormField(
                controller: _baseUrlController,
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white, // White background for the input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Base URL is required';
                  if (trimmed.length > 30)
                    return 'Base URL must be at most 30 characters';
                  final urlPattern = r'^https?:\/\/[\w\-\.]+(\.\w+)+.*$';
                  final regex = RegExp(urlPattern);
                  if (!regex.hasMatch(trimmed))
                    return 'Enter a valid HTTP/HTTPS URL Ex: https://myapi.com';
                  return null;
                },
              ),
              const SizedBox(height: 24), // This ensures consistent spacing
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(
                      56,
                      140,
                      224,
                      1,
                    ), // Blue color like login page
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _handleSubmit();
                    }
                  },
                  child: Text(
                    isEditMode ? 'Save Changes' : 'Create API',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Red cancel button
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back without saving
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
