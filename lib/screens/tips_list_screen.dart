import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tip_model.dart';
import 'tip_detail_screen.dart';

class TipsListScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const TipsListScreen({
    required this.title,
    required this.assetPath,
    Key? key,
  }) : super(key: key);

  @override
  State<TipsListScreen> createState() => _TipsListScreenState();
}

class _TipsListScreenState extends State<TipsListScreen> {
  List<TipModel> tips = [];
  List<TipModel> filteredTips = [];
  String selectedCategory = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  List<String> get categories {
    final cats = tips.map((tip) => tip.category).toSet().toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  @override
  void initState() {
    super.initState();
    _loadTips();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTips() async {
    print('Tentando ler asset: ${widget.assetPath}'); // DEBUG: mostra qual arquivo está sendo lido
    final String data = await rootBundle.loadString(widget.assetPath);
    final List<dynamic> jsonResult = json.decode(data);
    setState(() {
      tips = jsonResult.map((e) => TipModel.fromJson(e)).toList();
      filteredTips = List.from(tips);
    });
    print('Dicas/carregadas: ${tips.length}'); // DEBUG: mostra quantos itens foram lidos
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredTips = tips.where((tip) {
        final matchCategory = (selectedCategory == 'Todas' || tip.category == selectedCategory);
        final matchSearch = tip.title.toLowerCase().contains(query) ||
            tip.summary.toLowerCase().contains(query) ||
            tip.content.toLowerCase().contains(query);
        return matchCategory && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                decoration: InputDecoration(
                  labelText: "Categoria",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val!;
                  });
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar dica/artigo',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...filteredTips.map((tip) => Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Image.asset(
                  tip.image,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(Icons.error, color: Colors.red),
                ),
                title: Text(tip.title),
                subtitle: Text(tip.summary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TipDetailScreen(tip: tip),
                    ),
                  );
                },
              ),
            )),
        if (filteredTips.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Nenhuma dica/artigo encontrado.')),
          ),
      ],
    );
  }
}
