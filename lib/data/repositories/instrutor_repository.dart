import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/instrutores_model.dart';

class InstrutoresRepository {
  Future<void> insertInstrutor(Instrutores instrutor) async {
    final db = await DatabaseHelper.initDb();
    await db.insert(
      'Instrutores',
      instrutor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Instrutores>> getInstrutores() async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> instrutorMaps =
        await db.query('Instrutores');
    return instrutorMaps.map((map) {
      return Instrutores(
        idInstrutores: map['idInstrutores'] as int?,
        nomeInstrutor: map['nome_instrutor'] as String,
      );
    }).toList();
  }

  Future<void> updateInstrutor(Instrutores instrutor) async {
    final db = await DatabaseHelper.initDb();
    await db.update(
      'Instrutores',
      instrutor.toMap(),
      where: 'idInstrutores = ?',
      whereArgs: [instrutor.idInstrutores],
    );
  }

  Future<void> deleteInstrutor(int id) async {
    final db = await DatabaseHelper.initDb();
    await db.delete(
      'Instrutores',
      where: 'idInstrutores = ?',
      whereArgs: [id],
    );
  }

  Future<int?> getInstrutoroIdByNome(String nomeInstrutor) async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> result = await db.query(
      'Instrutor',
      where: 'nome_instrutor = ?',
      whereArgs: [nomeInstrutor],
    );

    if (result.isNotEmpty) {
      return result.first['idCursos'] as int?;
    }

    return null; // Caso não encontre o curso com o nome fornecido.
  }
}
