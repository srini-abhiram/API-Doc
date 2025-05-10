import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'api_doc_form.dart';
import 'endpoints.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ParseObject> apiDocs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    // validateSession();
    fetchApiDocs();
  });
  }

  ///Validate and maintain session for a valid, authenticated user
  // Future<void> validateSession() async {
  // final currentUser = await ParseUser.currentUser() as ParseUser?;

  // if (currentUser == null || currentUser.sessionToken == null) {
  //   // No user or session token - redirect to login
  //   Navigator.pushReplacementNamed(context, '/login');
  //   return;
  // }

  // final ParseResponse? sessionResponse =
  //     await ParseUser.getCurrentUserFromServer(currentUser.sessionToken!);

  // if (sessionResponse == null || sessionResponse.success != true) {
  //   // Session expired or invalid
  //   await currentUser.logout();
  //   Navigator.pushReplacementNamed(context, '/login');
  //   return;
  // }

  // Session is valid - proceed to fetch data
  
// }


  Future<void> fetchApiDocs() async {
    setState(() => isLoading = true);

    final user = await ParseUser.currentUser() as ParseUser;
    final query =
        QueryBuilder<ParseObject>(ParseObject('ApiDoc'))
          ..whereEqualTo('user', user)
          ..orderByDescending('createdAt');

    try {
      final List<ParseObject> results = await query.find();

      setState(() {
        apiDocs = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        apiDocs = [];
        isLoading = false;
      });
      debugPrint('Error fetching API docs: \$e');
    }
  }

  void confirmDelete(ParseObject apiDoc) {
    final titleController = TextEditingController();
    final actualTitle = apiDoc.get<String>('name')?.trim() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        bool isMatched = false;
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Enter API title to confirm deletion:'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      onChanged: (value) {
                        final trimmedValue = value.trim();
                        setState(() {
                          isMatched = trimmedValue == actualTitle;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter API title',
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed:
                        isMatched
                            ? () async {
                              await apiDoc.delete();
                              Navigator.pop(context);
                              fetchApiDocs();
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Yes'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('No'),
                  ),
                ],
              ),
        );
      },
    );
  }

  void navigateToEdit(ParseObject apiDoc) {
    // Get name, description, and baseUrl from the clicked item (ParseObject)
    String name = apiDoc.get<String>('name') ?? '';
    String description = apiDoc.get<String>('description') ?? '';
    String baseUrl = apiDoc.get<String>('baseUrl') ?? '';

    // Navigate to edit page with data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ApiDocPage(
              apiDoc: ApiDoc(
                name: name,
                description: description,
                baseUrl: baseUrl,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B4151),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        title: const Text('API docs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiDocPage()),
              );
              fetchApiDocs();
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: apiDocs.length,
                itemBuilder: (context, index) {
                  final api = apiDocs[index];
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        api.get<String>('name') ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            api.get<String>('description') ??
                                'No description provided',
                          ),
                          Text(
                            api.get<String>('baseUrl') ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => navigateToEdit(api),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDelete(api),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye),
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EndpointListPage(apiDoc: api),
                                  ),
                                ),
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
