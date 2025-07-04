import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentResourceScreen extends StatefulWidget {
  const StudentResourceScreen({super.key});

  @override
  State<StudentResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<StudentResourceScreen> {
  final _resourcesCollection = FirebaseFirestore.instance.collection('resources');

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${_monthString(date.month)} ${date.day}, ${date.year} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}";
  }

  String _monthString(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String subjectName = args['subjectName'];
    final String className = args['className'];
    final Color color = args['color'] ?? Colors.indigo;

    final bool isLight = color.computeLuminance() > 0.5;
    final Color textColor = isLight ? Colors.black87 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Resources · $subjectName - $className', style: TextStyle(color: textColor)),
        backgroundColor: color,
        foregroundColor: textColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _resourcesCollection
            .where('subjectName', isEqualTo: subjectName)
            .where('className', isEqualTo: className)
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading resources'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No resources available.'));
          }

          final Map<String, List<QueryDocumentSnapshot>> categorizedResources = {};
          for (var doc in docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final category = data['category'] ?? 'Uncategorized';
            categorizedResources.putIfAbsent(category, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: categorizedResources.entries.map((entry) {
              final category = entry.key;
              final resources = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...resources.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: Icon(Icons.library_books, color: Colors.teal[300], size: 32),
                        title: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: data['timestamp'] != null
                            ? Text(
                          'Posted on ${_formatTimestamp(data['timestamp'])}',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                            : null,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/PreviewResourceScreen',
                            arguments: {
                              'docid': doc.id,
                              'data': data,
                              'color': color,
                            },
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
