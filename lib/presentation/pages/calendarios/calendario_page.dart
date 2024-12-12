import 'package:cronograma/data/models/calendarios_model.dart';
import 'package:cronograma/data/repositories/calendarios_repository.dart';
import 'package:cronograma/presentation/viewmodels/calendarios_viewmodels.dart';
import 'package:flutter/material.dart';

class CadastroCalendariosPage extends StatefulWidget {
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
  final _idTurmaController = TextEditingController();

  final CalendariosViewModel _calendariosViewModel =
      CalendariosViewModel(CalendariosRepository());

  // Para armazenar as datas
  DateTime? _dataInicio;
  DateTime? _dataFim;

  // Método para mostrar o DatePicker para a data de início
  Future<void> _selectDataInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataInicio) {
      setState(() {
        _dataInicio = picked;
        _dataInicioController.text =
            "${_dataInicio!.toLocal()}".split(' ')[0]; // formato "yyyy-mm-dd"
      });
    }
  }

  // Método para mostrar o DatePicker para a data de fim
  Future<void> _selectDataFim(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataFim) {
      setState(() {
        _dataFim = picked;
        _dataFimController.text =
            "${_dataFim!.toLocal()}".split(' ')[0]; // formato "yyyy-mm-dd"
      });
    }
  }

  // Método para salvar os dados
  Future<void> _saveCalendario() async {
    if (_formKey.currentState!.validate()) {
      final Calendario = Calendario(
        idTurma: int.parse(
            _idTurmaController.text), // Converter o idturma para inteiro
        ano: int.parse(_anoController.text),
        mes: int.parse(_mesController.text),
        dataInicio: _dataInicio!,
        dataFim: _dataFim!,
      );

      // Adicionando o calendário no repositório
      await _calendariosViewModel.addCalendario(Calendarios(
          ano: ano,
          mes: mes,
          dataInicio: dataInicio,
          dataFim: dataFim,
          idturma: idturma));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calendário cadastrado com sucesso!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Calendário')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo para o ano
              TextFormField(
                controller: _anoController,
                decoration: InputDecoration(labelText: 'Ano'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o ano';
                  }
                  return null;
                },
              ),
              // Campo para o mês
              TextFormField(
                controller: _mesController,
                decoration: InputDecoration(labelText: 'Mês'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o mês';
                  }
                  return null;
                },
              ),
              // Campo para o ID da turma
              TextFormField(
                controller: _idTurmaController,
                decoration: InputDecoration(labelText: 'ID da Turma'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o ID da turma';
                  }
                  return null;
                },
              ),
              // Campo para a data de início
              TextFormField(
                controller: _dataInicioController,
                decoration: InputDecoration(labelText: 'Data Início'),
                readOnly: true,
                onTap: () => _selectDataInicio(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a data de início';
                  }
                  return null;
                },
              ),
              // Campo para a data de fim
              TextFormField(
                controller: _dataFimController,
                decoration: InputDecoration(labelText: 'Data Fim'),
                readOnly: true,
                onTap: () => _selectDataFim(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a data de fim';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCalendario,
                child: Text('Salvar Calendário'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
