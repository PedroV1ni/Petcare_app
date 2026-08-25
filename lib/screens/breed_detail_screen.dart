import 'package:flutter/material.dart';
import '../models/breed.dart';

class BreedDetailScreen extends StatelessWidget {
  final Breed breed;
  const BreedDetailScreen({Key? key, required this.breed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero com imagem
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            // Recolhida, a barra fica marrom: o branco do titulo e da seta
            // continua legivel quando a foto sai de cena.
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                breed.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    breed.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.brown.shade100,
                      child: Icon(Icons.pets, size: 80, color: Colors.brown.shade300),
                    ),
                  ),
                  // Escurece topo e base da foto para dar contraste a seta de
                  // voltar e ao titulo, sem escurecer o meio da imagem.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x8C000000),
                          Color(0x00000000),
                          Color(0xB3000000),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge espécie + porte
                  Wrap(spacing: 8, children: [
                    _badge(breed.species == 'cat' ? '🐱 Gato' : '🐶 Cão',
                        breed.species == 'cat' ? Colors.purple : Colors.blue),
                    _badge('📏 ${breed.size}', Colors.teal),
                    _badge('🌍 ${breed.origin}', Colors.orange),
                  ]),
                  const SizedBox(height: 16),

                  // Descrição
                  Text('Sobre a raça', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(breed.description, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 20),

                  // Temperamento
                  Text('Temperamento', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: breed.temperament.map((t) => Chip(
                          // O cinza padrao do Material sobre ambar claro fica
                          // com contraste fraco; marrom escuro resolve e
                          // mantem a paleta da tela.
                          label: Text(
                            t,
                            style: TextStyle(
                              color: Colors.brown.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: Colors.amber.shade50,
                        )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Dicas de cuidado
                  if (breed.tips.isNotEmpty) ...[
                    Text('Dicas de cuidado', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...breed.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Curiosidades
                  if (breed.curiosities.isNotEmpty) ...[
                    Text('Curiosidades', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...breed.curiosities.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡 ', style: TextStyle(fontSize: 16)),
                              Expanded(child: Text(c)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, MaterialColor color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.shade100),
        ),
        child: Text(text, style: TextStyle(color: color.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
      );
}
