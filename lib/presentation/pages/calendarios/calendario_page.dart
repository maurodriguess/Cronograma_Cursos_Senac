import 'package:cronograma/core/database_helper.dart';
import 'package:cronograma/data/models/calendarios_model.dart';
import 'package:cronograma/data/models/turma_model.dart';
import 'package:cronograma/data/repositories/calendarios_repository.dart';
import 'package:cronograma/data/repositories/turma_repository.dart';
import 'package:cronograma/presentation/viewmodels/calendarios_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/turma_viewmodels.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CadastroCalendariosPage extends StatefulWidget {
  const CadastroCalendariosPage({Key? key}) : super(key: key);

  @override
  _CadastroCalendariosPageState createState() =>
      _CadastroCalendariosPageState();
}

class _CadastroCalendariosPageState extends State<CadastroCalendariosPage> {
  final _formKey = GlobalKey<FormState>();
  final _anoController = TextEditingController();
  final _mesController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();

  late final TurmaViewModel _turmaViewModel;
  late final CalendariosViewModel _calendariosViewModel;

  DateTime? _dataInicio;
  DateTime? _dataFim;
  List<Turma> _turmas = [];
  int? _selectedTurmaId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _turmaViewModel = TurmaViewModel(TurmaRepository());
    _calendariosViewModel =
        CalendariosViewModel(CalendariosRepository(DatabaseHelper.instance));
    _loadTurmas();
  }

  @override
  void dispose() {
    _anoController.dispose();
    _mesController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    super.dispose();
  }

  Future<void> _loadTurmas() async {
    setState(() => _isLoading = true);
    try {
      final turmas = await _turmaViewModel.getTurmas();
      setState(() => _turmas = turmas);
    } catch (e) {
      _showErrorSnackbar('Erro ao carregar turmas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDataInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dataInicio = picked;
        _dataInicioController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      // Validar se data fim é anterior à data início
      if (_dataFim != null && _dataFim!.isBefore(picked)) {
        _dataFim = null;
        _dataFimController.clear();
      }
    }
  }

  Future<void> _selectDataFim(BuildContext context) async {
    final firstDate = _dataInicio ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dataFim = picked;
        _dataFimController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveCalendario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataInicio == null || _dataFim == null || _selectedTurmaId == null) {
      _showErrorSnackbar('Por favor, preencha todos os campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final calendario = Calendarios(
        ano: int.parse(_anoController.text),
        mes: _mesController.text,
        dataInicio: DateFormat('yyyy-MM-dd').format(_dataInicio!),
        dataFim: DateFormat('yyyy-MM-dd').format(_dataFim!),
        idTurma: _selectedTurmaId!,
      );

      await _calendariosViewModel.addCalendario(calendario);
      _showSuccessSnackbar('Calendário cadastrado com sucesso!');
      _resetForm();
    } catch (e) {
      _showErrorSnackbar('Erro ao salvar calendário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _dataInicio = null;
    _dataFim = null;
    _selectedTurmaId = null;
    _dataInicioController.clear();
    _dataFimController.clear();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Calendário'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: _isLoading && _turmas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _anoController,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        hintText: 'Ex: 2023',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o ano';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Ano inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mesController,
                      decoration: const InputDecoration(
                        labelText: 'Mês',
                        hintText: 'Ex: Janeiro',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o mês';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Turma',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTurmaId,
                      onChanged: (value) =>
                          setState(() => _selectedTurmaId = value),
                      items: _turmas.map((turma) {
                        return DropdownMenuItem<int>(
                          value: turma.idTurma,
                          child: Text('${turma.turma} (${turma.idTurma})'),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione uma turma';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dataInicioController,
                      decoration: const InputDecoration(
                        labelText: 'Data Início',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDataInicio(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione a data de início';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dataFimController,
                      decoration: const InputDecoration(
                        labelText: 'Data Fim',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDataFim(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione a data de fim';
                        }
                        if (_dataInicio != null &&
                            _dataFim != null &&
                            _dataFim!.isBefore(_dataInicio!)) {
                          return 'Data fim não pode ser anterior à data início';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveCalendario,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Salvar Calendário'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
