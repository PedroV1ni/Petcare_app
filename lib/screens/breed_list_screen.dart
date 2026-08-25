import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/breed.dart';
import 'breed_detail_screen.dart';

class BreedListScreen extends StatefulWidget {
  const BreedListScreen({Key? key}) : super(key: key);

  @override
  State<BreedListScreen> createState() => _BreedListScreenState();
}

class _BreedListScreenState extends State<BreedListScreen> {
  List<Breed> _all = [];
  List<Breed> _filtered = [];
  String _species = 'dog'; // 'dog' | 'cat' | 'all'
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/breeds/breeds.json');
      final List data = json.decode(raw);
      setState(() {
        _all = data.map((e) => Breed.fromJson(e)).toList();
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar raças: $e';
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((b) {
        final matchSpecies = _species == 'all' || b.species == _species;
        final matchSearch = q.isEmpty ||
            b.name.toLowerCase().contains(q) ||
            b.description.toLowerCase().contains(q) ||
            b.temperament.any((t) => t.toLowerCase().contains(q));
        return matchSpecies && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raças')),
      body: Column(
        children: [
          // Filtro espécie
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'dog', label: Text('🐶 Cães'), icon: Icon(Icons.pets, size: 16)),
                ButtonSegment(value: 'cat', label: Text('🐱 Gatos'), icon: Icon(Icons.catching_pokemon, size: 16)),
                ButtonSegment(value: 'all', label: Text('Todos')),
              ],
              selected: {_species},
              onSelectionChanged: (v) {
                setState(() => _species = v.first);
                _applyFilter();
              },
            ),
          ),
          // Busca
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar raça, temperamento...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        })
                    : null,
              ),
            ),
          ),
          // Lista
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
        ]),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('Nenhuma raça encontrada.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _BreedCard(breed: _filtered[i]),
    );
  }
}

class _BreedCard extends StatelessWidget {
  final Breed breed;
  const _BreedCard({required this.breed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BreedDetailScreen(breed: breed)),
        ),
        child: Row(
          children: [
            // Imagem
            SizedBox(
              width: 90,
              height: 90,
              child: Image.asset(
                breed.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.brown.shade50,
                  child: Icon(Icons.pets, size: 40, color: Colors.brown.shade200),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(breed.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: breed.species == 'cat' ? Colors.purple.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          breed.species == 'cat' ? '🐱 Gato' : '🐶 Cão',
                          style: TextStyle(
                            fontSize: 11,
                            color: breed.species == 'cat' ? Colors.purple : Colors.blue,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      breed.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: breed.temperament.take(3).map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
