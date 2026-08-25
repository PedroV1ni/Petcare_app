import 'package:flutter/material.dart';

import '../models/news.dart';
import '../services/data_service.dart';
import '../utils/app_widgets.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatelessWidget {
  NewsScreen({super.key});

  final _service = DataService();

  static const _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  /// Evita que o topo da lista fique so com materia sem resumo.
  ///
  /// O Firestore devolve por data, e ai as materias editoriais - as unicas com
  /// resumo e capa - afundam, porque aviso de prefeitura sai todo dia e guia
  /// de cuidado nao. A ordem cronologica continua dentro de cada grupo, mas
  /// nao se permite mais de dois itens seguidos sem resumo.
  List<News> _intercalar(List<News> lista) {
    bool temResumo(News n) =>
        n.description.isNotEmpty && n.description != n.author;

    final ricas = lista.where(temResumo).toList();
    final secas = lista.where((n) => !temResumo(n)).toList();
    final saida = <News>[];
    var seguidasSemResumo = 0;

    while (ricas.isNotEmpty || secas.isNotEmpty) {
      final pegarRica =
          ricas.isNotEmpty && (seguidasSemResumo >= 2 || secas.isEmpty);
      if (pegarRica) {
        saida.add(ricas.removeAt(0));
        seguidasSemResumo = 0;
      } else {
        saida.add(secas.removeAt(0));
        seguidasSemResumo++;
      }
    }
    return saida;
  }

  /// Data curta ao lado do veiculo. "há 2 dias" diz mais que "23 de ago."
  /// quando a noticia acabou de sair, que e o caso da maioria da lista.
  String _quando(DateTime d) {
    final dias = DateTime.now().difference(d).inDays;
    if (dias <= 0) return 'hoje';
    if (dias == 1) return 'ontem';
    if (dias < 7) return 'há $dias dias';
    return '${d.day} de ${_meses[d.month - 1]}.';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<News>>(
      stream: _service.streamNews(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return AppErrorWidget(message: 'Erro ao carregar notícias: ${snap.error}');
        }
        if (!snap.hasData) {
          return const AppLoadingWidget(message: 'Carregando notícias...');
        }
        final lista = _intercalar(snap.data!);
        if (lista.isEmpty) {
          return const AppEmptyWidget(
            message: 'Nenhuma notícia por enquanto.',
            icon: Icons.article_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: lista.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.brown.shade50,
          ),
          itemBuilder: (_, i) => _cartao(context, lista[i]),
        );
      },
    );
  }

  Widget _cartao(BuildContext context, News news) {
    // A descricao vira o nome do veiculo quando nao ha resumo; nesse caso
    // mostra-la aqui seria repetir o que ja aparece na linha de baixo.
    final temResumo =
        news.description.isNotEmpty && news.description != news.author;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _miniatura(news),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  if (temResumo) ...[
                    const SizedBox(height: 5),
                    Text(
                      news.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          news.author,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown.shade600,
                          ),
                        ),
                      ),
                      Text(
                        '  ·  ${_quando(news.date)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.brown.shade300),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// So parte das materias tem capa - o link do Google Noticias nao permite
  /// descobrir a imagem. O bloco tem tamanho fixo para a lista nao ficar
  /// desalinhada entre uma noticia com foto e outra sem.
  Widget _miniatura(News news) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 76,
        height: 76,
        child: news.temCapa
            ? Image.network(
                news.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _semCapa(),
                loadingBuilder: (_, filho, progresso) =>
                    progresso == null ? filho : _semCapa(),
              )
            : _semCapa(),
      ),
    );
  }

  Widget _semCapa() => Container(
        color: Colors.brown.shade50,
        child: Icon(Icons.article_outlined,
            size: 30, color: Colors.brown.shade200),
      );
}
