import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String photoPathOrUrl;
  final bool isLocalFile;

  const ContactCardData({
    required this.name,
    required this.relation,
    required this.phoneNumber,
    required this.photoPathOrUrl,
    required this.isLocalFile,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'phoneNumber': phoneNumber,
        'photoPathOrUrl': photoPathOrUrl,
        'isLocalFile': isLocalFile,
      };

  factory ContactCardData.fromJson(Map<String, dynamic> json) {
    return ContactCardData(
      name: json['name'] as String? ?? 'Contact',
      relation: json['relation'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      photoPathOrUrl: json['photoPathOrUrl'] as String? ?? '',
      isLocalFile: json['isLocalFile'] as bool? ?? false,
    );
  }
}

class PhotoCallScreen extends StatefulWidget {
  const PhotoCallScreen({super.key});

  @override
  State<PhotoCallScreen> createState() => _PhotoCallScreenState();
}

class _PhotoCallScreenState extends State<PhotoCallScreen> {
  static const String _storageKey = 'saved_senior_contacts_v1';

  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  int _currentIndex = 0;
  bool _isLoading = true;
  List<ContactCardData> _contacts = [];

  final List<ContactCardData> _defaultContacts = const [
    ContactCardData(
      name: 'Rahul',
      relation: 'Son',
      phoneNumber: '+919876543210',
      photoPathOrUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop',
      isLocalFile: false,
    ),
    ContactCardData(
      name: 'Priya',
      relation: 'Daughter',
      phoneNumber: '+919876543211',
      photoPathOrUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop',
      isLocalFile: false,
    ),
    ContactCardData(
      name: 'Dr. Kulkarni',
      relation: 'Family Doctor',
      phoneNumber: '+919876543212',
      photoPathOrUrl:
          'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=800&auto=format&fit=crop',
      isLocalFile: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _contacts = decoded
            .map((item) => ContactCardData.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _contacts = List<ContactCardData>.from(_defaultContacts);
      }
    } else {
      _contacts = List<ContactCardData>.from(_defaultContacts);
      await _saveContacts();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _makePhoneCall(BuildContext context, ContactCardData person) async {
    final Uri telUri = Uri(scheme: 'tel', path: person.phoneNumber.trim());
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

  Future<void> _openAddContactDialog() async {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();
    String? pickedImagePath;

    final ContactCardData? newContact = await showDialog<ContactCardData>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickPhoto() async {
              final XFile? file = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );
              if (file != null) {
                setDialogState(() {
                  pickedImagePath = file.path;
                });
              }
            }

            return AlertDialog(
              title: const Text(
                'Add New Contact',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: pickPhoto,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: pickedImagePath != null
                            ? Image.file(
                                File(pickedImagePath!),
                                fit: BoxFit.cover,
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 36),
                                  SizedBox(height: 6),
                                  Text(
                                    'Pick Photo',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Name (e.g. Aai)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: relationController,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Relation (e.g. Mother)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (e.g. +9198...)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final relation = relationController.text.trim();

                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter both Name and Phone Number'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      ContactCardData(
                        name: name,
                        relation: relation.isEmpty ? 'Family' : relation,
                        phoneNumber: phone,
                        photoPathOrUrl: pickedImagePath ?? '',
                        isLocalFile: pickedImagePath != null,
                      ),
                    );
                  },
                  child: const Text('Save', style: TextStyle(fontSize: 18)),
                ),
              ],
            );
          },
        );
      },
    );

    if (newContact != null) {
      setState(() {
        _contacts.add(newContact);
        _currentIndex = _contacts.length - 1;
      });
      await _saveContacts();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
  }

  Future<void> _deleteCurrentContact() async {
    if (_contacts.isEmpty) return;

    final person = _contacts[_currentIndex];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text('Remove ${person.name} from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _contacts.removeAt(_currentIndex);
        if (_currentIndex >= _contacts.length && _contacts.isNotEmpty) {
          _currentIndex = _contacts.length - 1;
        } else if (_contacts.isEmpty) {
          _currentIndex = 0;
        }
      });
      await _saveContacts();

      if (_contacts.isNotEmpty && _pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  Widget _buildPhoto(ContactCardData person) {
    if (person.photoPathOrUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, size: 110, color: Colors.grey),
      );
    }

    if (person.isLocalFile) {
      return Image.file(
        File(person.photoPathOrUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 110, color: Colors.grey),
          );
        },
      );
    }

    return Image.network(
      person.photoPathOrUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.person, size: 110, color: Colors.grey),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasContacts = _contacts.isNotEmpty;
    final safeIndex = hasContacts ? _currentIndex.clamp(0, _contacts.length - 1) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: Text(
          hasContacts
              ? 'Person ${safeIndex + 1} of ${_contacts.length}'
              : 'No Contacts',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (hasContacts)
            IconButton(
              onPressed: _deleteCurrentContact,
              tooltip: 'Remove contact',
              icon: const Icon(Icons.delete_outline, size: 26),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              onPressed: _openAddContactDialog,
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Add', style: TextStyle(fontSize: 17)),
            ),
          ),
        ],
      ),
      body: !hasContacts
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No contacts added yet.',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: _openAddContactDialog,
                        icon: const Icon(Icons.person_add, size: 28),
                        label: const Text(
                          'ADD FIRST CONTACT',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
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
                              Expanded(child: _buildPhoto(person)),
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
                        onPressed: safeIndex > 0
                            ? () => _goToPage(safeIndex - 1)
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
                        onPressed: safeIndex < _contacts.length - 1
                            ? () => _goToPage(safeIndex + 1)
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
                            _makePhoneCall(context, _contacts[safeIndex]),
                        icon: const Icon(Icons.call, size: 34, color: Colors.white),
                        label: Text(
                          'CALL ${_contacts[safeIndex].name.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
