
import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/turma_model.dart';

class TurmaRepository {
  Future<void> insertTurma(Turma turma) async {
    final db = await DatabaseHelper.initDb();
    await db.insert(
      'Turma',
      turma.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Turma>> getTurmas() async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> turmaMaps = await db.query('Turma');
    return turmaMaps.map((map) {
      return Turma(
        idTurma: map['idTurma'] as int?,
        turma: map['turma'] as String,
        idcurso: map['idcurso'] as int,
        idturno: map['idturno'] as int,
        idinstrutor: map['idinstrutor'] as int,
      );
    }).toList();
  }

  Future<void> updateTurma(Turma turma) async {
    final db = await DatabaseHelper.initDb();
    await db.update(
      'Turma',
      turma.toMap(),
      where: 'idTurma = ?',
      whereArgs: [turma.idTurma],
    );
  }

  Future<void> deleteTurma(int id) async {
    final db = await DatabaseHelper.initDb();
    await db.delete(
      'Turma',
      where: 'idTurma = ?',
      whereArgs: [id],
    );
  }
}
