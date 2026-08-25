import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/pet_model.dart';
import '../providers/pet_provider.dart';

class AddEditPetScreen extends StatefulWidget {
  final PetModel? pet;
  const AddEditPetScreen({Key? key, this.pet}) : super(key: key);

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _species = 'dog';
  String _size = 'Médio';
  String? _breed;
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365));
  String _imageUrl = '';
  bool _isSaving = false;

  // Raças carregadas do JSON
  List<String> _dogBreeds = [];
  List<String> _catBreeds = [];

  List<String> get _currentBreeds => _species == 'cat' ? _catBreeds : _dogBreeds;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
    if (widget.pet != null) {
      final p = widget.pet!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _weightCtrl.text = p.weight.toString();
      _species = p.species;
      _size = p.size;
      _breed = p.breed;
      _birthDate = p.birthDate;
      _imageUrl = p.imageUrl;
    }
  }

  Future<void> _loadBreeds() async {
    try {
      final raw = await rootBundle.loadString('assets/breeds/breeds.json');
      final List data = json.decode(raw);
      final dogs = data.where((b) => (b['species'] ?? 'dog') == 'dog').map<String>((b) => b['name'] as String).toList();
      final cats = data.where((b) => b['species'] == 'cat').map<String>((b) => b['name'] as String).toList();
      dogs.sort();
      cats.sort();
      setState(() {
        _dogBreeds = dogs;
        _catBreeds = cats;
        // garante que a raça atual existe na lista
        if (_breed != null && !_currentBreeds.contains(_breed)) {
          _breed = null;
        }
      });
    } catch (e) {
      // fallback mínimo
      setState(() {
        _dogBreeds = ['SRD (Vira-lata)', 'Golden Retriever', 'Labrador', 'Poodle', 'Bulldog', 'Beagle', 'Pug', 'Shih Tzu'];
        _catBreeds = ['SRD (Vira-lata)', 'Siamês', 'Persa', 'Maine Coon', 'Bengal'];
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ----- Imagem -----

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _imageUrl = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar foto'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeria'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          if (_imageUrl.isNotEmpty && !_imageUrl.startsWith('assets/'))
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(context); setState(() => _imageUrl = ''); },
            ),
        ]),
      ),
    );
  }

  // ----- Data -----

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  // ----- Salvar -----

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final pet = PetModel(
      id: widget.pet?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      birthDate: _birthDate,
      breed: _breed ?? 'SRD',
      species: _species,
      size: _size,
      weight: double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0,
      imageUrl: _imageUrl,
    );

    final provider = context.read<PetProvider>();
    if (widget.pet == null) {
      await provider.addPet(pet);
    } else {
      await provider.updatePet(pet);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
        );
        provider.clearError();
      } else {
        Navigator.pop(context);
      }
    }
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Pet' : 'Adicionar Pet'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Salvar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Foto
            Center(
              child: GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.brown.shade50,
                      backgroundImage: _imageUrl.isEmpty
                          ? null
                          : _imageUrl.startsWith('assets/')
                              ? AssetImage(_imageUrl) as ImageProvider
                              : FileImage(File(_imageUrl)),
                      child: _imageUrl.isEmpty
                          ? Icon(Icons.add_a_photo, size: 36, color: Colors.brown.shade300)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Espécie
            const Text('Espécie', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'dog', label: Text('🐶 Cão'), icon: Icon(Icons.pets)),
                ButtonSegment(value: 'cat', label: Text('🐱 Gato'), icon: Icon(Icons.catching_pokemon)),
                ButtonSegment(value: 'other', label: Text('Outro'), icon: Icon(Icons.cruelty_free)),
              ],
              selected: {_species},
              onSelectionChanged: (v) => setState(() {
                _species = v.first;
                _breed = null; // resetar raça ao trocar espécie
              }),
            ),
            const SizedBox(height: 16),

            // Nome
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),

            // Raça
            DropdownButtonFormField<String>(
              value: (_breed != null && _currentBreeds.contains(_breed)) ? _breed : null,
              decoration: const InputDecoration(labelText: 'Raça', border: OutlineInputBorder()),
              items: _currentBreeds.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _breed = v),
            ),
            const SizedBox(height: 16),

            // Data de nascimento
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de nascimento',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text('${_birthDate.day}/${_birthDate.month}/${_birthDate.year}'),
              ),
            ),
            const SizedBox(height: 16),

            // Porte
            DropdownButtonFormField<String>(
              value: _size,
              decoration: const InputDecoration(labelText: 'Porte', border: OutlineInputBorder()),
              items: ['Pequeno', 'Médio', 'Grande']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _size = v!),
            ),
            const SizedBox(height: 16),

            // Peso
            TextFormField(
              controller: _weightCtrl,
              decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder(), suffixText: 'kg'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d == null || d < 0) return 'Peso inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
