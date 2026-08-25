import 'package:flutter/material.dart';
import '../models/pet_model.dart';

class PetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onTap;

  const PetCard({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(pet.imageUrl),
          radius: 28,
        ),
        title: Text(
          pet.name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${pet.breed} - ${pet.size}'),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
