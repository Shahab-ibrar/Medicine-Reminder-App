import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:medicine_reminder_app/providers/auth_provider.dart';
import 'package:medicine_reminder_app/providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: authProvider.user?.name);
    _ageController =
        TextEditingController(text: authProvider.user?.age.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final age = int.parse(_ageController.text.trim());

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      age: age,
    );

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Opens image picker and uploads the selected photo.
  Future<void> _pickAndUploadPhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final picker = ImagePicker();

    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      bool success;
      if (kIsWeb) {
        // Web: read as bytes
        final bytes = await picked.readAsBytes();
        success = await authProvider.updateProfilePhoto(
          imageBytes: bytes,
          fileName: picked.name,
        );
      } else {
        // Mobile / Desktop: use file path
        success = await authProvider.updateProfilePhoto(
          imageFile: File(picked.path),
          fileName: picked.name,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Profile photo updated!'
                : (authProvider.errorMessage ?? 'Failed to upload photo')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // ── Profile Avatar with camera overlay ─────────────────
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        authProvider.isLoading
                            ? CircleAvatar(
                                radius: 40,
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                child: const CircularProgressIndicator(),
                              )
                            : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                ? CircleAvatar(
                                    radius: 40,
                                    backgroundImage:
                                        NetworkImage(user.photoUrl!),
                                    onBackgroundImageError: (Object e, StackTrace? st) {},
                                  )
                                : CircleAvatar(
                                    radius: 40,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      user?.name.isNotEmpty == true
                                          ? user!.name[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  )),
                        // Camera icon overlay
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: _isEditing
                        ? Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration:
                                    const InputDecoration(labelText: 'Name'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Age'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your age';
                                  }
                                  final age = int.tryParse(value);
                                  if (age == null || age <= 0 || age > 120) {
                                    return 'Enter valid age';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _nameController.text =
                                            user?.name ?? '';
                                        _ageController.text =
                                            user?.age.toString() ?? '';
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : _updateProfile,
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Text(
                                user?.name ?? 'User Name',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'User Email',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Age: ${user?.age ?? 0} years old',
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Profile'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Application Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.accessibility_new_rounded),
                  title: const Text('Elderly Mode'),
                  subtitle: const Text(
                      'Increases text size and contrast for readability'),
                  value: themeProvider.isElderlyMode,
                  onChanged: (val) {
                    themeProvider.toggleElderlyMode(val);
                  },
                ),
                const Divider(height: 1),

                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Reduces screen glare for night viewing'),
                  value: themeProvider.isDark,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                ),
                const Divider(height: 1),

                SwitchListTile(
                  secondary: const Icon(Icons.cloud_sync_rounded),
                  title: const Text('Firebase Sync'),
                  subtitle: const Text(
                      'Store and read data in real-time Firestore'),
                  value: authProvider.isFirebaseEnabled,
                  onChanged: (val) async {
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    await authProvider.toggleServiceMode(val);
                    if (mounted) {
                      nav.pushReplacementNamed('/login');
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? 'Logged out and switched to Firebase Mode.'
                              : 'Logged out and switched to Sandbox Mode.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Project Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectRow('Project Name', 'Medicine Reminder App'),
                  _buildProjectRow('Course', 'Mobile Application Development'),
                  _buildProjectRow('Submitted To', 'Sir. Jawad Khan'),
                  _buildProjectRow('Institution',
                      'Comsats University Islamabad, Abbottabad Campus'),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Group Members:',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _buildMemberRow('Shahab Ibrar', 'FA23-bcs-103'),
                  _buildMemberRow('Shahid Zaman', 'FA23-BCS-104'),
                  _buildMemberRow('Musa Wisal', 'FA23-BCS-082'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text(
                      'Are you sure you want to log out of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await authProvider.signOut();
                if (mounted) {
                  nav.pushReplacementNamed('/login');
                }
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProjectRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMemberRow(String name, String roll) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          const Icon(Icons.person, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(roll, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
