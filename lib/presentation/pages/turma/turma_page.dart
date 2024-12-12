import 'package:cronograma/data/models/cursos_model.dart';
import 'package:cronograma/data/models/instrutores_model.dart';
import 'package:cronograma/data/models/turma_model.dart';
import 'package:cronograma/data/repositories/cursos_repository.dart';
import 'package:cronograma/data/repositories/instrutor_repository.dart';
import 'package:cronograma/presentation/viewmodels/cursos_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/estagio_viewmodels.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/turma_repository.dart';
import '../../../data/repositories/turno_repository.dart';
import '../../../presentation/viewmodels/turma_viewmodels.dart';
import '../../../presentation/viewmodels/turno_viewmodels.dart';

class TurmaPageForm extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _turnoController = TextEditingController();
  final TextEditingController _idTurmaController = TextEditingController();
  final TextEditingController _turmaController = TextEditingController();
  final TextEditingController _cursoController = TextEditingController();
  final TextEditingController _instrutorController =
      TextEditingController(); // Controlador do instrutor

  final TurnoViewModel _turnoviewModel = TurnoViewModel(TurnoRepository());
  final TurmaViewModel _turmarepository = TurmaViewModel(TurmaRepository());
  final CursosViewModel _cursosViewModel = CursosViewModel(CursosRepository());
  final InstrutoresViewModel _instrutoresViewModel = InstrutoresViewModel(
      InstrutoresRepository()); // ViewModel dos instrutores

  TurmaPageForm({super.key});

  final List<String> turnos = ['Matutino', 'Vespertino', 'Noturno'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Turma'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preencha os dados da Turma',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Nome da Turma
              TextFormField(
                controller: _turmaController,
                decoration: const InputDecoration(
                  labelText: 'Identificação da turma',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a identificação da turma';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Turno do Curso (Dropdown)
              DropdownButtonFormField<String>(
                items: turnos.map((turno) {
                  return DropdownMenuItem<String>(
                    value: turno,
                    child: Text(turno),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _turnoController.text = value; // Armazena o nome do turno
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Turno do curso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o turno';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Curso (Dropdown com FutureBuilder)
              FutureBuilder<List<Cursos>>(
                future: _cursosViewModel.getCursos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Erro ao carregar cursos: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Nenhum curso disponível');
                  } else {
                    List<Cursos> cursos = snapshot.data!;

                    return DropdownButtonFormField<int>(
                      onChanged: (int? value) {
                        _cursoController.text = value.toString();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Selecione o curso',
                        border: OutlineInputBorder(),
                      ),
                      items: cursos.map((curso) {
                        return DropdownMenuItem<int>(
                          value: curso.idCursos,
                          child: Text(curso.nomeCurso),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione um curso';
                        }
                        return null;
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 30),

              // Instrutor (Dropdown com FutureBuilder)
              FutureBuilder<List<Instrutores>>(
                future: _instrutoresViewModel.getInstrutores(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                        'Erro ao carregar instrutores: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Nenhum instrutor disponível');
                  } else {
                    List<Instrutores> instrutores = snapshot.data!;

                    return DropdownButtonFormField<int>(
                      onChanged: (int? value) {
                        _instrutorController.text = value.toString();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Selecione o instrutor',
                        border: OutlineInputBorder(),
                      ),
                      items: instrutores.map((instrutor) {
                        return DropdownMenuItem<int>(
                          value: instrutor.idInstrutores,
                          child: Text(instrutor.nomeInstrutor),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione um instrutor';
                        }
                        return null;
                      },
                    );
                  }
                },
              ),

              const SizedBox(height: 30),

              // Botão de cadastro
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final turnoId = await _turnoviewModel
                        .getTurnoIdByNome(_turnoController.text);

                    final instrutorId = int.tryParse(_instrutorController
                        .text); // ID do instrutor selecionado

                    final turma = Turma(
                      turma: _turmaController.text,
                      idcurso: int.tryParse(_cursoController.text),
                      idturno: turnoId,
                      idinstrutor: instrutorId, // Definindo o instrutor
                    );

                    try {
                      await _turmarepository.addTurma(turma);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Turma cadastrada com sucesso!')));
                      _idTurmaController.clear();
                      _turmaController.clear();
                      _turnoController.clear();
                      _cursoController.clear();
                      _instrutorController
                          .clear(); // Limpa o controlador do instrutor
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Erro ao cadastrar turma.')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Cadastrar Turma'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
