import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
import '../models/pet_model.dart';
import '../utils/pet_image_widget.dart';
import '../utils/app_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final petProv = context.watch<PetProvider>();
    final remProv = context.watch<ReminderProvider>();
    final pets = petProv.pets;
    final reminders = remProv.reminders;

    if (petProv.isLoading || remProv.isLoading) {
      return const Scaffold(body: AppLoadingWidget(message: 'Carregando...'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Lembretes ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lembretes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddReminder(context, pets),
                ),
              ],
            ),
            if (reminders.isEmpty)
              const AppEmptyWidget(
                message: 'Nenhum lembrete ainda.\nToque em + para adicionar.',
                icon: Icons.notifications_none,
              )
            else
              ...reminders.map((r) {
                // Busca o pet com segurança
                final petName = pets
                    .where((p) => p.id == r.petId)
                    .map((p) => p.name)
                    .firstOrNull ?? 'Pet removido';

                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: r.isDone,
                      onChanged: (_) => remProv.toggleDone(r.id),
                    ),
                    title: Text(
                      r.title,
                      style: TextStyle(
                        decoration: r.isDone ? TextDecoration.lineThrough : null,
                        color: r.isDone ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(
                      '$petName • ${DateFormat('dd/MM/yyyy').format(r.dateTime)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => remProv.removeReminder(r.id),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // ── Dicas Rápidas ──────────────────────────────────
            const Text('Dicas Rápidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _TipCard('Escove o pelo regularmente'),
                  _TipCard('Ofereça água fresca sempre'),
                  _TipCard('Passeie pelo menos 30 min hoje'),
                  _TipCard('Verifique as vacinas em dia'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Atividade dos Pets ─────────────────────────────
            const Text('Atividade dos Pets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (pets.isEmpty)
              const AppEmptyWidget(
                message: 'Cadastre um pet para ver a atividade.',
                icon: Icons.pets,
              )
            else
              ...pets.map((pet) {
                final today = remProv.todayReminders(pet.id);
                final done = remProv.completedTodayReminders(pet.id);
                final progress = petProv.activityProgress(done, today);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: PetImageWidget(
                      pet: pet,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: Text(pet.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today.isEmpty
                              ? 'Sem lembretes hoje'
                              : '${done.length}/${today.length} lembretes concluídos',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showAddReminder(BuildContext context, List<PetModel> pets) {
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um pet antes de adicionar lembretes.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    PetModel? selected = pets.first;
    DateTime date = DateTime.now();
    String type = 'outro';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Novo Lembrete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PetModel>(
                value: selected,
                decoration: const InputDecoration(
                  labelText: 'Pet',
                  border: OutlineInputBorder(),
                ),
                items: pets
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'vacina', child: Text('💉 Vacina')),
                  DropdownMenuItem(value: 'banho', child: Text('🛁 Banho')),
                  DropdownMenuItem(value: 'consulta', child: Text('🏥 Consulta')),
                  DropdownMenuItem(value: 'remedio', child: Text('💊 Remédio')),
                  DropdownMenuItem(value: 'outro', child: Text('📌 Outro')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => date = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(date)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty && selected != null) {
                  final rem = ReminderModel(
                    id: const Uuid().v4(),
                    title: titleCtrl.text.trim(),
                    petId: selected!.id,
                    type: type,
                    dateTime: date,
                  );
                  context.read<ReminderProvider>().addReminder(rem);
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
