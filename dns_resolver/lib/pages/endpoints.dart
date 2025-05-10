import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:convert';

class EndpointListPage extends StatefulWidget {
  final ParseObject apiDoc;

  const EndpointListPage({super.key, required this.apiDoc});

  @override
  State<EndpointListPage> createState() => _EndpointListPageState();
}

class _EndpointListPageState extends State<EndpointListPage> {
  List<ParseObject> endpoints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEndpoints();
  }

  Future<void> fetchEndpoints() async {
    setState(() => isLoading = true);

    final query =
        QueryBuilder<ParseObject>(ParseObject('Endpoint'))
          ..whereEqualTo('apiDoc', widget.apiDoc)
          ..orderByDescending('createdAt');

    try {
      final List<ParseObject> results = await query.find();

      setState(() {
        endpoints = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        endpoints = [];
        isLoading = false;
      });
      debugPrint('Error fetching endpoints: $e');
    }
  }

  void showAddEndpointDialog({ParseObject? endpointToEdit}) {
    final _formKey = GlobalKey<FormState>();
    final _pathController = TextEditingController();
    final _headersController = TextEditingController();
    final _bodyController = TextEditingController();
    String _method = 'GET';

    if (endpointToEdit != null) {
      _pathController.text = endpointToEdit.get<String>('path') ?? '';
      _method = endpointToEdit.get<String>('method') ?? 'GET';
      _headersController.text = endpointToEdit.get<String>('headers') ?? '';
      _bodyController.text = endpointToEdit.get<String>('body') ?? '';
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            endpointToEdit == null ? 'Add Endpoint' : 'Edit Endpoint',
          ),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint Path',
                      border: OutlineInputBorder(),
                      hintText: '/Users',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^\/[\w\/-]*$').hasMatch(value)) {
                        return 'Invalid endpoint path';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _method,
                    items:
                        ['GET', 'POST', 'PUT', 'DELETE']
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      _method = value!;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _headersController,
                    decoration: const InputDecoration(
                      labelText: 'Headers (JSON)',
                      border: OutlineInputBorder(),
                      hintText: '{"Authorization": "Bearer ..."}',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          Map<String, dynamic>.from(
                            (value.isEmpty ? {} : parseJson(value)),
                          );
                        } catch (_) {
                          return 'Invalid JSON';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Body (JSON)',
                      border: OutlineInputBorder(),
                      hintText: '{"key": "value"}',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          Map<String, dynamic>.from(
                            (value.isEmpty ? {} : parseJson(value)),
                          );
                        } catch (_) {
                          return 'Invalid JSON';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final endpoint = endpointToEdit ?? ParseObject('Endpoint');
                  endpoint
                    ..set('path', _pathController.text)
                    ..set('method', _method)
                    ..set('headers', _headersController.text)
                    ..set('body', _bodyController.text)
                    ..set('apiDoc', widget.apiDoc);

                  await endpoint.save();
                  Navigator.pop(context);
                  fetchEndpoints();
                }
              },
              child: Text(endpointToEdit == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  dynamic parseJson(String input) {
    return input.trim().isEmpty ? {} : jsonDecode(input);
  }

  void confirmDelete(ParseObject endpoint) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this endpoint?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await endpoint.delete();
                Navigator.pop(context);
                fetchEndpoints();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B4151),
        title: Text(
          'Endpoints of ${widget.apiDoc.get<String>('name') ?? ''}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : endpoints.isEmpty
                ? const Center(child: Text('No endpoints added yet.'))
                : ListView.builder(
                  itemCount: endpoints.length,
                  itemBuilder: (_, index) {
                    final endpoint = endpoints[index];
                    final methodColor = getMethodColor(
                      endpoint.get<String>('method') ?? '',
                    );
                    // Border = 25% lighter
                    final borderColor = methodColor;

                    // Background = 75% lighter
                    //final backgroundColor = lightenColor(methodColor, 0.5);

                    final bgColor = Colors.white;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: bgColor, // 50% lighter than method color
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: borderColor,
                        ), // 75% lighter than method color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ExpansionTile(
                        backgroundColor: bgColor,
                        collapsedBackgroundColor: bgColor,
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: methodColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              width: 90,
                              child: Text(
                                endpoint.get<String>('method') ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    endpoint.get<String>('path') ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          showAddEndpointDialog(
                                            endpointToEdit: endpoint,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          confirmDelete(endpoint);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          if (endpoint.get<String>('headers')?.isNotEmpty ??
                              false)
                            ListTile(
                              title: const Text('Headers:'),
                              subtitle: Text(
                                endpoint.get<String>('headers') ?? '{}',
                              ),
                            ),
                          if (endpoint.get<String>('body')?.isNotEmpty ?? false)
                            ListTile(
                              title: const Text('Body:'),
                              subtitle: Text(
                                endpoint.get<String>('body') ?? '{}',
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEndpointDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color lightenColor(Color color, double opacityReduction) {
    // Ensure that opacityReduction is between 0 and 1
    assert(opacityReduction >= 0 && opacityReduction <= 1);

    // Calculate the new opacity by reducing the alpha (transparency) value
    final newAlpha = (color.a * (1 - opacityReduction)).toInt();

    // Return a color with the same RGB values but modified alpha
    return Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0, // Normalized between 0 and 1 for opacity
    );
  }

  Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return const Color(0xFF49CC90); // POST - Green
      case 'PUT':
        return const Color(0xFFFCA130); // PUT - Orange
      case 'GET':
        return const Color(0xFF61AFFE); // GET - Blue
      case 'DELETE':
        return const Color(0xFFF93E3E); // DELETE - Red
      default:
        return Colors.white;
    }
  }
}
