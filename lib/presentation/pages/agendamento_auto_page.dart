import 'package:cronograma/core/automatizador_calendario.dart';
import 'package:cronograma/core/database_helper.dart';
import 'package:cronograma/data/repositories/calendarios_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgendamentoAutoPage extends StatefulWidget {
  const AgendamentoAutoPage({Key? key}) : super(key: key);

  @override
  State<AgendamentoAutoPage> createState() => _AgendamentoAutoPageState();
}

class _AgendamentoAutoPageState extends State<AgendamentoAutoPage> {
  final _formKey = GlobalKey<FormState>();
  final _idUcController = TextEditingController();
  final _idTurmaController = TextEditingController();
  final _cargaHorariaController = TextEditingController(text: '180');

  TimeOfDay? _horarioInicio;
  TimeOfDay? _horarioFim;
  List<int> _diasSelecionados = [1, 3, 5]; // Seg, Qua, Sex por padrão
  bool _isLoading = false;

  @override
  void dispose() {
    _idUcController.dispose();
    _idTurmaController.dispose();
    _cargaHorariaController.dispose();
    super.dispose();
  }

  Future<void> _agendar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horarioInicio == null || _horarioFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione os horários')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final automatizador = AutomatizadorCalendario(
        CalendariosRepository(DatabaseHelper.instance),
      );

      await automatizador.agendarAulasAutomaticamente(
        idUc: int.parse(_idUcController.text),
        idTurma: int.parse(_idTurmaController.text),
        cargaHorariaTotal: int.parse(_cargaHorariaController.text),
        horarioInicio: _horarioInicio!,
        horarioFim: _horarioFim!,
        diasDaSemana: _diasSelecionados,
        dataInicio: DateTime.now(),
        dataTermino: DateTime.now().add(const Duration(days: 90)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Aulas agendadas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _nomeDia(int dia) {
    switch (dia) {
      case 1:
        return 'Segunda';
      case 2:
        return 'Terça';
      case 3:
        return 'Quarta';
      case 4:
        return 'Quinta';
      case 5:
        return 'Sexta';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendamento Automático')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _idUcController,
              decoration: const InputDecoration(
                labelText: 'ID da UC',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe o ID da UC';
                if (int.tryParse(value) == null) return 'ID inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idTurmaController,
              decoration: const InputDecoration(
                labelText: 'ID da Turma',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Informe o ID da turma';
                if (int.tryParse(value) == null) return 'ID inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cargaHorariaController,
              decoration: const InputDecoration(
                labelText: 'Carga Horária Total (horas)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Informe a carga horária';
                if (int.tryParse(value) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Horário Início: ${_horarioInicio?.format(context) ?? 'Não selecionado'}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime:
                      _horarioInicio ?? const TimeOfDay(hour: 19, minute: 0),
                );
                if (time != null) {
                  setState(() => _horarioInicio = time);
                }
              },
            ),
            ListTile(
              title: Text(
                'Horário Fim: ${_horarioFim?.format(context) ?? 'Não selecionado'}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime:
                      _horarioFim ?? const TimeOfDay(hour: 22, minute: 0),
                );
                if (time != null) {
                  setState(() => _horarioFim = time);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Dias da semana:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5].map((dia) {
                return FilterChip(
                  label: Text(_nomeDia(dia)),
                  selected: _diasSelecionados.contains(dia),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _diasSelecionados.add(dia)
                          : _diasSelecionados.remove(dia);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _agendar,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('GERAR AGENDAMENTO',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
