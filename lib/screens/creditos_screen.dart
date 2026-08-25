import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

/// Atribuicao das fotos de raca.
///
/// As licencas CC BY e CC BY-SA exigem credito visivel, entao esta tela
/// precisa continuar alcancavel pelo app enquanto essas imagens forem usadas.
/// A fonte e assets/creditos.json, gerado a partir de CREDITOS_IMAGENS.md.
class CreditosScreen extends StatefulWidget {
  const CreditosScreen({super.key});

  @override
  State<CreditosScreen> createState() => _CreditosScreenState();
}

class _CreditosScreenState extends State<CreditosScreen> {
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final bruto = await rootBundle.loadString('assets/creditos.json');
      final lista = (json.decode(bruto) as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _itens = lista;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Nao foi possivel carregar os creditos: $e';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _abrir(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creditos das imagens')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_erro!, textAlign: TextAlign.center),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'As fotos das racas vem do Wikimedia Commons. As '
                        'licencas Creative Commons exigem que o credito ao '
                        'autor apareca no app.',
                        style: TextStyle(
                          color: Colors.brown.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._itens.map(_cartao),
                  ],
                ),
    );
  }

  Widget _cartao(Map<String, dynamic> item) {
    final autor = (item['autor'] as String?) ?? '';
    final origem = (item['origem'] as String?) ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/breeds/${item['arquivo']}',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              color: Colors.brown.shade50,
              child: Icon(Icons.pets, color: Colors.brown.shade200),
            ),
          ),
        ),
        title: Text(
          item['raca'] as String? ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            item['licenca'] as String? ?? '',
            if (autor.isNotEmpty) autor,
          ].join(' - '),
          style: TextStyle(color: Colors.brown.shade400),
        ),
        trailing: origem.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Ver arquivo original',
                onPressed: () => _abrir(origem),
              ),
      ),
    );
  }
}
