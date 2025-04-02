import 'package:cronograma/data/models/cursos_model.dart';
import 'package:cronograma/data/models/instrutores_model.dart';
import 'package:cronograma/data/models/turma_model.dart';
import 'package:cronograma/data/repositories/cursos_repository.dart';
import 'package:cronograma/data/repositories/instrutor_repository.dart';
import 'package:cronograma/data/repositories/turma_repository.dart';
import 'package:cronograma/data/repositories/turno_repository.dart';
import 'package:cronograma/presentation/pages/turma/edit_turma_page.dart'
    show EditTurmaPage;
import 'package:cronograma/presentation/viewmodels/cursos_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/estagio_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/turma_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/turno_viewmodels.dart';
import 'package:flutter/material.dart';

class TurmaPageForm extends StatefulWidget {
  const TurmaPageForm({super.key});

  @override
  State<TurmaPageForm> createState() => _TurmaPageFormState();
}

class _TurmaPageFormState extends State<TurmaPageForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _turmaController = TextEditingController();
  final TurmaViewModel _viewModel = TurmaViewModel(TurmaRepository());
  final TurnoViewModel _turnoViewModel = TurnoViewModel(TurnoRepository());
  final CursosViewModel _cursosViewModel = CursosViewModel(CursosRepository());
  final InstrutoresViewModel _instrutoresViewModel =
      InstrutoresViewModel(InstrutoresRepository());

  bool _isLoading = false;
  List<Turma> _turmas = [];
  List<String> _turnos = ['Matutino', 'Vespertino', 'Noturno'];
  String? _turnoSelecionado;
  int? _cursoIdSelecionado;
  int? _instrutorIdSelecionado;
  int? _turmaParaExcluir;
  bool _mostrarConfirmacaoExclusao = false;
  List<Cursos> _cursos = [];
  List<Instrutores> _instrutores = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final turmas = await _viewModel.getTurmas();
      final cursos = await _cursosViewModel.getCursos();
      final instrutores = await _instrutoresViewModel.getInstrutores();

      if (mounted) {
        setState(() {
          _turmas = turmas;
          _cursos = cursos;
          _instrutores = instrutores;
          if (_cursos.isNotEmpty && _cursoIdSelecionado == null) {
            _cursoIdSelecionado = _cursos.first.idCurso;
          }
          if (_instrutores.isNotEmpty && _instrutorIdSelecionado == null) {
            _instrutorIdSelecionado = _instrutores.first.idInstrutor;
          }
          if (_turnos.isNotEmpty && _turnoSelecionado == null) {
            _turnoSelecionado = _turnos.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTurma() async {
    if (!_formKey.currentState!.validate() ||
        _turnoSelecionado == null ||
        _cursoIdSelecionado == null ||
        _instrutorIdSelecionado == null) return;

    setState(() => _isLoading = true);

    try {
      final turnoId =
          await _turnoViewModel.getTurnoIdByNome(_turnoSelecionado!);

      final turma = Turma(
        turma: _turmaController.text,
        idcurso: _cursoIdSelecionado!,
        idturno: turnoId!,
        idinstrutor: _instrutorIdSelecionado!,
      );

      await _viewModel.addTurma(turma);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turma cadastrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      _turmaController.clear();
      await _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editarTurma(Turma turma) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTurmaPage(
          turma: turma,
          turnos: _turnos,
          cursos: _cursos,
          instrutores: _instrutores,
        ),
      ),
    );

    if (result == true && mounted) {
      await _carregarDados();
    }
  }

  Future<void> _confirmarExclusao(int turmaId) async {
    setState(() {
      _turmaParaExcluir = turmaId;
      _mostrarConfirmacaoExclusao = true;
    });

    await Future.delayed(const Duration(seconds: 5));

    if (mounted &&
        _mostrarConfirmacaoExclusao &&
        _turmaParaExcluir == turmaId) {
      await _excluirTurma(turmaId);
    }
  }

  Future<void> _cancelarExclusao() async {
    setState(() {
      _mostrarConfirmacaoExclusao = false;
      _turmaParaExcluir = null;
    });
  }

  Future<void> _excluirTurma(int turmaId) async {
    try {
      await _viewModel.deleteTurma(turmaId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turma excluída com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      await _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mostrarConfirmacaoExclusao = false;
          _turmaParaExcluir = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Turma'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Cadastrar Nova Turma',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _turmaController,
                            decoration: InputDecoration(
                              labelText: 'Identificação da Turma',
                              prefixIcon: Icon(Icons.groups,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira a identificação';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _turnoSelecionado,
                            items: _turnos.map((turno) {
                              return DropdownMenuItem<String>(
                                value: turno,
                                child: Text(turno),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() => _turnoSelecionado = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Turno',
                              prefixIcon: Icon(Icons.schedule,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) =>
                                value == null ? 'Selecione um turno' : null,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<int>(
                            value: _cursoIdSelecionado,
                            items: _cursos.map((curso) {
                              return DropdownMenuItem<int>(
                                value: curso.idCurso,
                                child: Text(curso.nomeCurso),
                              );
                            }).toList(),
                            onChanged: (int? value) {
                              if (value != null) {
                                setState(() => _cursoIdSelecionado = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Curso',
                              prefixIcon: Icon(Icons.school,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) =>
                                value == null ? 'Selecione um curso' : null,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<int>(
                            value: _instrutorIdSelecionado,
                            items: _instrutores.map((instrutor) {
                              return DropdownMenuItem<int>(
                                value: instrutor.idInstrutor,
                                child: Text(instrutor.nomeInstrutor),
                              );
                            }).toList(),
                            onChanged: (int? value) {
                              if (value != null) {
                                setState(() => _instrutorIdSelecionado = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Instrutor',
                              prefixIcon: Icon(Icons.person,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) =>
                                value == null ? 'Selecione um instrutor' : null,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveTurma,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.save, size: 24),
                                        SizedBox(width: 8),
                                        Text(
                                          'Salvar Turma',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Turmas Cadastradas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _turmas.isEmpty
                        ? const Text('Nenhuma turma cadastrada')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _turmas.length,
                            itemBuilder: (context, index) {
                              final turma = _turmas[index];
                              final curso = _cursos.firstWhere(
                                (c) => c.idCurso == turma.idcurso,
                                orElse: () => Cursos(
                                    nomeCurso: 'Curso não encontrado',
                                    cargahoraria: 0),
                              );
                              final instrutor = _instrutores.firstWhere(
                                (i) => i.idInstrutor == turma.idinstrutor,
                                orElse: () => Instrutores(
                                    nomeInstrutor: 'Instrutor não encontrado'),
                              );
                              final turno = turma.idturno;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(turma.turma),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Curso: ${curso.nomeCurso}'),
                                      Text(
                                          'Instrutor: ${instrutor.nomeInstrutor}'),
                                      Text('Turno: $turno'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: colorScheme.primary),
                                        onPressed: () => _editarTurma(turma),
                                      ),
                                      if (_mostrarConfirmacaoExclusao &&
                                          _turmaParaExcluir == turma.idTurma)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.red),
                                              onPressed: _cancelarExclusao,
                                            ),
                                            TweenAnimationBuilder(
                                              tween: IntTween(begin: 5, end: 0),
                                              duration:
                                                  const Duration(seconds: 5),
                                              builder: (context, value, child) {
                                                return Text('$value');
                                              },
                                            ),
                                          ],
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _confirmarExclusao(
                                              turma.idTurma!),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
