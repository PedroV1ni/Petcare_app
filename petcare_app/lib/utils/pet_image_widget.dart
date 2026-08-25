import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pet_model.dart';

/// Widget seguro para exibir imagem de pet —
/// suporta asset, arquivo local e fallback automático.
class PetImageWidget extends StatelessWidget {
  final PetModel pet;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PetImageWidget({
    Key? key,
    required this.pet,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (pet.imageUrl.isEmpty) {
      image = _fallback();
    } else if (pet.isAssetImage) {
      image = Image.asset(
        pet.imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      final file = File(pet.imageUrl);
      image = Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _fallback() {
    final icon = pet.species == 'cat' ? Icons.pets : Icons.catching_pokemon;
    return Container(
      width: width,
      height: height,
      color: Colors.brown.shade50,
      child: Icon(icon, size: (width ?? 64) * 0.5, color: Colors.brown.shade200),
    );
  }
}
