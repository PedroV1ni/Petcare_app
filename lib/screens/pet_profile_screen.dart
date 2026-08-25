import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet_model.dart';
import '../utils/pet_image_widget.dart';
import 'add_edit_pet_screen.dart';

class PetProfileScreen extends StatefulWidget {
  final PetModel pet;
  final Function(PetModel) onEdit;
  final VoidCallback onDelete;

  const PetProfileScreen({
    Key? key,
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late PetModel _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  void _navigateToEdit() async {
    final result = await Navigator.push<PetModel>(
      context,
      MaterialPageRoute(builder: (_) => AddEditPetScreen(pet: _pet)),
    );
    if (result != null) {
      setState(() => _pet = result);
      widget.onEdit(result);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir ${_pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(_pet.birthDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(_pet.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _navigateToEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto
            PetImageWidget(
              pet: _pet,
              width: 120,
              height: 120,
              borderRadius: BorderRadius.circular(60),
            ),
            const SizedBox(height: 16),

            // Nome
            Text(_pet.name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_pet.breed, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // Badges
            Wrap(spacing: 8, children: [
              _infoChip(Icons.straighten, _pet.size),
              _infoChip(Icons.monitor_weight, '${_pet.weight} kg'),
              _infoChip(Icons.cake, '$dateStr (${_pet.age} ${_pet.age == 1 ? 'ano' : 'anos'})'),
              _infoChip(
                _pet.species == 'cat' ? Icons.catching_pokemon : Icons.pets,
                _pet.species == 'cat' ? 'Gato' : _pet.species == 'dog' ? 'Cão' : 'Outro',
              ),
            ]),

            if (_pet.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Observações',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_pet.description),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Botões
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                onPressed: _navigateToEdit,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Excluir'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _confirmDelete,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        backgroundColor: Colors.brown.shade50,
      );
}
