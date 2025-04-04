import 'package:cronograma/core/automatizador_calendario.dart';
import 'package:cronograma/data/repositories/calendarios_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cronograma/core/database_helper.dart';

class CronogramaPage extends StatefulWidget {
  const CronogramaPage({Key? key}) : super(key: key);

  @override
  _CronogramaPageState createState() => _CronogramaPageState();
}

class _CronogramaPageState extends State<CronogramaPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<DateTime, List<Aula>> _events = {};
  final Map<DateTime, String> _feriados = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _carregarFeriadosBrasileiros(now.year);
    _carregarAulas();
  }

  void _carregarFeriadosBrasileiros(int ano) {
    _feriados[DateTime(ano, 1, 1)] = '🎉 Ano Novo';
    _feriados[DateTime(ano, 4, 21)] = '🎖 Tiradentes';
    _feriados[DateTime(ano, 5, 1)] = '👷 Dia do Trabalho';
    _feriados[DateTime(ano, 9, 7)] = '🇧🇷 Independência do Brasil';
    _feriados[DateTime(ano, 10, 12)] = '🙏 Nossa Senhora Aparecida';
    _feriados[DateTime(ano, 11, 2)] = '🕯 Finados';
    _feriados[DateTime(ano, 11, 15)] = '🏛 Proclamação da República';
    _feriados[DateTime(ano, 12, 25)] = '🎄 Natal';

    final pascoa = _calcularPascoa(ano);
    _feriados[pascoa] = '🐣 Páscoa';
    _feriados[pascoa.subtract(const Duration(days: 2))] = '✝ Sexta-Feira Santa';
    _feriados[pascoa.subtract(const Duration(days: 47))] = '🎭 Carnaval';
    _feriados[pascoa.add(const Duration(days: 60))] = '🍞 Corpus Christi';
  }

  DateTime _calcularPascoa(int ano) {
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = (h + l - 7 * m + 114) % 31 + 1;

    return DateTime(ano, mes, dia);
  }

  bool _isFeriado(DateTime day) {
    return _feriados.containsKey(DateTime(day.year, day.month, day.day));
  }

  Future<void> _carregarAulas() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final aulas = await db.query('Aulas');

      final Map<DateTime, List<Aula>> events = {};
      for (var aula in aulas) {
        final date = DateTime.parse(aula['data'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);

        final aulaObj = Aula(
          idAula: aula['idAula'] as int,
          idUc: aula['idUc'] as int,
          idTurma: aula['idTurma'] as int,
          data: date,
          horario: aula['horario'] as String,
          status: aula['status'] as String,
        );

        events.putIfAbsent(normalizedDate, () => []).add(aulaObj);
      }

      if (mounted) {
        setState(() {
          _events.clear();
          _events.addAll(events);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar aulas: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _adicionarAula() async {
    if (_selectedDay == null || !mounted) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final turmas = await db.query('Turma');
      final ucs = await db.query('Unidades_Curriculares');

      if (turmas.isEmpty || ucs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastre turmas e UCs primeiro!')),
          );
        }
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Adicionar Nova Aula'),
          content: AdicionarAulaDialog(
            turmas: turmas,
            ucs: ucs,
            selectedDate: _selectedDay!,
          ),
        ),
      );

      if (result != null && mounted) {
        await db.insert('Aulas', {
          'idUc': result['idUc'],
          'idTurma': result['idTurma'],
          'data': DateFormat('yyyy-MM-dd').format(_selectedDay!),
          'horario': result['horario'],
          'status': 'Agendada',
        });
        await _carregarAulas();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aula adicionada com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar aula: $e')),
        );
      }
    }
  }

  Future<void> _removerAula(int idAula) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('Aulas', where: 'idAula = ?', whereArgs: [idAula]);
      if (mounted) {
        await _carregarAulas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aula removida com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover aula: $e')),
        );
      }
    }
  }

  Future<void> _showAutoScheduleDialog() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final turmas = await db.query('Turma');
      final ucs = await db.query('Unidades_Curriculares');

      if (turmas.isEmpty || ucs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastre turmas e UCs primeiro!')),
          );
        }
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _buildAutoScheduleDialog(turmas, ucs),
      );

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Agendamento Automático'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedTurmaId,
                        decoration: const InputDecoration(labelText: 'Turma'),
                        items: turmas
                            .map((t) => DropdownMenuItem(
                                  value: t['idTurma'] as int,
                                  child: Text(t['turma'] as String),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedTurmaId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedUcId,
                        decoration: const InputDecoration(
                            labelText: 'Unidade Curricular'),
                        items: ucs
                            .map((uc) => DropdownMenuItem(
                                  value: uc['idUc'] as int,
                                  child: Text(uc['nome_uc'] as String),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedUcId = value),
                      ),
                      const SizedBox(height: 16),
                      const Text('Padrão: Segunda/Quarta/Sexta, 19h-22h'),
                      const SizedBox(height: 8),
                      const Text('Total: 180 horas (60 aulas)'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedTurmaId != null && selectedUcId != null) {
                        Navigator.pop(context, {
                          'idTurma': selectedTurmaId!,
                          'idUc': selectedUcId!,
                        });
                      }
                    },
                    child: const Text('Agendar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != null && mounted) {
        await _executarAgendamentoAutomatico(
          idTurma: result['idTurma'] as int,
          idUc: result['idUc'] as int,
          cargaHoraria: result['cargaHoraria'] as int,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }
  

  Future<void> _executarAgendamentoAutomatico({
    required int idTurma,
    required int idUc,
    required int cargaHoraria,
  }) async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final automatizador = AutomatizadorCalendario(
          CalendariosRepository(DatabaseHelper.instance));

      await automatizador.agendarAulasAutomaticamente(
        idUc: idUc,
        idTurma: idTurma,
        cargaHorariaTotal: 180,
        horarioInicio: const TimeOfDay(hour: 19, minute: 0),
        horarioFim: const TimeOfDay(hour: 22, minute: 0),
        diasDaSemana: [1, 3, 5], // Segunda, Quarta, Sexta
        dataInicio: DateTime.now(),
        dataTermino: DateTime.now().add(const Duration(days: 90)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 60 aulas agendadas com sucesso!')),
        );
        await _carregarAulas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro no agendamento: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Aula> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String? _getFeriadoForDay(DateTime day) {
    return _feriados[DateTime(day.year, day.month, day.day)];
  }

  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox();

    final events = _getEventsForDay(_selectedDay!);
    final feriado = _getFeriadoForDay(_selectedDay!);

    return Column(
      children: [
        if (feriado != null)
          Card(
            color: Colors.amber[100],
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.celebration, color: Colors.orange),
              title: Text(feriado),
              subtitle: Text(
                  DateFormat('EEEE, d MMMM', 'pt_BR').format(_selectedDay!)),
            ),
          ),
        if (events.isEmpty && feriado == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Nenhuma aula agendada para ${DateFormat('EEEE, d MMMM', 'pt_BR').format(_selectedDay!)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ...events.map((aula) => _buildAulaCard(aula)),
      ],
    );
  }

  Widget _buildAulaCard(Aula aula) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 40,
          decoration: BoxDecoration(
            color: _getColorByStatus(aula.status),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: FutureBuilder<Map<String, dynamic>>(
          future: _getAulaDetails(aula.idAula!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Carregando...',
                  style: TextStyle(color: Colors.grey));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Erro ao carregar dados',
                  style: TextStyle(color: Colors.red));
            }
            final data = snapshot.data!;
            return Text(
              '${data['nome_uc']} - ${data['turma']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _getAulaDetails(aula.idAula!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando...',
                      style: TextStyle(color: Colors.grey));
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar dados',
                      style: TextStyle(color: Colors.red));
                }
                final data = snapshot.data!;
                return Text('Instrutor: ${data['nome_instrutor']}');
              },
            ),
            Text('Horário: ${aula.horario}'),
            Text('Status: ${aula.status}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmarRemocaoAula(aula.idAula!),
        ),
      ),
    );
  }

  Future<void> _confirmarRemocaoAula(int idAula) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar remoção'),
        content: const Text('Tem certeza que deseja remover esta aula?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _removerAula(idAula);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Aulas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Feriados Nacionais'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: _feriados.entries
                        .map((e) => ListTile(
                              title: Text(e.value),
                              subtitle: Text(
                                DateFormat('EEEE, d MMMM yyyy', 'pt_BR')
                                    .format(e.key),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'auto_schedule',
            tooltip: 'Agendamento Automático',
            onPressed: _showAutoScheduleDialog,
            child: const Icon(Icons.auto_awesome_motion),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_class',
            onPressed: _adicionarAula,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  locale: 'pt_BR',
                  headerStyle: HeaderStyle(
                    titleTextFormatter: (date, locale) =>
                        DateFormat('MMMM yyyy', 'pt_BR')
                            .format(date)
                            .toUpperCase(),
                    formatButtonVisible: false,
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    holidayTextStyle: TextStyle(color: Colors.red[800]),
                    markerDecoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat.E('pt_BR').format(day);
                      return Center(
                        child: Text(
                          text,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                    defaultBuilder: (context, date, _) {
                      final isFeriado = _isFeriado(date);
                      final isToday = isSameDay(date, DateTime.now());
                      final isSelected = isSameDay(date, _selectedDay);
                      final hasEvents = _getEventsForDay(date).isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isFeriado
                              ? Colors.red[50]
                              : isToday
                                  ? Colors.orange[100]
                                  : isSelected
                                      ? Colors.blue[100]
                                      : null,
                          border: isFeriado
                              ? Border.all(color: Colors.red)
                              : isSelected
                                  ? Border.all(color: Colors.blue)
                                  : null,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isFeriado
                                      ? Colors.red[800]
                                      : date.weekday == 6 || date.weekday == 7
                                          ? Colors.red
                                          : null,
                                  fontWeight: isFeriado || isSelected || isToday
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                            if (hasEvents && !isSelected)
                              Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[400],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) =>
                      setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  eventLoader: _getEventsForDay,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _carregarAulas,
                    child: _buildEventList(),
                  ),
                ),
              ],
            ),
    );
  }

  Color _getColorByStatus(String status) {
    switch (status) {
      case 'Realizada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      case 'Adiada':
        return Colors.orange;
      default: // Agendada
        return Colors.blue;
    }
  }

  Future<Map<String, dynamic>> _getAulaDetails(int idAula) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
      SELECT Aulas.*, 
             Unidades_Curriculares.nome_uc, 
             Turma.turma, 
             Instrutores.nome_instrutor
      FROM Aulas
      JOIN Unidades_Curriculares ON Aulas.idUc = Unidades_Curriculares.idUc
      JOIN Turma ON Aulas.idTurma = Turma.idTurma
      JOIN Instrutores ON Turma.idInstrutor = Instrutores.idInstrutor
      WHERE Aulas.idAula = ?
    ''', [idAula]);

      if (result.isEmpty) {
        return {
          'nome_uc': 'Não encontrado',
          'turma': 'Não encontrada',
          'nome_instrutor': 'Não encontrado'
        };
      }

      return result.first;
    } catch (e) {
      return {
        'nome_uc': 'Erro: $e',
        'turma': 'Erro: $e',
        'nome_instrutor': 'Erro: $e'
      };
    }
  }
}

class AdicionarAulaDialog extends StatefulWidget {
  final List<Map<String, dynamic>> turmas;
  final List<Map<String, dynamic>> ucs;
  final DateTime selectedDate;

  const AdicionarAulaDialog({
    Key? key,
    required this.turmas,
    required this.ucs,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _AdicionarAulaDialogState createState() => _AdicionarAulaDialogState();
}

class _AdicionarAulaDialogState extends State<AdicionarAulaDialog> {
  int? _selectedTurmaId;
  int? _selectedUcId;
  String _horario = '19:00-22:00';

  @override
  void initState() {
    super.initState();
    if (widget.turmas.isNotEmpty)
      _selectedTurmaId = widget.turmas.first['idTurma'] as int;
    if (widget.ucs.isNotEmpty) _selectedUcId = widget.ucs.first['idUc'] as int;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Data selecionada:'),
            subtitle: Text(
              DateFormat('EEEE, d MMMM yyyy', 'pt_BR')
                  .format(widget.selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          DropdownButtonFormField<int>(
            value: _selectedTurmaId,
            decoration: const InputDecoration(
              labelText: 'Turma',
              border: OutlineInputBorder(),
            ),
            items: widget.turmas
                .map((turma) => DropdownMenuItem(
                      value: turma['idTurma'] as int,
                      child: Text(turma['turma'] as String),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedTurmaId = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedUcId,
            decoration: const InputDecoration(
              labelText: 'Unidade Curricular',
              border: OutlineInputBorder(),
            ),
            items: widget.ucs
                .map((uc) => DropdownMenuItem(
                      value: uc['idUc'] as int,
                      child: Text(uc['nome_uc'] as String),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedUcId = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _horario,
            decoration: const InputDecoration(
              labelText: 'Horário',
              border: OutlineInputBorder(),
            ),
            items: ['08:00-12:00', '13:30-17:30', '19:00-22:00']
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _horario = value!),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedTurmaId != null && _selectedUcId != null
                    ? () => Navigator.pop(context, {
                          'idTurma': _selectedTurmaId,
                          'idUc': _selectedUcId,
                          'horario': _horario,
                        })
                    : null,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Aula {
  final int? idAula;
  final int idUc;
  final int idTurma;
  final DateTime data;
  final String horario;
  final String status;

  Aula({
    this.idAula,
    required this.idUc,
    required this.idTurma,
    required this.data,
    required this.horario,
    this.status = 'Agendada',
  });
}
