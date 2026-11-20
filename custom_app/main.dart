import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SeniorCallApp());
}

class SeniorCallApp extends StatelessWidget {
  const SeniorCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Photo Call',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PhotoCallScreen(),
    );
  }
}

class ContactCardData {
  final String name;
  final String relation;
  final String phoneNumber;
  final String photoUrl;

  const ContactCardData({
    required this.name,
    required this.relation,
    required this.phoneNumber,
    required this.photoUrl,
  });
}

class PhotoCallScreen extends StatefulWidget {
  const PhotoCallScreen({super.key});

  @override
  State<PhotoCallScreen> createState() => _PhotoCallScreenState();
}

class _PhotoCallScreenState extends State<PhotoCallScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<ContactCardData> _contacts = const [
    ContactCardData(
      name: 'Rahul',
      relation: 'Son',
      phoneNumber: '+919876543210',
      photoUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop',
    ),
    ContactCardData(
      name: 'Priya',
      relation: 'Daughter',
      phoneNumber: '+919876543211',
      photoUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop',
    ),
    ContactCardData(
      name: 'Dr. Kulkarni',
      relation: 'Family Doctor',
      phoneNumber: '+919876543212',
      photoUrl:
          'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=800&auto=format&fit=crop',
    ),
  ];

  Future<void> _makePhoneCall(BuildContext context, ContactCardData person) async {
    final Uri telUri = Uri(scheme: 'tel', path: person.phoneNumber);
    try {
      final bool launched = await launchUrl(telUri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for ${person.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting call: $e')),
        );
      }
    }
  }

  void _goToPage(int newIndex) {
    if (newIndex < 0 || newIndex >= _contacts.length) return;
    _pageController.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: Text(
          'Person ${_currentIndex + 1} of ${_contacts.length}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _contacts.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final person = _contacts[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Card(
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.network(
                            person.photoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.person,
                                  size: 110,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              Text(
                                person.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                person.relation,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () => _goToPage(_currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back, size: 26),
                  label: const Text('Previous', style: TextStyle(fontSize: 20)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _currentIndex < _contacts.length - 1
                      ? () => _goToPage(_currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 26),
                  label: const Text('Next', style: TextStyle(fontSize: 20)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 76,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _makePhoneCall(context, _contacts[_currentIndex]),
                  icon: const Icon(Icons.call, size: 34, color: Colors.white),
                  label: Text(
                    'CALL ${_contacts[_currentIndex].name.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8E3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
