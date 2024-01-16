import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;

  Future<void> _fetchData() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:8000/api/diary'));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _allData = responseData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        // Handle other status codes (if needed)
      }
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to connect to the server. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _addData(String title, String desc) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/data'),
        body: json.encode({'title': title, 'description': desc}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        _fetchData();
      } else {
        print('Failed to add data');
      }
    } catch (e) {
      print('Error adding data: $e');
    }
  }

  Future<void> _updateData(int id, String title, String desc) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/api/data/$id'),
        body: json.encode({'title': title, 'description': desc}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _fetchData();
      } else {
        print('Failed to update data. Status Code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error updating data: $e');
    }
  }

  Future<void> _deleteData(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('http://10.0.2.2:8000/api/data/$id'));

      if (response.statusCode == 204) {
        _fetchData();
      } else {
        print('Failed to delete data');
      }
    } catch (e) {
      print('Error deleting data: $e');
    }
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  void showBottomSheet(int? id) async {
    if (id != null) {
      final existingData =
          _allData.firstWhere((element) => element['id'] == id);

      _titleController.text = existingData['title'];
      _descController.text = existingData['description'];
    }

    //add or update data
    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 40,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Title',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Description',
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (id == null) {
                    await _addData(
                      _titleController.text,
                      _descController.text,
                    );
                  } else {
                    await _updateData(
                      id,
                      _titleController.text,
                      _descController.text,
                    );
                  }

                  _titleController.text = '';
                  _descController.text = '';

                  Navigator.of(context).pop();
                  print('Data saved');
                },
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    id == null ? 'Add Data' : 'Update',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEAF4),
      appBar: AppBar(
        title: const Text('Diary Notes'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _allData.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Text(
                          _allData[index]['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          _allData[index]['created_at'] != null
                              ? DateFormat('MM-dd-yyyy').format(
                                  DateTime.parse(_allData[index]['created_at']),
                                )
                              : 'No Date', // Display 'No Date' if created_at is null
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle:
                      Text(_allData[index]['description'] ?? 'No Description'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showBottomSheet(_allData[index]['id']);
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.indigo,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _deleteData(_allData[index]['id']);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBottomSheet(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
