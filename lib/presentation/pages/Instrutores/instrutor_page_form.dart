import 'package:cronograma/data/models/instrutores_model.dart';
import 'package:cronograma/data/repositories/instrutor_repository.dart';
import 'package:cronograma/presentation/viewmodels/estagio_viewmodels.dart';
import 'package:flutter/material.dart';

class CadastroInstrutorPage extends StatefulWidget {

  const CadastroInstrutorPage({super.key});

  @override
  State<CadastroInstrutorPage> createState() => _CadastroInstrutorPageState();
}

class _CadastroInstrutorPageState extends State<CadastroInstrutorPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _telefoneController = TextEditingController();

  final InstrutoresViewModel _viewModel = InstrutoresViewModel(InstrutoresRepository());

  Future<void> saveInstrutores() async {
    if (_formKey.currentState!.validate()) {
      final instrutor = Instrutores(
        nomeInstrutor: _nomeController.text,
        
      );
      // print(dog.toMap());
      await _viewModel.addInstrutor(instrutor);

      // Verifica se o widget ainda está montado antes de exibir o Snackbar ou navegar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Curso adicionado com sucesso!')),
        );
        // Navigator.pop(context); // Fecha a página após salvar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Instrutor'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preencha os dados do Instrutor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o telefone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: saveInstrutores,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Cadastrar Instrutor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
