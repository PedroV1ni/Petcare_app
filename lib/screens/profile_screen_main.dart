import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import '../models/pet_model.dart';
import '../utils/pet_image_widget.dart';
import '../utils/app_widgets.dart';
import 'add_edit_pet_screen.dart';
import 'pet_profile_screen.dart';

class ProfileScreenMain extends StatelessWidget {
  const ProfileScreenMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final petProv = context.watch<PetProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pets')),
      body: petProv.isLoading
          ? const AppLoadingWidget(message: 'Carregando pets...')
          : petProv.error != null
              ? AppErrorWidget(
                  message: petProv.error!,
                  onRetry: () => petProv.loadPets(),
                )
              : petProv.pets.isEmpty
                  ? AppEmptyWidget(
                      message: 'Nenhum pet cadastrado ainda.',
                      icon: Icons.pets,
                      action: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar pet'),
                        onPressed: () => _goToAdd(context),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Seus Pets (${petProv.pets.length})',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...petProv.pets.map((pet) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: PetImageWidget(
                                  pet: pet,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                title: Text(pet.name),
                                subtitle: Text(
                                    '${pet.breed} • ${pet.age} ${pet.age == 1 ? 'ano' : 'anos'}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _showPetProfile(context, pet),
                              ),
                            )),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar novo pet'),
                          onPressed: () => _goToAdd(context),
                        ),
                      ],
                    ),
    );
  }

  void _goToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPetScreen()),
    );
  }

  void _showPetProfile(BuildContext context, PetModel pet) {
    final petProv = context.read<PetProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetProfileScreen(
          pet: pet,
          onEdit: (updated) {
            petProv.updatePet(updated);
          },
          onDelete: () {
            petProv.removePet(pet.id);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
