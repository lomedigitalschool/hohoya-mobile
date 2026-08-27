import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  final _cropper = ImageCropper();
  File? _image;
  String? _remotePictureUrl;
  bool _isPicking = false;
  bool _isUploading = false;

  Future<void> _choosePicture(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      final cropped = await _cropper.cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Recadrer la photo', lockAspectRatio: true),
          IOSUiSettings(title: 'Recadrer la photo', aspectRatioLockEnabled: true),
        ],
      );
      if (cropped != null && mounted) setState(() => _image = File(cropped.path));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de sélectionner cette photo.')));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _uploadPicture() async {
    final image = _image;
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await AuthService().uploadProfilePicture(image);
      if (!mounted) return;
      setState(() => _remotePictureUrl = url.isEmpty ? null : url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil mise à jour.')));
    } on GoogleAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de l’envoi. Réessayez.')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choisir dans la galerie'), onTap: () { Navigator.pop(context); _choosePicture(ImageSource.gallery); }),
        ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Prendre une photo'), onTap: () { Navigator.pop(context); _choosePicture(ImageSource.camera); }),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPicture = _image != null || _remotePictureUrl != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Center(child: Stack(children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: Colors.teal.shade50,
            backgroundImage: _image != null ? FileImage(_image!) : (_remotePictureUrl != null ? NetworkImage(_remotePictureUrl!) : null) as ImageProvider?,
            child: hasPicture ? null : const Icon(Icons.person_outline, size: 64, color: Colors.teal),
          ),
          Positioned(right: 0, bottom: 0, child: FloatingActionButton.small(onPressed: _isPicking ? null : _openPicker, tooltip: 'Changer la photo', child: const Icon(Icons.camera_alt_outlined))),
        ])),
        const SizedBox(height: 24),
        const Text('Photo de profil', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Choisissez une image carrée depuis la galerie ou la caméra.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _image == null || _isUploading ? null : _uploadPicture, icon: _isUploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_outlined), label: Text(_isUploading ? 'Envoi...' : 'Enregistrer la photo')),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: () => Navigator.of(context).pushNamed('/owner-properties'), icon: const Icon(Icons.home_work_outlined), label: const Text('Mon portefeuille')),
      ]),
    );
  }
}
