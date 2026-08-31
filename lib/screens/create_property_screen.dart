import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/property.dart';
import '../services/property_service.dart';

class CreatePropertyScreen extends StatefulWidget {
  final Property? property;
  const CreatePropertyScreen({super.key, this.property});

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController(text: 'Lome');
  final _neighborhood = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _deposit = TextEditingController();
  final _picker = ImagePicker();
  int _step = 0;
  String _type = 'Appartement';
  String _priceType = 'location';
  int _bedrooms = 2;
  int _bathrooms = 1;
  int _area = 70;
  int _coverIndex = 0;
  bool _isSaving = false;
  bool _isPicking = false;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    final property = widget.property;
    if (property != null) {
      _title.text = property.title;
      _description.text = property.description;
      _city.text = property.city;
      _neighborhood.text = property.neighborhood;
      _address.text = property.address;
      _price.text = property.price.toStringAsFixed(0);
      _deposit.text = property.deposit.toStringAsFixed(0);
      _type = property.type;
      _priceType = property.priceType;
      _bedrooms = property.bedrooms;
      _bathrooms = property.bathrooms;
      _area = property.area;
      _images = List.of(property.images);
    }
    _restoreDraft();
  }

  @override
  void dispose() {
    for (final controller in [_title, _description, _city, _neighborhood, _address, _price, _deposit]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    if (widget.property != null) return;
    final preferences = await SharedPreferences.getInstance();
    if (!mounted || preferences.getBool('property_draft_exists') != true) return;
    setState(() {
      _title.text = preferences.getString('draft_title') ?? '';
      _description.text = preferences.getString('draft_description') ?? '';
      _city.text = preferences.getString('draft_city') ?? 'Lome';
      _neighborhood.text = preferences.getString('draft_neighborhood') ?? '';
      _address.text = preferences.getString('draft_address') ?? '';
      _price.text = preferences.getString('draft_price') ?? '';
      _deposit.text = preferences.getString('draft_deposit') ?? '';
    });
  }

  Future<void> _saveDraft() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('property_draft_exists', true);
    await preferences.setString('draft_title', _title.text);
    await preferences.setString('draft_description', _description.text);
    await preferences.setString('draft_city', _city.text);
    await preferences.setString('draft_neighborhood', _neighborhood.text);
    await preferences.setString('draft_address', _address.text);
    await preferences.setString('draft_price', _price.text);
    await preferences.setString('draft_deposit', _deposit.text);
  }

  String? _required(String? value, String label) => value == null || value.trim().isEmpty ? '$label requis' : null;

  bool _validateStep() {
    if (_step == 0) return _formKey.currentState?.validate() ?? false;
    if (_step == 1) return _required(_city.text, 'Ville') == null && _required(_neighborhood.text, 'Quartier') == null && _required(_address.text, 'Adresse') == null;
    if (_step == 2) return double.tryParse(_price.text) != null && double.parse(_price.text) > 0;
    return true;
  }

  void _next() {
    if (!_validateStep()) {
      setState(() {});
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final picked = source == ImageSource.gallery ? await _picker.pickMultiImage() : [(await _picker.pickImage(source: source))].whereType<XFile>().toList();
      if (mounted) setState(() => _images = [..._images, ...picked.map((file) => file.path)]);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de l’ajout de la photo. Réessayez.')));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _reorderImages(int oldIndex, int newIndex) => setState(() { if (newIndex > oldIndex) newIndex--; final image = _images.removeAt(oldIndex); _images.insert(newIndex, image); _coverIndex = 0; });

  Future<void> _publish() async {
    if (_images.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins une photo.'))); return; }
    setState(() => _isSaving = true);
    final service = PropertyService();
    if (widget.property == null) {
      final property = await service.createProperty(title: _title.text.trim(), city: _city.text.trim(), neighborhood: _neighborhood.text.trim(), address: _address.text.trim(), type: _type, price: double.parse(_price.text), priceType: _priceType, deposit: double.tryParse(_deposit.text) ?? 0, bedrooms: _bedrooms, bathrooms: _bathrooms, area: _area, description: _description.text.trim(), images: _images);
      await service.uploadPropertyImages(property.id, _images);
    } else {
      await service.updateProperty(widget.property!, title: _title.text.trim(), city: _city.text.trim(), neighborhood: _neighborhood.text.trim(), type: _type, price: double.parse(_price.text), bedrooms: _bedrooms, bathrooms: _bathrooms, area: _area, description: _description.text.trim());
      await service.uploadPropertyImages(widget.property!.id, _images);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('property_draft_exists');
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Infos de base', 'Localisation', 'Prix', 'Photos'];
    return Scaffold(
      appBar: AppBar(title: Text(widget.property == null ? 'Publier un bien' : 'Modifier l’annonce'), actions: [IconButton(onPressed: _saveDraft, icon: const Icon(Icons.save_outlined), tooltip: 'Sauvegarder le brouillon')]),
      body: Form(key: _formKey, child: Column(children: [
        Expanded(child: Stepper(currentStep: _step, onStepContinue: _next, onStepCancel: _step == 0 ? null : () => setState(() => _step--), controlsBuilder: (context, details) => Padding(padding: const EdgeInsets.only(top: 16), child: Row(children: [FilledButton(onPressed: _isSaving ? null : details.onStepContinue, child: Text(_step == 3 ? (widget.property == null ? 'Publier' : 'Enregistrer') : 'Suivant')), if (_step > 0) TextButton(onPressed: details.onStepCancel, child: const Text('Retour'))])), steps: [
          Step(title: Text(titles[0]), isActive: _step >= 0, content: Column(children: [_field(_title, 'Titre', true), DropdownButtonFormField<String>(initialValue: _type, decoration: const InputDecoration(labelText: 'Type de bien'), items: ['Appartement', 'Maison', 'Villa', 'Terrain', 'Bureau', 'Commerce'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => _type = value ?? _type)), _field(_description, 'Description', true, maxLines: 3)])),
          Step(title: Text(titles[1]), isActive: _step >= 1, content: Column(children: [_field(_city, 'Ville', true), _field(_neighborhood, 'Quartier', true), _field(_address, 'Adresse complète', true)])),
          Step(title: Text(titles[2]), isActive: _step >= 2, content: Column(children: [SegmentedButton<String>(segments: const [ButtonSegment(value: 'location', label: Text('Loyer')), ButtonSegment(value: 'vente', label: Text('Vente'))], selected: {_priceType}, onSelectionChanged: (value) => setState(() => _priceType = value.first)), _field(_price, _priceType == 'location' ? 'Loyer (FCFA)' : 'Prix de vente (FCFA)', true, number: true), _field(_deposit, 'Caution (FCFA)', false, number: true), Row(children: [Expanded(child: _number('Chambres', _bedrooms, (value) => setState(() => _bedrooms = value))), Expanded(child: _number('Salles de bain', _bathrooms, (value) => setState(() => _bathrooms = value)))]), _number('Surface (m2)', _area, (value) => setState(() => _area = value))])),
          Step(title: Text(titles[3]), isActive: _step >= 3, content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_photoActions(), if (_isPicking) const LinearProgressIndicator(), if (_images.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Ajoutez des photos pour continuer')), ReorderableWrap(images: _images, coverIndex: _coverIndex, onReorder: _reorderImages, onCoverChanged: (index) => setState(() => _coverIndex = index))])),
        ])),
      ])),
    );
  }

  Widget _field(TextEditingController controller, String label, bool required, {int maxLines = 1, bool number = false}) => TextFormField(controller: controller, maxLines: maxLines, keyboardType: number ? TextInputType.number : null, decoration: InputDecoration(labelText: label), validator: required ? (value) => _required(value, label) : null);
  Widget _number(String label, int value, ValueChanged<int> onChanged) => InputDecorator(decoration: InputDecoration(labelText: label), child: Row(children: [IconButton(onPressed: value > 0 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove)), Text('$value'), IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add))]));
  Widget _photoActions() => Row(children: [OutlinedButton.icon(onPressed: _isPicking ? null : () => _pickImages(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galerie')), const SizedBox(width: 8), OutlinedButton.icon(onPressed: _isPicking ? null : () => _pickImages(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Caméra'))]);
}

class ReorderableWrap extends StatelessWidget {
  final List<String> images;
  final int coverIndex;
  final void Function(int, int) onReorder;
  final ValueChanged<int> onCoverChanged;
  const ReorderableWrap({super.key, required this.images, required this.coverIndex, required this.onReorder, required this.onCoverChanged});
  @override
  Widget build(BuildContext context) => Column(children: List.generate(images.length, (index) => ListTile(
    leading: Image.file(File(images[index]), width: 64, height: 64, fit: BoxFit.cover),
    title: Text(index == coverIndex ? 'Photo de couverture' : 'Photo ${index + 1}'),
    subtitle: Row(children: [
      IconButton(onPressed: index == 0 ? null : () => onReorder(index, index - 1), icon: const Icon(Icons.arrow_upward, size: 18), tooltip: 'Monter'),
      IconButton(onPressed: index == images.length - 1 ? null : () => onReorder(index, index + 2), icon: const Icon(Icons.arrow_downward, size: 18), tooltip: 'Descendre'),
    ]),
    trailing: IconButton(onPressed: () => onCoverChanged(index), icon: Icon(index == coverIndex ? Icons.star : Icons.star_border, color: Colors.amber), tooltip: 'Choisir comme couverture'),
  )));
}
