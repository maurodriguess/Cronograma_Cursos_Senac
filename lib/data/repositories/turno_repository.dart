import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/turno_model.dart';

class TurnoRepository {
  Future<void> insertTurno(Turno turno) async {
    final db = await DatabaseHelper.initDb();
    await db.insert(
      'Turno',
      turno.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Turno>> getTurnos() async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> turnoMaps = await db.query('Turno');
    return turnoMaps.map((map) {
      return Turno(
        idTurno: map['idTurno'] as int?,
        turno: map['turno'] as String,
      );
    }).toList();
  }

  Future<void> updateTurno(Turno turno) async {
    final db = await DatabaseHelper.initDb();
    await db.update(
      'Turno',
      turno.toMap(),
      where: 'idTurno = ?',
      whereArgs: [turno.idTurno],
    );
  }

  Future<void> deleteTurno(int id) async {
    final db = await DatabaseHelper.initDb();
    await db.delete(
      'Turno',
      where: 'idTurno = ?',
      whereArgs: [id],
    );
  }

  Future<int?> getTurnoIdByNome(String nomeTurno) async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> result = await db.query(
      'Turno',
      where: 'turno = ?',
      whereArgs: [nomeTurno],
    );

    if (result.isNotEmpty) {
      return result.first['idTurno'] as int?;
    }

    return null; // Caso não encontre o curso com o nome fornecido.
  }
}
